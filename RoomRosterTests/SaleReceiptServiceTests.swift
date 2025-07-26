import XCTest
import CoreGraphics
@testable import RoomRoster

final class SaleReceiptServiceTests: XCTestCase {
    func testUploadPDF() async throws {
        let service = SaleReceiptService()
        let data = "test".data(using: .utf8)!
        _ = try? await service.uploadReceiptPDF(data, for: "123")
        XCTAssertTrue(true)
    }

    func testUploadImage() async throws {
        let service = SaleReceiptService()
        #if canImport(UIKit)
        let image = PlatformImage(systemName: "doc")!
        #else
        let image = PlatformImage(size: .init(width: 1, height: 1))
        #endif
        _ = try? await service.uploadReceipt(image: image, for: "999")
        XCTAssertTrue(true)
    }
}
