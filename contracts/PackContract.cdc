import NonFungibleToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import NFTContract from 0xf8d6e0586b0a20c7
import FlowToken from 0x0ae53cb6e3f42a79

pub contract  PackContract{
  // Events
  // Emitted when contract initialized
  pub event ContractInitialized()
  // Emitted when a Pack is created
  pub event PackCreated(packId: UInt64, totalNFTs: UInt64)
  // Emitted when a Pack is purchased
  pub event PackPurchased(packId: UInt64, price: UFix64, receiptAddress: Address)
  // Emitted when a Pack is opened
  pub event PackOpened(packId: UInt64, receiptAddress: Address)
  // Emitted when a Pack is deposite to user pack collection
  pub event PackDeposited(packId: UInt64, receiptAddress: Address)
  // Emitted when a Pack is withdraw to user pack collection
  //pub event PackWithdrawan(packId: UInt64, receiptAddress: Address)

  // Paths for the pack contract
  // Storage path for Admin pack
  pub let PackAdminStoragePath: StoragePath
  // Storage path for pack collection
  pub let PackCollectionStoragePath: StoragePath
  // Private path for pack
  pub let PackAdminPrivatePath: PrivatePath
  // Public path for pack
  pub let PackAdminPublicPath: PublicPath
  // Public path for pack open
  pub let PackCollectionPublicPath: PublicPath

  // State Vraibles
  // dictionary to store the pack data against pack id
  access(contract) var allPacks: {UInt64: PackData} // {packId:PackData}
  // variable to store the admin capability to NFT-Methods
  access(contract) var adminref: Capability<&{NFTContract.NFTMethodsCapability}>

  // {1 : 100}

  // structure to store the data for pack
  pub struct PackData {
    pub let packId: UInt64
    pub let data: {String: AnyStruct} //{name:any_data_of_pack}
    pub let availableTemplates: {UInt64: UInt64} // {templateid: supply}
    pub let totalNFTs: UInt64 // How many NFT a pack can hold
    pub var packPrice: UFix64 

    init(packId: UInt64, data: {String: AnyStruct}, availableTemplates: {UInt64: UInt64},totalNFTs: UInt64, packPrice: UFix64) {
      self.packId = packId
      self.data = data
      self.availableTemplates = availableTemplates
      self.totalNFTs = totalNFTs
      self.packPrice = packPrice
    } 
  }
  
  pub resource interface PackPublicMethods{
    pub fun purchasePack(packId: UInt64, flowPayment: @FungibleToken.Vault, receiptAccount: Address)
  }
  
  pub resource interface PackCollectionPublicMethods{
    pub fun depositPack(token: @PackContract.Pack)
    pub fun getTotalPackIDs(): [UInt64]
  }

  pub resource AdminPackResource: PackPublicMethods {
    // variable to store admin vault refrence 
    access(contract) var ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>?

    //method to add owner vault refrence
    pub fun addOwnerVault(vaultRef : Capability<&AnyResource{FungibleToken.Receiver}>){
      self.ownerVault = vaultRef
    }
    
    //method to create the pack 
    pub fun createAdminPack(packId: UInt64, data: {String: AnyStruct}, availableTemplates: {UInt64: UInt64}, totalNFTs: UInt64, packPrice: UFix64){
      pre {
        packId !=0 && PackContract.allPacks[packId] == nil: "Please provide valid pack id"
        data.keys.length !=0: "Please provide pack data"
        totalNFTs  > 0 && totalNFTs <= 5: "Please provide valid NFT's length"
        packPrice > UFix64(0): "please provide price greater then zero"      
      }
      var countSupply: UInt64 = 0
      for temp in availableTemplates.keys {
          let templateData = NFTContract.getTemplateById(templateId: temp)
          assert(templateData != nil, message: "please provide valid template ids") 
          countSupply = countSupply + availableTemplates[temp]!
      }

      assert(countSupply == totalNFTs, message: "total nfts count is not valid")
      let newPack =  PackData(packId: packId, data: data, availableTemplates: availableTemplates, totalNFTs: totalNFTs, packPrice: packPrice)
      PackContract.allPacks[packId] = newPack

      emit PackCreated(packId: packId, totalNFTs: totalNFTs)
    }

    // method to purchase the pack
    pub fun purchasePack(packId: UInt64, flowPayment: @FungibleToken.Vault, receiptAccount: Address) {
      pre {
        packId !=0 && PackContract.allPacks[packId] != nil: "Please provide valid pack id"
        flowPayment.balance == PackContract.allPacks[packId]!.packPrice: "your balance is not enough to buy the pack"
        receiptAccount != nil: "receipent address should not be null" 
      }

      let ownerVaultRef = self.ownerVault!.borrow()
                ?? panic("Could not borrow reference to owner token vault")
      ownerVaultRef.deposit(from: <- flowPayment)

      let userPackCollectionRef = getAccount(receiptAccount).getCapability(PackContract.PackCollectionPublicPath)
                                  .borrow<&{PackContract.PackCollectionPublicMethods}>() 
                                  ?? panic("could not get reciever refrence to pack collection")
      userPackCollectionRef!.depositPack(token: <- PackContract.createPack(packId: packId, transferAble: true))

      let packPrice = PackContract.allPacks[packId]!.packPrice
      emit PackPurchased(packId: packId, price: packPrice, receiptAddress: receiptAccount)
    }

    init(){
      self.ownerVault = nil
    }
  }

  pub resource Pack {
    // variable to store user purchased packs Ids
    access(contract) var packId: UInt64
    // variable that store the status to transferAble
    access(contract) var transferAble: Bool

    // method to open the pack
    pub fun openPack(receiptAccount: Address){
      pre {
        //receiptAccount != nil: "receipent address should not be null"
        self.packId != 0 && PackContract.allPacks[self.packId] != nil : "User does not have any pack"
      }
      let totalMints = PackContract.allPacks[self.packId]!.totalNFTs
      let templates = PackContract.allPacks[self.packId]!.availableTemplates
      
      for tempId in templates.keys {
          var templateData = NFTContract.getTemplateById(templateId: tempId)
          var i: UInt64 = 0
          while i < templates[tempId]! {
              PackContract.adminref.borrow()!.mintNFT(templateId: templateData.templateId, account: receiptAccount, immutableData: nil)
              i = i + 1
          }
      }

      self.packId = 0
      emit PackOpened(packId: self.packId, receiptAddress: receiptAccount) 
    }
    
    access(contract) fun updateTransferStatus(transferAble: Bool) {
      self.transferAble == transferAble
    }
    init(packId :UInt64, transferAble: Bool){
      self.packId = packId
      self.transferAble = transferAble
    }
  }

  pub resource PackCollection: PackCollectionPublicMethods{
    // dictionary to store the resources
    pub var ownedPacks: @{UInt64: PackContract.Pack}
    // variable to count the total pack user have in collection
    pub var totalPacksCount: UInt64

    pub fun withdrawPack(withdrawPackId: UInt64): @PackContract.Pack {
      pre {
        withdrawPackId != 0 && self.ownedPacks[withdrawPackId] != nil: "please provide valid id"
      }
      //emit PackWithdrawan(packId: withdrawPackId, receiptAddress: self.owner?.address!)
      return <- self.ownedPacks.remove(key: withdrawPackId)! 

    }

    pub fun depositPack(token: @PackContract.Pack){
      pre {
        token !=nil: "please provide valid pack"
        token.transferAble == true: "could not transfer pack"
      }
      let id = token.packId
      token.updateTransferStatus(transferAble: false)
      let oldToken <- self.ownedPacks[self.totalPacksCount] <- token  
      self.totalPacksCount = self.totalPacksCount + 1
      emit PackDeposited(packId: id, receiptAddress: self.owner?.address!)
      destroy oldToken
    }

    pub fun getTotalPackIDs(): [UInt64]{
      return self.ownedPacks.keys
    }
    
    init(){
      self.ownedPacks <- {}
      self.totalPacksCount = 1
    }

    destroy () {
      destroy self.ownedPacks
    }
  }

  // method to create the openPack resourcre
  access(contract) fun createPack(packId: UInt64, transferAble: Bool): @PackContract.Pack {
    return <- create  Pack(packId: packId, transferAble: transferAble)
  }

  // method to create the pack collection 
  pub fun createPackCollection(): @PackContract.PackCollection{
    return  <- create PackCollection()
  }
  // method to get All Packs
  pub fun getAllPacks():{UInt64: PackData} {
    return  self.allPacks
  }

  // method to get the for pack specific id
  pub fun getPacksById(packId: UInt64): PackData {
    return self.allPacks[packId]!
  }

  init(){

    self.allPacks = {}

    var adminPrivateCap = self.account.getCapability
            <&{NFTContract.NFTMethodsCapability}>(NFTContract.NFTMethodsCapabilityPrivatePath)
    self.adminref = adminPrivateCap
   
    self.PackAdminStoragePath = /storage/packAdminStoragePath
    self.PackCollectionStoragePath = /storage/packCollectionStoragePath
    
    self.PackAdminPublicPath = /public/packAdminPublicPath
    self.PackCollectionPublicPath = /public/packCollectionPublicPath
    self.PackAdminPrivatePath = /private/packAdminPrivatePath 
    
    self.account.save(<- create AdminPackResource(), to: self.PackAdminStoragePath)
    self.account.link<&{PackContract.PackPublicMethods}>(self.PackAdminPublicPath, target: self.PackAdminStoragePath)
    
    self.account.save(<- self.createPackCollection(), to: self.PackCollectionStoragePath)
    self.account.link<&{PackContract.PackCollectionPublicMethods}>(self.PackCollectionPublicPath, target: self.PackCollectionStoragePath)

    emit  ContractInitialized()
  }
}