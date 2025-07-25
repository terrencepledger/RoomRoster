import Foundation

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
