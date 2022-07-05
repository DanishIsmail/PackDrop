import PackContract from 0xf8d6e0586b0a20c7

transaction(){
    let adminRef: &PackContract.Pack
    prepare(acct: AuthAccount) {
        self.adminRef = acct.borrow<&PackContract.Pack>(from:PackContract.PackStoragePath)
        ??panic("could not borrow admin reference")
    }
    execute{
        let ids: [UInt64] =  [1,2,3,4,5]
        self.adminRef.addAvailableNFTs(templateIds: ids)

        log("nft-ids added")

    }

}