import SwiftData
import Foundation

// Save and delete items
class KitchenViewModel: ObservableObject {
    @Published var items: [Item] = []

    func addItem(_ item: Item) {
        items.append(item)
        // Save to persistent storage
    }

    func removeItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        // Update persistent storage
    }
}
