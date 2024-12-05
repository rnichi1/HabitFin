import SwiftUI
import PhotosUI
import SwiftData

struct AddReceiptModalView: View {
    @ObservedObject var viewModel: ScanReceiptViewModel
    @Binding var showingAddReceiptModal: Bool

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                // If an image is selected, show it; otherwise, show the camera view
                if let image = viewModel.selectedImage {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .padding()
                        
                        Button(action: {
                            viewModel.processReceipt()
                            showingAddReceiptModal = false
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
                    }
                } else {
                    CameraView(viewModel: viewModel)
                        .edgesIgnoringSafeArea(.all)
                }

                // Photo Picker Icon
                PhotosPicker(selection: $viewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
    }
}
