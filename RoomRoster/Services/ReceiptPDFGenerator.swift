import Foundation
#if canImport(UIKit)
import UIKit

struct ReceiptPDFGenerator {
    static func generate(for sale: Sale) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 300, height: 200), format: format)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let text = "Sale Receipt\nItem: \(sale.itemId)\nDate: \(sale.date.toShortString())\nPrice: \(sale.price ?? 0)"
            text.draw(at: CGPoint(x: 20, y: 20), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
        }
        return data
    }
}
#endif
