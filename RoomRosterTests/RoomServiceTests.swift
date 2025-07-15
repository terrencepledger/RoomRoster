import XCTest
@testable import RoomRoster

final class RoomServiceTests: XCTestCase {
    func testFetchRoomsParsesNames() async throws {
        let mock = MockNetworkService()
        let response = GoogleSheetsResponse(range: "Rooms", majorDimension: "ROWS", values: [["Room A"],["Room B"]])
        mock.fetchDataResults = [response]
        let service = RoomService(sheetId: "sheet", apiKey: "key", networkService: mock)
        let rooms = try await service.fetchRooms()
        XCTAssertEqual(mock.fetchDataInputs.first, "https://sheets.googleapis.com/v4/spreadsheets/sheet/values/Rooms!A:A?key=key")
        XCTAssertEqual(rooms.map { $0.name }, ["Room A", "Room B"])
    }

    func testAddRoomWithEmptyNameThrows() async throws {
        let service = RoomService(sheetId: "s", apiKey: "k", networkService: MockNetworkService())
        await XCTAssertThrowsError(try await service.addRoom(name: "   ")) { error in
            XCTAssertEqual(error as? RoomServiceError, .invalidName)
        }
    }
}
