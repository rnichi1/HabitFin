import SwiftUI
import PhotosUI
import SwiftData

struct AddReceiptModalView: View {
    @ObservedObject var viewModel: ScanReceiptViewModel

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomLeading) {
                // Camera View
                CameraView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)

                // Show selected image if available
                if let image = viewModel.selectedImage {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .padding()
                        Spacer()
                    }
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
