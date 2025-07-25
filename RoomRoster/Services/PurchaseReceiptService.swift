import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum PurchaseReceiptServiceError: Error {
    case failedToConvertImage
    case uploadFailed(Error)
    case downloadURLNotFound
}

enum ReceiptFileType: String {
    case pdf
    case jpg
    case png

    var fileExtension: String { rawValue }
    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .jpg: return "image/jpeg"
        case .png: return "image/png"
        }
    }
}

final class PurchaseReceiptService {
    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
    }

    func uploadReceiptPDF(_ data: Data, for itemId: String) async throws -> URL {
        return try await firebaseService.uploadData(
            data,
            to: "receipts/\(itemId).pdf",
            contentType: ReceiptFileType.pdf.mimeType
        )
    }

    func uploadReceipt(image: UIImage, for itemId: String) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PurchaseReceiptServiceError.failedToConvertImage
        }
        return try await firebaseService.uploadData(
            data,
            to: "receipts/\(itemId).jpg",
            contentType: ReceiptFileType.jpg.mimeType
        )
    }

    func loadReceipt(for itemId: String, type: ReceiptFileType = .pdf) async throws -> Data {
        let path = "receipts/\(itemId).\(type.fileExtension)"
        return try await firebaseService.downloadData(at: path)
    }
}
