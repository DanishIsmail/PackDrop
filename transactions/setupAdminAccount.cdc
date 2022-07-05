import ImsaNFTContract from 0xf8d6e0586b0a20c7

transaction() {
    prepare(signer: AuthAccount) {
        // save the resource to the signer's account storage
        if signer.getLinkTarget(ImsaNFTContract.NFTMethodsCapabilityPrivatePath) == nil {
            let adminResouce <- ImsaNFTContract.createAdminResource()
            signer.save(<- adminResouce, to: ImsaNFTContract.AdminResourceStoragePath)
            // link the UnlockedCapability in private storage
            signer.link<&{ImsaNFTContract.NFTMethodsCapability}>(
                ImsaNFTContract.NFTMethodsCapabilityPrivatePath,
                target: ImsaNFTContract.AdminResourceStoragePath
            )
        }

        signer.link<&{ImsaNFTContract.UserSpecialCapability}>(
            /public/UserSpecialCapability,
            target: ImsaNFTContract.AdminResourceStoragePath
        )

        let collection  <- ImsaNFTContract.createEmptyCollection()
        // store the empty NFT Collection in account storage
        signer.save( <- collection, to:ImsaNFTContract.CollectionStoragePath)
        log("Collection created for account".concat(signer.address.toString()))
        // create a public capability for the Collection
        signer.link<&{ImsaNFTContract.ImsaNFTContractCollectionPublic}>(ImsaNFTContract.CollectionPublicPath, target:ImsaNFTContract.CollectionStoragePath)
        log("Capability created")
    }
}
