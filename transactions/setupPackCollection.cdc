import PackContract from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: AuthAccount) {
        let collection  <- PackContract.createPackCollection()
        // store the empty NFT Collection in account storage
        acct.save( <- collection, to:PackContract.PackCollectionStoragePath)
        // create a public capability for the Collection
        acct.link<&{PackContract.PackCollectionPublicMethods}>(PackContract.PackCollectionPublicPath, target: PackContract.PackCollectionStoragePath)
    }
}