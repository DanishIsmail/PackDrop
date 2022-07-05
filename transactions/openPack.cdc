import NonFungibleToken from 0xf8d6e0586b0a20c7
import ImsaNFTContract from 0xf8d6e0586b0a20c7
import PackContract from 0xf8d6e0586b0a20c7

transaction(packId: UInt64, receiptAccount: Address){
    
    prepare(tokenRecipientAccount:AuthAccount) {
        let adminRef = tokenRecipientAccount.borrow<&PackContract.PackOpen>(from: PackContract.PackOpenStoragePath)
            ?? panic("could not borrow reference to UserSpecialCapability")
       
       adminRef.openPack(packId: packId,  receiptAccount: receiptAccount)
    }
    execute{
        log("Pack opend")
    }

}