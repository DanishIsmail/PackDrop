import ImsaNFTContract from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {
        let collection  <- ImsaNFTContract.createEmptyCollection()
        // store the empty NFT Collection in account storage
        acct.save( <- collection, to:ImsaNFTContract.CollectionStoragePath)
        // create a public capability for the Collection
        acct.link<&{ImsaNFTContract.ImsaNFTContractCollectionPublic}>(ImsaNFTContract.CollectionPublicPath, target:ImsaNFTContract.CollectionStoragePath)
    }
}