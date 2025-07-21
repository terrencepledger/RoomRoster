import XCTest
@testable import RoomRoster

final class ViewModelTests: XCTestCase {
    @MainActor
    func testInventoryViewModelLoadRooms() async throws {
        let mock = MockNetworkService()
        let response = GoogleSheetsResponse(range: "Rooms", majorDimension: "ROWS", values: [["R1"],["R2"]])
        mock.authorizedFetchResults = [response]
        let roomService = RoomService(sheetId: "s", networkService: mock)
        let vm = InventoryViewModel(
            inventoryService: InventoryService(sheetId: "s", networkService: MockNetworkService()),
            roomService: roomService
        )
        await vm.loadRooms()
        XCTAssertEqual(vm.rooms.map { $0.name }, ["R1", "R2"])
    }

    @MainActor
    func testCreateItemViewModelValidateTag() {
        let vm = CreateItemViewModel(
            inventoryService: InventoryService(sheetId: "s", networkService: MockNetworkService()),
            roomService: RoomService(sheetId: "s", networkService: MockNetworkService()),
            receiptService: PurchaseReceiptService(directory: FileManager.default.temporaryDirectory),
            itemsProvider: { [Item(id: "1", imageURL: "", name: "", description: "", quantity: 1, dateAdded: "", estimatedPrice: nil, status: .available, lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: PropertyTag(rawValue: "A0001"), purchaseReceiptURL: nil)] }
        )
        vm.propertyTagInput = "A0001"
        vm.validateTag()
        XCTAssertTrue(vm.showTagError)
        XCTAssertEqual(vm.tagError, Strings.createItem.errors.tag.duplicate)
    }
}
