import SwiftData
import Foundation

@Model
class Item: Identifiable {
    var id: UUID?
    var name: String?
    var category: String?
    var quantity: Int?
    var price: Double?
    var total: Double?
    var discount: Double?

    init(
        id: UUID? = UUID(),
        name: String? = nil,
        category: String? = nil,
        quantity: Int? = 1,
        price: Double? = nil,
        total: Double? = nil,
        discount: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.price = price
        self.total = total
        self.discount = discount
    }
}
