import SwiftUI

struct ReceiptDetailView: View {
    let receipt: Receipt

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Display Receipt Image
                if let imagePath = receipt.image,
                   let image = UIImage(contentsOfFile: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                }

                // Display Store Information
                Text(receipt.storeName ?? "Unknown Store")
                    .font(.largeTitle)
                    .bold()

                Text(receipt.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown Date")
                    .foregroundColor(.secondary)

                // Display Receipt Total
                HStack {
                    Text("Total:")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "$%.2f", receipt.total ?? 0.0))
                        .bold()
                }

                // Display Discount Total
                HStack {
                    Text("Total Discounts:")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "$%.2f", receipt.discountsTotal ?? 0.0))
                        .foregroundColor(.green)
                }

                // List Items
                Divider()
                Text("Items:")
                    .font(.headline)

                ForEach(receipt.items ?? [], id: \.id) { item in
                    HStack {
                        Text(item.name ?? "Unknown Item")
                        Spacer()
                        Text("Qty: \(item.quantity ?? 0)")
                        Text(String(format: "$%.2f", item.total ?? 0.0))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
