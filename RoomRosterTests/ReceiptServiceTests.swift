import XCTest
@testable import RoomRoster

final class ReceiptServiceTests: XCTestCase {
    func testUploadAndFetch() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let service = ReceiptService(directory: tempDir)
        let data = "hello".data(using: .utf8)!
        let receipt = try service.uploadReceipt(data, for: "sale1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: receipt.pdfURL.path))
        let loaded = try service.fetchReceipt(for: "sale1")
        XCTAssertEqual(loaded, data)
    }
}
