import NFTContract from 0xf8d6e0586b0a20c7
pub fun main(templateId: UInt64): NFTContract.Template {
    return NFTContract.getTemplateById(templateId: templateId)
}

