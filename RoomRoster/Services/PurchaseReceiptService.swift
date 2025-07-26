import Foundation

enum PurchaseReceiptServiceError: Error {
    case failedToConvertImage
    case uploadFailed(Error)
    case downloadURLNotFound
}

final class PurchaseReceiptService {
    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
    }

    func uploadReceiptPDF(_ data: Data, for itemId: String) async throws -> URL {
        return try await firebaseService.uploadData(
            data,
            to: "receipts/purchases/\(itemId).pdf",
            contentType: ReceiptFileType.pdf.mimeType
        )
    }

    func uploadReceipt(image: PlatformImage, for itemId: String) async throws -> URL {
        guard let data = image.jpegDataCompatible(compressionQuality: 0.8) else {
            throw PurchaseReceiptServiceError.failedToConvertImage
        }
        return try await firebaseService.uploadData(
            data,
            to: "receipts/purchases/\(itemId).jpg",
            contentType: ReceiptFileType.jpg.mimeType
        )
    }

    func loadReceipt(for itemId: String, type: ReceiptFileType = .pdf) async throws -> Data {
        let path = "receipts/purchases/\(itemId).\(type.fileExtension)"
        return try await firebaseService.downloadData(at: path)
    }
}
