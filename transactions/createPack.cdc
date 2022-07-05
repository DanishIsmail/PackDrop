import PackContract from 0xf8d6e0586b0a20c7

transaction(packId: UInt64, packName: String, totalNFTs: UInt64, packPrice: UFix64){
    let adminRef: &PackContract.Pack
    prepare(acct: AuthAccount) {
        self.adminRef = acct.borrow<&PackContract.Pack>(from:PackContract.PackStoragePath)
        ??panic("could not borrow admin reference")
    }
    execute{
        self.adminRef.createPack(packId: packId, packName: packName, totalNFTs: totalNFTs, packPrice: packPrice);

        log("Pack created")

    }

}

