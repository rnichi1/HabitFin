import SwiftUI
import PhotosUI
import SwiftData

struct ReceiptView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ScanReceiptViewModel
    @Query private var receipts: [Receipt] // Fetch saved receipts, sorted by date
    @Binding var showingAddReceiptModal: Bool

    init(modelContext: ModelContext, showingAddReceiptModal: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: ScanReceiptViewModel(modelContext: modelContext))
        _showingAddReceiptModal = showingAddReceiptModal
    }

    var body: some View {
        NavigationView {
            VStack {
                // List of Scanned Receipts
                if !receipts.isEmpty {
                    List {
                        Section(header: Text("Scanned Receipts")) {
                            ForEach(receipts) { receipt in
                                NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                    ReceiptRowView(receipt: receipt)
                                }
                            }
                            .onDelete(perform: deleteReceipts)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                } else {
                    VStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .padding()
                        Text("No receipts scanned yet.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        Button(action: {
                            showingAddReceiptModal = true
                        }) {
                            Text("Scan Your First Receipt")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Receipts")
            .padding()
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(title: Text("Notice"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func deleteReceipts(at offsets: IndexSet) {
        for index in offsets {
            let receipt = receipts[index]
            modelContext.delete(receipt)
        }
    }
}
