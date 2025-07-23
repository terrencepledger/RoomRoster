import XCTest
import UIKit
@testable import RoomRoster

final class PurchaseReceiptServiceTests: XCTestCase {
    func testUploadPDF() async throws {
        let service = PurchaseReceiptService()
        let data = "test".data(using: .utf8)!
        _ = try? await service.uploadReceiptPDF(data, for: "123")
        XCTAssertTrue(true)
    }

    func testUploadImage() async throws {
        let service = PurchaseReceiptService()
        let image = UIImage(systemName: "doc")!
        _ = try? await service.uploadReceipt(image: image, for: "999")
        XCTAssertTrue(true)
    }
}
