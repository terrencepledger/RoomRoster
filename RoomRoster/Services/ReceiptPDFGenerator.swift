import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import CoreGraphics

struct ReceiptPDFGenerator {
    static func generate(for sale: Sale) -> Data? {
        #if canImport(UIKit)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 300, height: 200),
            format: format
        )
        return renderer.pdfData { ctx in
            ctx.beginPage()
            let text = "Sale Receipt\nItem: \(sale.itemId)\nDate: \(sale.date.toShortString())\nPrice: \(sale.price ?? 0)"
            text.draw(
                at: CGPoint(x: 20, y: 20),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )
        }
        #elseif canImport(AppKit)
        let data = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 300, height: 200)
        guard
            let consumer = CGDataConsumer(data: data as CFMutableData),
            let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else {
            return nil
        }
        context.beginPDFPage(nil)
        let text = "Sale Receipt\nItem: \(sale.itemId)\nDate: \(sale.date.toShortString())\nPrice: \(sale.price ?? 0)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12)
        ]
        let string = NSAttributedString(string: text, attributes: attrs)
        NSGraphicsContext.saveGraphicsState()
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = graphicsContext
        string.draw(at: CGPoint(x: 20, y: mediaBox.height - 40))
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
        context.closePDF()
        return data as Data
        #else
        return nil
        #endif
    }
}
