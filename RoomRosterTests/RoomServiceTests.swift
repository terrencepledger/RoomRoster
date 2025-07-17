import XCTest
@testable import RoomRoster

final class RoomServiceTests: XCTestCase {
    func testFetchRoomsParsesNames() async throws {
        let mock = MockNetworkService()
        let response = GoogleSheetsResponse(range: "Rooms", majorDimension: "ROWS", values: [["Room A"],["Room B"]])
        mock.authorizedFetchResults = [response]
        let service = RoomService(sheetId: "sheet", networkService: mock)
        let rooms = try await service.fetchRooms()
        XCTAssertEqual(mock.authorizedFetchInputs.first?.absoluteString, "https://sheets.googleapis.com/v4/spreadsheets/sheet/values/Rooms!A:A")
        XCTAssertEqual(rooms.map { $0.name }, ["Room A", "Room B"])
    }

    func testAddRoomWithEmptyNameThrows() async throws {
        let service = RoomService(sheetId: "s", networkService: MockNetworkService())
        do {
            _ = try await service.addRoom(name: "   ")
            XCTFail("Expected invalidName error")
        } catch {
            XCTAssertEqual(error as? RoomServiceError, .invalidName)
        }
    }

    func testAddRoomWithInvalidURLThrows() async throws {
        // Provide an invalid sheet ID to produce an invalid URL
        let service = RoomService(sheetId: "invalid sheet id", networkService: MockNetworkService())
        do {
            _ = try await service.addRoom(name: "Room")
            XCTFail("Expected invalidURL error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .invalidURL)
        }
    }
}
