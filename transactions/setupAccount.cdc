import NFTContract from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {
        let collection  <- NFTContract.createEmptyCollection()
        // store the empty NFT Collection in account storage
        acct.save( <- collection, to:NFTContract.CollectionStoragePath)
        // create a public capability for the Collection
        acct.link<&{NFTContract.NFTContractCollectionPublic}>(NFTContract.CollectionPublicPath, target:NFTContract.CollectionStoragePath)
    }
}