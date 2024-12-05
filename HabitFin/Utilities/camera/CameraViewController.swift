import SwiftUI
import AVFoundation
import UIKit

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoOutput = AVCapturePhotoOutput()
    var photoCaptureCompletionBlock: ((UIImage?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }

        captureSession.beginConfiguration()
        
        // Set up input device (camera)
        if let videoDevice = AVCaptureDevice.default(for: .video),
           let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
           captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        // Set up output device (photo output)
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        captureSession.commitConfiguration()

        // Set up preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }

        // Start the session on a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        print("here")
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("now here")
        photoCaptureCompletionBlock = completion
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            guard let imageData = photo.fileDataRepresentation(), error == nil else {
                self.photoCaptureCompletionBlock?(nil)
                return
            }

            let image = UIImage(data: imageData)
            self.photoCaptureCompletionBlock?(image)
        }
    }
}


struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    var onPhotoCaptured: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        context.coordinator.viewController = viewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
            return Coordinator(self)
        }

        class Coordinator: NSObject {
            var parent: CameraViewControllerRepresentable
            var viewController: CameraViewController?

            init(_ parent: CameraViewControllerRepresentable) {
                self.parent = parent
            }

            func capturePhoto() {
                guard let viewController = viewController else { return }
                viewController.takePhoto { [weak self] image in
                    DispatchQueue.main.async {
                        self?.parent.onPhotoCaptured(image)
                    }
                }
            }

        }
    }


