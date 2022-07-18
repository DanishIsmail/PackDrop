import NonFungibleToken from 0xf8d6e0586b0a20c7
import NFTContract from 0xf8d6e0586b0a20c7
import PackContract from 0xf8d6e0586b0a20c7

transaction(packId: UInt64, receiptAccount: Address){
    prepare(providerAccount:AuthAccount) {
        let ownerCollectionRef = providerAccount.borrow<&PackContract.PackCollection>(from: PackContract.PackCollectionStoragePath)
                                ?? panic("could not borrow the owner refrence to the collection")
        let userPack <-ownerCollectionRef.withdrawPack(withdrawPackId: packId)

        userPack.openPack(receiptAccount: receiptAccount)
        
        destroy  userPack
    }
    execute{
        log("Pack opend")

    }

}