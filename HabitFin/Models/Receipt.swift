import SwiftData
import Foundation

@Model
class Receipt: Identifiable {
    var id: UUID?
    var date: Date?
    var items: [Item]?
    var total: Double?
    var paymentType: String?
    var discountsTotal: Double?
    var storeName: String?
    var image: Data?

    init(
        id: UUID? = UUID(),
        date: Date? = Date(),
        items: [Item]? = nil,
        total: Double? = nil,
        paymentType: String? = nil,
        discountsTotal: Double? = nil,
        storeName: String? = nil,
        image: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.items = items
        self.total = total
        self.paymentType = paymentType
        self.discountsTotal = discountsTotal
        self.storeName = storeName
        self.image = image
    }
}
