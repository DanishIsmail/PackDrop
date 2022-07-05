import ImsaNFTContract from 0xf8d6e0586b0a20c7
pub fun main(brandId:UInt64): AnyStruct{
    return ImsaNFTContract.getBrandById(brandId: brandId)
}