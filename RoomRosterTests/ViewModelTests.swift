import XCTest
@testable import RoomRoster

final class ViewModelTests: XCTestCase {
    func testInventoryViewModelLoadRooms() async throws {
        let mock = MockNetworkService()
        let response = GoogleSheetsResponse(range: "Rooms", majorDimension: "ROWS", values: [["R1"],["R2"]])
        mock.fetchDataResults = [response]
        let roomService = RoomService(sheetId: "s", apiKey: "k", networkService: mock)
        let vm = InventoryViewModel(inventoryService: InventoryService(sheetId: "s", apiKey: "k", networkService: MockNetworkService()), roomService: roomService)
        await vm.loadRooms()
        XCTAssertEqual(vm.rooms.map { $0.name }, ["R1", "R2"])
    }

    func testCreateItemViewModelValidateTag() {
        let vm = CreateItemViewModel(
            inventoryService: InventoryService(sheetId: "s", apiKey: "k", networkService: MockNetworkService()),
            roomService: RoomService(sheetId: "s", apiKey: "k", networkService: MockNetworkService()),
            itemsProvider: { [Item(id: "1", imageURL: "", name: "", description: "", quantity: 1, dateAdded: "", estimatedPrice: nil, status: .available, lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: PropertyTag(rawValue: "A0001"))] }
        )
        vm.propertyTagInput = "A0001"
        vm.validateTag()
        XCTAssertTrue(vm.showTagError)
        XCTAssertEqual(vm.tagError, Strings.createItem.errors.tag.duplicate)
    }
}
