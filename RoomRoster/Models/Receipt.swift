import Foundation

struct Receipt: Identifiable, Codable {
    var id: String { saleId }
    let saleId: String
    let date: Date
    let pdfURL: URL
}
