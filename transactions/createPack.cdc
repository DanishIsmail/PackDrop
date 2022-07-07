import PackContract from 0xf8d6e0586b0a20c7

transaction(packId: UInt64, totalNFTs: UInt64, packPrice: UFix64){
    //  packData: {String: AnyStruct},
    let adminRef: &PackContract.AdminPackResource
    prepare(acct: AuthAccount) {
        self.adminRef = acct.borrow<&PackContract.AdminPackResource>(from:PackContract.PackAdminStoragePath)
        ??panic("could not borrow admin reference")
    }
    execute{
        let packData: {String: AnyStruct} = {
            "packName": "MyPack"
        }
        self.adminRef.createPack(packId: packId, data: packData, totalNFTs: totalNFTs, packPrice: packPrice);
        log("Pack created")

    }

}
