import Foundation
import UIKit
import FirebaseStorage

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
    private let storage = Storage.storage()

    func uploadReceiptPDF(_ data: Data, for itemId: String) async throws -> URL {
        try await uploadReceipt(data, for: itemId, type: .pdf)
    }

    func uploadReceipt(image: UIImage, for itemId: String) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PurchaseReceiptServiceError.failedToConvertImage
        }
        return try await uploadReceipt(data, for: itemId, type: .jpg)
    }

    func loadReceipt(for itemId: String, type: ReceiptFileType = .pdf) async throws -> Data {
        let url = try await downloadReceiptURL(for: itemId, type: type)
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    private func uploadReceipt(_ data: Data, for itemId: String, type: ReceiptFileType) async throws -> URL {
        let ref = storage.reference().child("receipts/\(itemId).\(type.fileExtension)")
        let metadata = StorageMetadata()
        metadata.contentType = type.mimeType
        try await withCheckedThrowingContinuation { cont in
            ref.putData(data, metadata: metadata) { _, error in
                if let error = error {
                    cont.resume(throwing: PurchaseReceiptServiceError.uploadFailed(error))
                } else {
                    cont.resume(returning: ())
                }
            }
        }
        return try await downloadReceiptURL(for: itemId, type: type)
    }

    private func downloadReceiptURL(for itemId: String, type: ReceiptFileType) async throws -> URL {
        let ref = storage.reference().child("receipts/\(itemId).\(type.fileExtension)")
        return try await withCheckedThrowingContinuation { cont in
            ref.downloadURL { url, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let url = url {
                    cont.resume(returning: url)
                } else {
                    cont.resume(throwing: PurchaseReceiptServiceError.downloadURLNotFound)
                }
            }
        }
    }
}
