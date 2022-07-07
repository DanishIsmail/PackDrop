import PackContract from 0xf8d6e0586b0a20c7

transaction(){
    let adminRef: &PackContract.AdminPackResource
    prepare(acct: AuthAccount) {
        self.adminRef = acct.borrow<&PackContract.AdminPackResource>(from:PackContract.PackAdminStoragePath)
        ??panic("could not borrow admin reference")
    }
    execute{
        //let ids: [UInt64] =  [1,2,3,4,5]
        let  ids: {UInt64: UInt64} = {
            1: 100,
            2: 100,
            3: 100,
            4: 100,
            5: 100
        }
        self.adminRef.addAvailableNFTs(templateIds: ids)

        log("nft-ids added")

    }

}