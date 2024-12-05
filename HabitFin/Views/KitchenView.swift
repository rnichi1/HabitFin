import SwiftUI
import SwiftData

struct KitchenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    HStack {
                        Text(item.name ?? "Unknown Item")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "Qty: %.2f", item.quantity ?? 0.0))
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("My Kitchen")
            .toolbar {
                EditButton()
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
    }
}
