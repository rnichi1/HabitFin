import SwiftData
import Foundation

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

    func updateItem(_ item: Item) {
        // Update item in the list and persistent storage
    }
}
