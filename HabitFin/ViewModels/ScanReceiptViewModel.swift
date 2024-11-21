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
                        do {
                            // Save image to file system
                            let imagePath = try self.saveImageToFileSystem(image)
                            
                            // Create and save Receipt
                            let receipt = Receipt(
                                date: Date(),
                                items: items,
                                total: items.reduce(0.0) { $0 + ($1.total ?? 0.0) },
                                paymentType: "Unknown", // Placeholder; can be updated later
                                discountsTotal: items.reduce(0.0) { $0 + ($1.discount ?? 0.0) },
                                storeName: "Unknown", // Placeholder; can be updated later
                                image: imagePath
                            )
                            self.modelContext.insert(receipt)
                            try self.modelContext.save()
                        } catch {
                            self.alertMessage = "Failed to save receipt: \(error.localizedDescription)"
                            self.showingAlert = true
                        }
                    }
                }
            }
        }
    }

    private func saveImageToFileSystem(_ image: UIImage) throws -> String {
        let fileManager = FileManager.default
        let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageName = UUID().uuidString + ".png"
        let fileURL = folderURL.appendingPathComponent(imageName)
        
        if let imageData = image.pngData() {
            try imageData.write(to: fileURL)
            return fileURL.path
        } else {
            throw NSError(domain: "ImageSaveError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG data."])
        }
    }
}
