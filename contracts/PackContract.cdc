import NonFungibleToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import ImsaNFTContract from 0xf8d6e0586b0a20c7
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
  pub event PackWithdrawan(packId: UInt64, receiptAddress: Address)

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
  access(contract) var allPacks: {UInt64: PackData}
  // dictionary to store available nfts
  access(contract) var availableNFTS: {UInt64: UInt64}
  // dictionary to store the user purchased packs ids
 //access(contract) var userPacks: {Address: [UInt64]}
  // variable to store the admin capability to NFT-Methods
  access(contract) var adminref: Capability<&{ImsaNFTContract.NFTMethodsCapability}>


  // structure to store the data for pack
  pub struct PackData {
    pub let packId: UInt64
    pub let data: {String: AnyStruct}
    pub let totalNFTs: UInt64
    pub var packPrice: UFix64

    init(packId: UInt64, data: {String: AnyStruct}, totalNFTs: UInt64, packPrice: UFix64) {
      self.packId = packId
      self.data = data
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
    pub fun createPack(packId: UInt64, data: {String: AnyStruct}, totalNFTs: UInt64, packPrice: UFix64){
      pre {
        packId !=0 && PackContract.allPacks[packId] == nil: "Please provide valid pack id"
        data.keys.length !=0: "Please provide pack data"
        totalNFTs  > 0 && totalNFTs <= 5: "Please provide valid NFT's length"
        packPrice > UFix64(0): "please provide price greater then zero"
        UInt64(PackContract.availableNFTS.keys.length) >= totalNFTs: "please add availble NFT Ids first"      
      }

      let newPack =  PackData(packId: packId, data: data, totalNFTs: totalNFTs, packPrice: packPrice)
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
      
      userPackCollectionRef!.depositPack(token: <- PackContract.createPackOpen(packId: packId, transferAble: true))

      let packPrice = PackContract.allPacks[packId]!.packPrice
      emit PackPurchased(packId: packId, price: packPrice, receiptAddress: receiptAccount)
    }

    pub fun addAvailableNFTs(templateIds: {UInt64: UInt64}) {
      pre {
        templateIds.keys.length !=0: "please provide valid ids" 
      }

      for tempId in templateIds.keys{
        let templateData = ImsaNFTContract.getTemplateById(templateId: tempId)
        let templateSupply = templateIds[tempId]
        assert(templateData.maxSupply >= templateSupply!, message: "template supply should be valid")
        if templateData !=nil && PackContract.availableNFTS.containsKey(tempId) == false {
          PackContract.availableNFTS[tempId] = templateIds[tempId]
        }
      }
    } 

    init(){
      self.ownerVault = nil
    }
  }

  pub resource Pack {
    // variable to store user purchased packs Ids
    access(contract) var userPackId: UInt64
    // variable that store the status to transferAble
    access(contract) var transferAble: Bool

    // method to open the pack
    pub fun openPack(receiptAccount: Address){
      pre {
        receiptAccount != nil: "receipent address should not be null"
        self.userPackId != 0 && PackContract.allPacks[self.userPackId] != nil : "User does not have any pack"
      }
      let totalMints = PackContract.allPacks[self.userPackId]!.totalNFTs
      var i: UInt64 = 0
      while i < totalMints {
        let templateData = ImsaNFTContract.getTemplateById(templateId: PackContract.availableNFTS.keys[i])
        if templateData.issuedSupply < PackContract.availableNFTS[templateData.templateId]! {
          PackContract.adminref.borrow()!.mintNFT(templateId: templateData.templateId, account: receiptAccount, immutableData: nil)
        }
        else {
            PackContract.availableNFTS.remove(key: templateData.templateId)
        }
        i = i + 1
      }
    
      emit PackOpened(packId: self.userPackId, receiptAddress: receiptAccount) 
    }
    
    access(contract) fun updateTransferStatus(transferAble: Bool) {
      self.transferAble == transferAble
    }
    init(packId :UInt64, transferAble: Bool){
      self.userPackId = packId
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
      emit PackWithdrawan(packId: withdrawPackId, receiptAddress: self.owner?.address!)
      return <- self.ownedPacks.remove(key: withdrawPackId)! 

    }

    pub fun depositPack(token: @PackContract.Pack){
      pre {
        token !=nil: "please provide valid pack"
        token.transferAble == true: "could not transfer pack"
      }
      self.totalPacksCount.saturatingAdd(1)
      let id = token.userPackId
      token.updateTransferStatus(transferAble: false)
      self.ownedPacks[self.totalPacksCount] <-! token
      emit PackDeposited(packId: id, receiptAddress: self.owner?.address!)
    }

    pub fun getTotalPackIDs(): [UInt64]{
      return self.ownedPacks.keys
    }

    init(){
      self.ownedPacks <- {}
      self.totalPacksCount = 0
    }

    destroy () {
      destroy self.ownedPacks
    }
  }

  // method to create the openPack resourcre
  access(contract) fun createPackOpen(packId: UInt64, transferAble: Bool): @PackContract.Pack {
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
    //self.userPacks = {}
    self.availableNFTS = {}

    var adminPrivateCap = self.account.getCapability
            <&{ImsaNFTContract.NFTMethodsCapability}>(ImsaNFTContract.NFTMethodsCapabilityPrivatePath)
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