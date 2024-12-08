import SwiftUI
import PhotosUI
import SwiftData

// Model that handles all the states and handling of OCR scanning and GPT calls
class ScanReceiptViewModel: ObservableObject {
    @Published var imageSelection: PhotosPickerItem? {
        didSet {
            loadImage()
        }
    }
    @Published var selectedImage: UIImage?
    @Published var isProcessing = false
    @Published var showingAlert = false
    @Published var alertMessage = ""

    private let ocrService = OCRService()
    private let gptService = GPTService()
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadImage() {
        guard let imageSelection = imageSelection else { return }
        imageSelection.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data?):
                    if let uiImage = UIImage(data: data) {
                        self.selectedImage = uiImage
                    } else {
                        self.alertMessage = "Failed to load image."
                        self.showingAlert = true
                    }
                case .success(nil):
                    self.alertMessage = "No image data found."
                    self.showingAlert = true
                case .failure(let error):
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                }
            }
        }
    }

    // ocr and gpt integration
    func processReceipt() {
        guard let image = selectedImage else {
            alertMessage = "Please select an image."
            showingAlert = true
            return
        }

        isProcessing = true

        // pass image to ocr
        ocrService.recognizeText(from: image) { [weak self] text, debugImage in
            guard let self = self else { return }

            // pass ocr text to gpt
            self.gptService.processReceiptText(text) { receipt in
                DispatchQueue.main.async {
                    self.isProcessing = false

                    if let receipt = receipt, let items = receipt.items, !items.isEmpty {
                        do {
                            // Safely use the debug image (with bounding boxes)
                            if let debugImage = debugImage, let imageData = debugImage.pngData() {
                                
                                // Update receipt details with saved debug image data
                                receipt.imageData = imageData

                                // Save receipt to context
                                self.modelContext.insert(receipt)
                                try self.modelContext.save()
                            } else {
                                self.alertMessage = "Failed to generate debug image data."
                                self.showingAlert = true
                            }
                        } catch {
                            self.alertMessage = "Failed to save receipt: \(error.localizedDescription)"
                            self.showingAlert = true
                        }
                    } else {
                        self.alertMessage = "No items found on the receipt."
                        self.showingAlert = true
                    }
                }
            }
        }

    }
}
