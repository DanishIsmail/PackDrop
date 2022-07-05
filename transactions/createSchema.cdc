import ImsaNFTContract from 0xf8d6e0586b0a20c7

transaction (schemaName:String){

      prepare(acct: AuthAccount) {

            let actorResource = acct.getCapability
                  <&{ImsaNFTContract.NFTMethodsCapability}>
                  (ImsaNFTContract.NFTMethodsCapabilityPrivatePath)
                  .borrow() ?? 
                  panic("could not borrow a reference to the NFTMethodsCapability interface")


            let format : {String: ImsaNFTContract.SchemaType} = {
            "artist" : ImsaNFTContract.SchemaType.String,
            "artistEmail"  :  ImsaNFTContract.SchemaType.String,
            "title":ImsaNFTContract.SchemaType.String,
            "mintType":  ImsaNFTContract.SchemaType.String,
            "nftType":  ImsaNFTContract.SchemaType.String,
            "rarity":  ImsaNFTContract.SchemaType.String,
            "contectType":  ImsaNFTContract.SchemaType.String,
            "contectValue":  ImsaNFTContract.SchemaType.String,
            "extras": ImsaNFTContract.SchemaType.Any
            }

            actorResource.createSchema(schemaName: schemaName, format: format)
            log("schema created")
      }
}