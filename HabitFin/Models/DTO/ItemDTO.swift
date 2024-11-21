import Foundation

struct ItemDTO: Codable {
    var name: String?
    var category: String?
    var quantity: Int?
    var price: Double?
    var total: Double?        
    var discount: Double?
}
