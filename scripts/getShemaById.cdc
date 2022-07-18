import NFTContract from 0xf8d6e0586b0a20c7

pub fun main(schemaId: UInt64): NFTContract.Schema {
    return NFTContract.getSchemaById(schemaId: schemaId)
}