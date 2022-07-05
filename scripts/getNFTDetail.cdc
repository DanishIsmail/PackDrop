import ImsaNFTContract from 0xf8d6e0586b0a20c7

pub fun main(nftId: UInt64) : AnyStruct{    
    var nftData = ImsaNFTContract.getNFTDataById(nftId: nftId)
    return nftData
}