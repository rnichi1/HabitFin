import SwiftUI
import PhotosUI
import SwiftData

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
    private let gptService = GPTService(apiKey: "gpt key")
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

    func processReceipt() {
        guard let image = selectedImage else {
            alertMessage = "Please select an image."
            showingAlert = true
            return
        }

        isProcessing = true

        ocrService.recognizeText(from: image) { [weak self] text in
            guard let self = self else { return }
            self.gptService.processReceiptText(text) { items in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if items.isEmpty {
                        self.alertMessage = "No items found on the receipt."
                        self.showingAlert = true
                    } else {
                        // Update the model context with new items
                        do {
                            for item in items {
                                self.modelContext.insert(item)
                            }
                            try self.modelContext.save()
                        } catch {
                            self.alertMessage = "Failed to save items: \(error.localizedDescription)"
                            self.showingAlert = true
                        }
                    }
                }
            }
        }
    }
}
