import Vision
import UIKit

class OCRService {
    func recognizeText(from image: UIImage, completion: @escaping (String, UIImage?) -> Void) {
        // Normalize image orientation
        let normalizedImage = image.normalizedOrientation()
        guard let cgImage = normalizedImage.cgImage else {
            print("Failed to get CGImage from UIImage")
            completion("", nil)
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text observations found")
                completion("", nil)
                return
            }

            // Process observations into structured receipt lines
            let text = self.processReceiptObservations(observations, for: normalizedImage)

            // Generate debugging image
            let debugImage = self.drawBoundingBoxes(for: normalizedImage, observations: observations)

            print("Processed Receipt Text:\n\(text)")
            completion(text, debugImage)
        }

        // Configure recognition preferences
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "de-DE"]
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform the text recognition request: \(error).")
                completion("", nil)
            }
        }
    }

    private func processReceiptObservations(_ observations: [VNRecognizedTextObservation], for image: UIImage) -> String {
        // Convert observations to strings with their bounding boxes and transform the bounding boxes
        let textObservations = observations
            .map { observation -> TextObservation in
                let text = observation.topCandidates(1).first?.string ?? ""
                let box = transformBoundingBox(observation.boundingBox, for: image)
                return TextObservation(
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                    box: box
                )
            }
            .filter { !$0.text.isEmpty }
            .sorted { $0.box.minY < $1.box.minY }
        
        var orderedText = ""
        textObservations.forEach {
            orderedText += $0.text + "\n"
        }

        return (orderedText)
    }

    // Bounding boxes on image so users see what was recognized
    private func drawBoundingBoxes(for image: UIImage, observations: [VNRecognizedTextObservation]) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            image.draw(at: .zero)

            context.cgContext.setStrokeColor(UIColor.red.cgColor)
            context.cgContext.setLineWidth(2.0)

            let imageSize = CGSize(width: image.size.width, height: image.size.height)

            for observation in observations {
                // Transform the bounding box to match UIKit's coordinate system (Since it's not the same for Vision)
                let boundingBox = transformBoundingBox(observation.boundingBox, for: image)

                // Convert normalized coordinates to image coordinates
                let rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))

                // Draw the bounding box
                context.cgContext.stroke(rect)
            }
        }
    }


    private func transformBoundingBox(_ box: CGRect, for image: UIImage) -> CGRect {
        var transformedBox = box

        switch image.imageOrientation {
        case .up, .upMirrored:
            // UIKit expects the origin to be at the top-left, so flip the Y-axis
            transformedBox = CGRect(
                x: box.minX,
                y: 1.0 - box.maxY,
                width: box.width,
                height: box.height
            )

        case .down, .downMirrored:
            // Rotate 180 degrees and flip the Y-axis
            transformedBox = CGRect(
                x: 1.0 - box.maxX,
                y: box.minY,
                width: box.width,
                height: box.height
            )

        case .left, .leftMirrored:
            // Rotate 90 degrees counter-clockwise
            transformedBox = CGRect(
                x: box.minY,
                y: box.minX,
                width: box.height,
                height: box.width
            )

        case .right, .rightMirrored:
            // Rotate 90 degrees clockwise
            transformedBox = CGRect(
                x: 1.0 - box.maxY,
                y: 1.0 - box.minX,
                width: box.height,
                height: box.width
            )

        default:
            break
        }

        return transformedBox
    }

}

// Supporting extensions and structs
extension UIImage {
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}

struct ReceiptItem {
    var name: String = ""
    var price: Double?
}

struct TextObservation {
    let text: String
    let box: CGRect
}
