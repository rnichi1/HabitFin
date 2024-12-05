import SwiftUI

struct CameraView: View {
    @ObservedObject var viewModel: ScanReceiptViewModel
    @State private var coordinator: CameraViewControllerRepresentable.Coordinator?

    var body: some View {
        ZStack {
            // Camera preview
            CameraViewControllerRepresentable { capturedImage in
                if let image = capturedImage {
                    viewModel.selectedImage = image
                    viewModel.isProcessing = false
                } else {
                    viewModel.alertMessage = "Failed to capture photo."
                    viewModel.showingAlert = true
                    viewModel.isProcessing = false
                }
            }
            .onAppear {
                coordinator = CameraViewControllerRepresentable(onPhotoCaptured: { _ in }).makeCoordinator()
            }
            .edgesIgnoringSafeArea(.all)

            // White capture button at the bottom-center
            VStack {
                Spacer()
                Button(action: {
                    viewModel.isProcessing = true
                    coordinator?.capturePhoto()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .shadow(radius: 10)
                }
                .padding(.bottom, 20)
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Image Selection"),
                  message: Text(viewModel.alertMessage),
                  dismissButton: .default(Text("OK")))
        }
        .overlay(
            Group {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }
        )
    }
}
