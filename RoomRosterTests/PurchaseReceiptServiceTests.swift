import XCTest
@testable import RoomRoster

final class PurchaseReceiptServiceTests: XCTestCase {
    func testSaveAndLoadReceipt() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let service = PurchaseReceiptService(directory: tempDir)
        let data = "test".data(using: .utf8)!
        let url = try service.saveReceiptPDF(data, for: "123")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let loaded = try service.loadReceipt(for: "123", type: .pdf)
        XCTAssertEqual(loaded, data)
    }

    func testSaveReceiptImage() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let service = PurchaseReceiptService(directory: tempDir)
        let image = UIImage(systemName: "doc")!
        let url = try service.saveReceipt(image: image, for: "999")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}
