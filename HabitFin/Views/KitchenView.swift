import SwiftUI
import SwiftData

struct KitchenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.name) private var items: [Item]
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isAddItemPresented = false
    
    // Computed property to filter items
    private var filteredItems: [Item] {
        items.filter { item in
            let nameMatches = searchText.isEmpty ||
                (item.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            let categoryMatches = selectedCategory == nil ||
                item.category == selectedCategory
            return nameMatches && categoryMatches
        }
    }
    
    // Unique categories from items
    private var categories: [String] {
        Array(Set(items.compactMap { $0.category })).sorted()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Category and Search Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        // All Items filter
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        // Dynamic category chips
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Items List
                List {
                    ForEach(filteredItems) { item in
                        ItemRow(item: item)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("My Kitchen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddItemPresented = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddItemPresented) {
                AddItemView()
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = filteredItems[index]
                modelContext.delete(item)
            }
        }
    }
}

// Custom Category Chip View
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search items", text: $text)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// Item Row Component
struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name ?? "Unknown Item")
                    .font(.headline)
                
                if let category = item.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "Qty: %.2f", item.quantity ?? 0.0))
                    .font(.subheadline)
                
                if let price = item.price {
                    Text(String(format: "$%.2f", price))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Modal content for adding new item manually
struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var itemName = ""
    @State private var itemQuantity: Double = 1.0
    @State private var itemCategory = ""
    @State private var itemPrice: Double?
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Item Name", text: $itemName)
                
                TextField("Category", text: $itemCategory)
                
                Stepper(
                    "Quantity: \(String(format: "%.2f", itemQuantity))",
                    value: $itemQuantity,
                    in: 0...100,
                    step: 0.5
                )
                
                TextField("Price (Optional)",
                          value: $itemPrice,
                          format: .number)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }
    
    // Save item with SwiftData
    private func saveItem() {
        // Calculate total if both quantity and price exist
        let totalValue = itemPrice.map { $0 * itemQuantity }
        
        // Create a new Item
        let newItem = Item(
            name: itemName,
            category: itemCategory.isEmpty ? nil : itemCategory,
            quantity: itemQuantity,
            price: itemPrice,
            total: totalValue
        )
        
        // Insert the new item into the model context
        modelContext.insert(newItem)
        
        // Save changes and dismiss the view
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving item: \(error)")
            // In a real app, you might want to show an error alert
        }
    }
}
