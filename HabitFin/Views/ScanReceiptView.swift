import SwiftUI
import PhotosUI
import SwiftData

struct ScanReceiptView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ScanReceiptViewModel

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ScanReceiptViewModel(modelContext: modelContext))
    }

    var body: some View {
        VStack {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                PhotosPicker(selection: $viewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                    Text("Select Receipt Image")
                        .foregroundColor(.blue)
                }
            }

            Button(action: {
                viewModel.processReceipt()
            }) {
                if viewModel.isProcessing {
                    ProgressView()
                } else {
                    Text("Process Receipt")
                }
            }
            .padding()
            .disabled(viewModel.selectedImage == nil || viewModel.isProcessing)
        }
        .padding()
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Notice"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
