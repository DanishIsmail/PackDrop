import PackContract from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

transaction(packId: UInt64, price: UFix64, receiptAccount: Address, ownerAccount: Address){
    
    prepare(tokenRecipientAccount:AuthAccount) {

        let AdminAccount = getAccount(ownerAccount)

        let adminRef = AdminAccount.getCapability
            <&{PackContract.PackPublicMethods}>
            (PackContract.PackAdminPublicPath)
            .borrow()
            ?? panic("could not borrow reference to UserSpecialCapability")
       
        let vaultRef = tokenRecipientAccount.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) 
         ?? panic("Could not borrow buyer vault reference")
        
        adminRef.purchasePack(packId: packId, flowPayment: <- vaultRef.withdraw(amount: price), receiptAccount: receiptAccount)
       
        
    }
    execute{
        log("Pack purchased")

    }

}


