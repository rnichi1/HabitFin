import Foundation

// GPT facing item dto
struct ItemDTO: Codable {
    var name: String?
    var category: String?
    var quantity: Double?
    var price: Double?
    var total: Double?     
}
