import SwiftUI
import PhotosUI
import SwiftData

struct AddReceiptModalView: View {
    @ObservedObject var viewModel: ScanReceiptViewModel
    @Binding var showingAddReceiptModal: Bool

    // Modal for adding new Receipt (Includes Camera and Image Picker)
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                if let image = viewModel.selectedImage {
                    VStack {
                        // Selected image preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .padding()
                        
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        } else {
                            Button(action: {
                                viewModel.processReceipt()
                            }) {
                                Text("Process Image")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding([.leading, .trailing], 16)
                            }
                            .disabled(viewModel.isProcessing)
                        }
                    }
                } else {
                    // camera
                    CameraView(viewModel: viewModel)
                        .edgesIgnoringSafeArea(.all)
                    
                    // picker
                    PhotosPicker(selection: $viewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 60)
                    }
                }
            
            }
        }
        .onChange(of: viewModel.isProcessing) { isProcessing in
            if !isProcessing {
                // Close the modal only when processing is complete
                showingAddReceiptModal = false
            }
        }
    }
}

