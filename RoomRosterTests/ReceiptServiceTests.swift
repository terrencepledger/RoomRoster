import XCTest
@testable import RoomRoster

final class ReceiptServiceTests: XCTestCase {
    func testSaveAndLoadReceipt() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let service = ReceiptService(directory: dir)
        let sale = Sale(itemId: "1", date: Date(), price: 10, condition: .new, buyerName: "a", buyerContact: nil, soldBy: "b", department: "c")
        let data = "test".data(using: .utf8)!
        let receipt = try service.saveReceipt(data, for: sale)
        let loaded = try service.loadReceipt(for: receipt)
        XCTAssertEqual(loaded, data)
    }
}
