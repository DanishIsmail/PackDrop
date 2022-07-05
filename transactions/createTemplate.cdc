import ImsaNFTContract from 0xf8d6e0586b0a20c7

transaction(brandId: UInt64, schemaId: UInt64, maxSupply: UInt64) {
    prepare(acct: AuthAccount) {
        let actorResource = acct.getCapability
            <&{ImsaNFTContract.NFTMethodsCapability}>
            (ImsaNFTContract.NFTMethodsCapabilityPrivatePath)
            .borrow() ?? 
            panic("could not borrow a reference to the NFTMethodsCapability interface")
        
        let immutableData: {String: AnyStruct} = {
            "contectType" : "Image",
            "contectValue"  : "https://troontechnologies.com"
            //extra
        }
         
        let mutableData : {String: AnyStruct} = {   
            "title": "racing car NFT",
            "description":  "wining moment of game"
        }
        actorResource.createTemplate(brandId: brandId, schemaId: schemaId, maxSupply: maxSupply, immutableData: immutableData, mutableData: mutableData)
        log("ok")
    }
}