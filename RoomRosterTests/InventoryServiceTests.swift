import XCTest
@testable import RoomRoster

final class InventoryServiceTests: XCTestCase {
    func testFetchInventoryUsesNetwork() async throws {
        let mock = MockNetworkService()
        let expected = GoogleSheetsResponse(range: "Inventory!A:B", majorDimension: "ROWS", values: [["id","name"],["1","Item"]])
        mock.authorizedFetchResults = [expected]
        let service = InventoryService(sheetId: "sheet", networkService: mock)
        let result = try await service.fetchInventory()
        XCTAssertEqual(mock.authorizedFetchInputs.first?.absoluteString, "https://sheets.googleapis.com/v4/spreadsheets/sheet/values/Inventory")
        XCTAssertEqual(result.range, expected.range)
    }

    func testUpdateItemSendsPutRequest() async throws {
        let mock = MockNetworkService()
        let inventory = GoogleSheetsResponse(range: "Inventory", majorDimension: "ROWS", values: [["id","name"],["123","Old"]])
        mock.authorizedFetchResults = [inventory]
        let service = InventoryService(sheetId: "sheet", networkService: mock)
        var item = Item.empty()
        item.id = "123"
        item.name = "New"
        try await service.updateItem(item)
        XCTAssertEqual(mock.authorizedRequests.first?.1, "PUT")
        XCTAssertEqual(mock.sentRequests.count, 1)
    }

    func testCreateItemSendsTagRange() async throws {
        let mock = MockNetworkService()
        let service = InventoryService(sheetId: "sheet", networkService: mock)
        var item = Item.empty()
        item.quantity = 2
        item.propertyTagRange = PropertyTagRange(tags: [
            PropertyTag(rawValue: "A0001")!,
            PropertyTag(rawValue: "A0002")!
        ])
        try await service.createItem(item)
        let body = mock.authorizedRequests.first?.2
        let row = (body?["values"] as? [[String]])?.first
        let index = ItemField.allCases.firstIndex(of: .propertyTag)!
        XCTAssertEqual(row?[index], "A0001-A0002")
    }
}
