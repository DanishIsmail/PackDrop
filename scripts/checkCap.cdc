import ImsaNFTContract from 0xf8d6e0586b0a20c7
import PackContract from 0xf8d6e0586b0a20c7

pub fun main():Bool{
    let account = getAccount(0x179b6b1cb6755e31)
    //let cap = account.getCapability(/public/UserSpecialCapability)
      //     .borrow<&{NFTContract.UserSpecialCapability}>()
    //let cap = account.getCapability(NFTContract.CollectionPublicPath)
      // .borrow<&{NonFungibleToken.CollectionPublic}>()
    let cap = account.getCapability
            <&{PackContract.PackOpenPublicMethods}>
            (PackContract.PackOpenPublicPath)
    //let cap = account.getCapability(PackContract.PackPublicPath).borrow<&{PackContract.PackPublicMethods}>()
      
    if cap == nil {
        return false
    }
    return true
}