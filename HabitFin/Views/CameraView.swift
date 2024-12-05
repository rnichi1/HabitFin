import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var viewModel: ScanReceiptViewModel
    @StateObject var camera = CameraModel()

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(camera: camera).ignoresSafeArea(.all, edges: .all)

            // White capture button at the bottom-center
            VStack {
                Spacer()
                Button(action: {
                    camera.takePic()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 65, height: 65)
                            .shadow(radius: 10)
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 75, height: 75)
                            .shadow(radius: 10)
                    }
                }
                .padding(.bottom, 80)
            }
            
            // Grid overlay
            GeometryReader { geometry in
                ZStack {
                    let width = geometry.size.width / 4 * 3
                    let height = geometry.size.height / 3 * 1.8
                    let horizontalLines = 6
                    let verticalLines = 3

                    ForEach(0...horizontalLines, id: \.self) { index in
                        Path { path in
                            let y = height / CGFloat(horizontalLines) * CGFloat(index)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    }

                    ForEach(0...verticalLines, id: \.self) { index in
                        Path { path in
                            let x = width / CGFloat(verticalLines) * CGFloat(index)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    }
                }
                .offset(y: geometry.size.width / 3.5 )
                .offset(x: (geometry.size.width - (geometry.size.width / 4 * 3)) / 2)
                .allowsHitTesting(false)
            }



            // Hint text
            VStack {
                Text("Align your receipt horizontally for the best results.\nEnsure the edges are within the frame.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.top, 16)
                Spacer()
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
        .onAppear(perform: {
            camera.viewModel = viewModel
            camera.Check()
        }
        )
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!

    var viewModel: ScanReceiptViewModel?

    func Check() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
        default:
            return
        }
    }

    func setUp() {
        do {
            session.beginConfiguration()
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let input = try AVCaptureDeviceInput(device: device!)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }

    func takePic() {
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let capturedImage = UIImage(data: imageData)

        DispatchQueue.main.async {
            self.viewModel?.selectedImage = capturedImage
            self.session.stopRunning()
        }
    }
}



struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        camera.session.startRunning()
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
