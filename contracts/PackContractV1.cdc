import NonFungibleToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import NFTContract from 0xf8d6e0586b0a20c7
import FlowToken from 0x0ae53cb6e3f42a79

pub contract  PackContractV1{
  // Events
  // Emitted when contract initialized
  pub event ContractInitialized()
  // Emitted when a Pack is created
  pub event PackCreated(packId: UInt64, packName: String, totalNFTs: UInt64)
  // Emitted when a Pack is purchased
  pub event PackPurchased(packId: UInt64, price: UFix64, receiptAddress: Address)
  // Emitted when a Pack is opened
  pub event PackOpened(packId: UInt64, receiptAddress: Address)

  // Paths for the pack contract
  // Storage path for pack
  pub let PackStoragePath: StoragePath
  // Private path for pack
  pub let PackPrivatePath: PrivatePath
  // Public path for pack
  pub let PackPublicPath: PublicPath

  // State Vraibles
  // dictionary to store the pack data against pack id
  access(contract) var allPacks: {UInt64: PackData}
  // array to store available nfts
  access(contract) var availableNFTS: [UInt64]
  // dictionary to store the user purchased packs ids
  access(contract) var userPacks: {Address: [UInt64]}
  // variable to store the admin capability to NFT-Methods
  access(contract) var adminref: Capability<&{NFTContract.NFTMethodsCapability}>


  // structure to store the data for pack
  pub struct PackData {
    pub let packId: UInt64
    pub let packName: String
    pub let totalNFTs: UInt64
    pub var packPrice: UFix64

    init(packId: UInt64, packName: String, totalNFTs: UInt64, packPrice: UFix64) {
      self.packId = packId
      self.packName = packName
      self.totalNFTs = totalNFTs
      self.packPrice = packPrice
    } 
  }
  
  pub resource interface PackPublicMethods{
    pub fun purchasePack(packId: UInt64, flowPayment: @FungibleToken.Vault, receiptAccount: Address)
    pub fun openPack(packId: UInt64, receiptAccount: Address)
  }

  pub resource Pack: PackPublicMethods {
    // variable to store admin vault refrence 
    access(contract) var ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>?

    //method to add owner vault refrence
    pub fun addOwnerVault(vaultRef : Capability<&AnyResource{FungibleToken.Receiver}>){
      self.ownerVault = vaultRef
    }
    
    //method to create the pack 
    pub fun createPack(packId: UInt64, packName: String, totalNFTs: UInt64, packPrice: UFix64){
      pre {
        packId !=0 && PackContractV1.allPacks[packId] == nil: "Please provide valid pack id"
        packName.length !=0: "Please provide pack name"
        totalNFTs  > 0 && totalNFTs <= 5: "Please provide valid NFT's length"
        packPrice > UFix64(0): "please provide price greater then zero"
        UInt64(PackContractV1.availableNFTS.length) >= totalNFTs: "please add availble NFT Ids first"      
      }

      let newPack =  PackData(packId: packId, packName: packName, totalNFTs: totalNFTs, packPrice: packPrice)
      PackContractV1.allPacks[packId] = newPack

      emit PackCreated(packId: packId, packName: packName, totalNFTs: totalNFTs)
    }

    // method to purchase the pack
    pub fun purchasePack(packId: UInt64, flowPayment: @FungibleToken.Vault, receiptAccount: Address) {
      pre {
        packId !=0 && PackContractV1.allPacks[packId] != nil: "Please provide valid pack id"
        flowPayment.balance == PackContractV1.allPacks[packId]!.packPrice: "your balance is not enough to buy the pack"
        receiptAccount != nil: "receipent address should not be null" 
      }

      let ownerVaultRef = self.ownerVault!.borrow()
                ?? panic("Could not borrow reference to owner token vault")
      ownerVaultRef.deposit(from: <- flowPayment)
      if PackContractV1.userPacks.containsKey(receiptAccount) == nil {
        PackContractV1.userPacks[receiptAccount]= [packId]
      }
      else{
        PackContractV1.userPacks[receiptAccount]!.append(packId)
      }
      let packPrice = PackContractV1.allPacks[packId]!.packPrice

      emit PackPurchased(packId: packId, price: packPrice, receiptAddress: receiptAccount)
    }

    pub fun openPack(packId: UInt64, receiptAccount: Address){
      pre {
        packId !=0 && PackContractV1.allPacks[packId] != nil: "Please provide valid pack id"
        receiptAccount != nil && PackContractV1.userPacks[receiptAccount] != nil: "receipent address should not be null"
        PackContractV1.userPacks[receiptAccount]!.contains(packId) == true: "User does not have any pack"
      }
      //var count: UInt64 = 0
      let totalMints = PackContractV1.allPacks[packId]!.totalNFTs
      var i: UInt64 = 0
      while i < totalMints {
        let templateData = NFTContract.getTemplateById(templateId: PackContractV1.availableNFTS[i])
        if templateData.issuedSupply < templateData.maxSupply {
          PackContractV1.adminref.borrow()!.mintNFT(templateId: templateData.templateId, account: receiptAccount, immutableData: nil)
          //count.saturatingAdd(1)
          }
        else {
            PackContractV1.availableNFTS.remove(at: templateData.templateId)
        }
        i = i + 1
      }
      let indexOFValue = PackContractV1.userPacks[receiptAccount]!.firstIndex(of: packId)!
      PackContractV1.userPacks[receiptAccount]!.remove(at: indexOFValue)
      emit PackOpened(packId: packId, receiptAddress: receiptAccount) 
    }

    pub fun addAvailableNFTs(templateIds: [UInt64]) {
      pre {
        templateIds.length !=0: "please provide valid ids" 
      }

      for tempId in templateIds{
        let templateData = NFTContract.getTemplateById(templateId: tempId)
        if templateData !=nil && PackContractV1.availableNFTS.contains(tempId) == false {
          PackContractV1.availableNFTS.append(tempId)
        }
      }
    } 

    init(){
      self.ownerVault = nil
    }
  }

  //method to get All Packs
  pub fun getAllPacks():{UInt64: PackData} {
    return  self.allPacks
  }

  // method to get the for pack specific id
  pub fun getPacksById(packId: UInt64): PackData {
    return self.allPacks[packId]!
  }

  init(){

    self.allPacks = {}
    self.availableNFTS = []
    self.userPacks = {}

    var adminPrivateCap = self.account.getCapability
            <&{NFTContract.NFTMethodsCapability}>(NFTContract.NFTMethodsCapabilityPrivatePath)
    self.adminref = adminPrivateCap
    self.PackStoragePath = /storage/packStoragePath
    self.PackPublicPath = /public/packPublicPath
    self.PackPrivatePath = /private/packPrivatePath
    
    self.account.save(<- create Pack(), to: self.PackStoragePath)
    self.account.link<&{PackContractV1.PackPublicMethods}>(self.PackPublicPath, target: self.PackStoragePath)
    
    emit  ContractInitialized()
  }
}