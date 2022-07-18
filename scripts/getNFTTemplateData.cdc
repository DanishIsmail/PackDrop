import NFTContract from 0xf8d6e0586b0a20c7


pub fun main(address: Address) : {UInt64: AnyStruct}{
    let account1 = getAccount(address)
    let acct1Capability =  account1.getCapability(NFTContract.CollectionPublicPath)
                            .borrow<&{NFTContract.NFTContractCollectionPublic}>()
                            ??panic("could not borrow receiver reference ")
    var nftIds =   acct1Capability.getIDs()
    var dict : {UInt64: AnyStruct} = {}
    for nftId in nftIds {
        var nftData = NFTContract.getNFTDataById(nftId: nftId)
        var templateDataById =  NFTContract.getTemplateById(templateId: nftData.templateID)
        var nftMetaData : {String:AnyStruct} = {}
        
        nftMetaData["mintNumber"] =nftData.mintNumber;
        nftMetaData["templateData"] = templateDataById;
        dict.insert(key: nftId,nftMetaData)
    }
    return dict
}