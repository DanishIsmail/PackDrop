import NFTContract from 0xf8d6e0586b0a20c7

transaction(admin: Address) {
    prepare(signer: AuthAccount) {

        // get the public account object for the Admin
        let TemplateAdminAccount = getAccount(admin)

        // get the public capability from the Admin's public storage
        let TemplateAdminResource = TemplateAdminAccount.getCapability
            <&{NFTContract.UserSpecialCapability}>
            (/public/UserSpecialCapability)
            .borrow()
            ?? panic("could not borrow reference to UserSpecialCapability")

        //get admin refrence for adding AdminCapability
        let adminRef = signer.getCapability<&NFTContract.AdminCapability>(NFTContract.AdminCapabilityPrivate).borrow() 
                        ?? panic("could not get borrow the refrence")
        let userResponse = adminRef.isWhiteListedAccount(_user: admin) 
        if(userResponse == false) {
            adminRef.addwhiteListedAccount(_user: admin)
        }
        

        // get the private capability from the Authorized owner of the AdminResource
        // this will be the signer of this transaction
        let specialCapability = signer.getCapability
            <&{NFTContract.NFTMethodsCapability}>
            (NFTContract.NFTMethodsCapabilityPrivatePath) 

        // if the special capability is valid...
        if specialCapability.check() {
            // ...add it to the TemplateAdminResource
            TemplateAdminResource.addCapability(cap: specialCapability)
            log("capability added")
        } else {
            // ...let the people know we failed
            panic("special capability is invalid!")
        }
    }
}