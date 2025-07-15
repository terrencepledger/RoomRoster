import XCTest
@testable import RoomRoster

final class InventoryServiceTests: XCTestCase {
    func testFetchInventoryUsesNetwork() async throws {
        let mock = MockNetworkService()
        let expected = GoogleSheetsResponse(range: "Inventory!A:B", majorDimension: "ROWS", values: [["id","name"],["1","Item"]])
        mock.fetchDataResults = [expected]
        let service = InventoryService(sheetId: "sheet", apiKey: "key", networkService: mock)
        let result = try await service.fetchInventory()
        XCTAssertEqual(mock.fetchDataInputs.first, "https://sheets.googleapis.com/v4/spreadsheets/sheet/values/Inventory?key=key")
        XCTAssertEqual(result.range, expected.range)
    }

    func testUpdateItemSendsPutRequest() async throws {
        let mock = MockNetworkService()
        let inventory = GoogleSheetsResponse(range: "Inventory", majorDimension: "ROWS", values: [["id","name"],["123","Old"]])
        mock.fetchDataResults = [inventory]
        let service = InventoryService(sheetId: "sheet", apiKey: "key", networkService: mock)
        var item = Item.empty()
        item.id = "123"
        item.name = "New"
        try await service.updateItem(item)
        XCTAssertEqual(mock.authorizedRequests.first?.1, "PUT")
        XCTAssertEqual(mock.sentRequests.count, 1)
    }
}
