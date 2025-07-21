import Foundation
import UIKit

enum PurchaseReceiptServiceError: Error {
    case writeFailed(Error)
    case fileNotFound
    case failedToConvertImage
}

enum ReceiptFileType: String {
    case pdf
    case jpg
    case png

    var fileExtension: String { rawValue }
}

class PurchaseReceiptService {
    private let directory: URL

    init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory) {
        self.directory = directory.appendingPathComponent("purchase_receipts", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func saveReceiptPDF(_ data: Data, for itemId: String) throws -> URL {
        try saveReceipt(data, for: itemId, type: .pdf)
    }

    func saveReceipt(_ data: Data, for itemId: String, type: ReceiptFileType = .pdf) throws -> URL {
        let fileURL = directory.appendingPathComponent("\(itemId).\(type.fileExtension)")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw PurchaseReceiptServiceError.writeFailed(error)
        }
    }

    func saveReceipt(image: UIImage, for itemId: String) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw PurchaseReceiptServiceError.failedToConvertImage
        }
        return try saveReceipt(data, for: itemId, type: .jpg)
    }

    func loadReceipt(for itemId: String, type: ReceiptFileType = .pdf) throws -> Data {
        let fileURL = directory.appendingPathComponent("\(itemId).\(type.fileExtension)")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw PurchaseReceiptServiceError.fileNotFound
        }
        return try Data(contentsOf: fileURL)
    }
}
