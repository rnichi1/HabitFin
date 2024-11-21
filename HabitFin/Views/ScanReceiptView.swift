import SwiftUI
import PhotosUI
import SwiftData

struct ScanReceiptView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ScanReceiptViewModel
    @Query private var receipts: [Receipt] // Fetch saved receipts, sorted by date

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ScanReceiptViewModel(modelContext: modelContext))
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
                    .listStyle(InsetGroupedListStyle())
                } else {
                    Text("No receipts scanned yet.")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Divider()

                // Scan New Receipt Section
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(8)
                        .padding()
                } else {
                    PhotosPicker(selection: $viewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                        Text("Select Receipt Image")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    viewModel.processReceipt()
                }) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Process Receipt")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedImage == nil ? Color.gray.opacity(0.5) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(viewModel.selectedImage == nil || viewModel.isProcessing)
                .padding(.horizontal)
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
