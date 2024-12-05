import SwiftData
import Foundation

@Model
class Item: Identifiable {
    var id: UUID?
    var name: String?
    var category: String?
    var quantity: Double?
    var price: Double?
    var total: Double?

    init(
        id: UUID? = UUID(),
        name: String? = nil,
        category: String? = nil,
        quantity: Double? = 1.0,
        price: Double? = nil,
        total: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.price = price
        self.total = total
    }
}
