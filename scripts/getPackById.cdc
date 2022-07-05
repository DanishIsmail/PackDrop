import PackContract from 0xf8d6e0586b0a20c7

pub fun main(packId: UInt64): PackContract.PackData {
    return  PackContract.getPackById(packId: packId)
    
}