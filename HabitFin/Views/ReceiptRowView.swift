import SwiftUI

struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        HStack {
            if let imagePath = receipt.image,
               let image = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("No Image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading) {
                Text(receipt.storeName ?? "Unknown Store")
                    .font(.headline)
                Text(receipt.date?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown Date")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "$%.2f", receipt.total ?? 0.0))
                .font(.headline)
        }
    }
}
