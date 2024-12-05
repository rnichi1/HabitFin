import Foundation

struct ReceiptDTO: Codable {
    let storeName: String
    let date: String
    let total: Double
    let paymentType: String?
    let discountsTotal: Double?
    let items: [ItemDTO]
    let currency: String
}

