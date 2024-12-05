import SwiftUI

struct ReceiptDetailView: View {
    let receipt: Receipt

    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Display Receipt Image
                if let imageData = receipt.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                }

                // Display Store Information
                Text(receipt.storeName ?? "Unknown Store")
                    .font(.largeTitle)
                    .bold()

                Text(formatDate(date: receipt.date))
                    .foregroundColor(.secondary)
                
                Text(receipt.paymentType ?? "")
                    .font(.caption)
                    .bold()

                // Display Receipt Total
                HStack {
                    Text("Total:")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "\(receipt.currency ?? "") %.2f", receipt.total ?? 0.0))
                        .bold()
                }

                // Display Discount Total
                HStack {
                    Text("Total Discounts:")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "\(receipt.currency ?? "") %.2f", receipt.discountsTotal ?? 0.0))
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
                        Text(String(format: "Qty: %.2f", item.quantity ?? 0.0))
                        Text(String(format: "\(receipt.currency ?? "") %.2f", item.total ?? 0.0))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}


