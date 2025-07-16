import XCTest
@testable import RoomRoster

final class SalesServiceTests: XCTestCase {
    func testRecordSaleSendsPost() async throws {
        let mock = MockNetworkService()
        let service = SalesService(sheetId: "sheet", apiKey: "key", networkService: mock)
        let sale = Sale(itemId: "1", date: Date(), price: 10, condition: .good, buyerName: "B", buyerContact: "b@example.com", soldBy: "S", department: "D")
        try await service.recordSale(sale)
        XCTAssertEqual(mock.authorizedRequests.first?.1, "POST")
        XCTAssertEqual(mock.sentRequests.count, 1)
    }

    func testFetchSalesUsesNetwork() async throws {
        let mock = MockNetworkService()
        let sheet = GoogleSheetsResponse(range: "Sales", majorDimension: "ROWS", values: [["id","date","price","cond","buyer","contact","sold","dept"],["1","1/1/2025","5","Good","B","c","S","D"]])
        mock.fetchDataResults = [sheet]
        let service = SalesService(sheetId: "sheet", apiKey: "key", networkService: mock)
        let sales = try await service.fetchSales()
        XCTAssertEqual(mock.fetchDataInputs.first, "https://sheets.googleapis.com/v4/spreadsheets/sheet/values/Sales?key=key")
        XCTAssertEqual(sales.first?.itemId, "1")
    }
}
