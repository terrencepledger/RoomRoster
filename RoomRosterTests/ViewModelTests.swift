import XCTest
import Foundation
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
            receiptService: PurchaseReceiptService(),
            itemsProvider: {
                [
                    Item(
                        id: "1",
                        imageURL: "",
                        name: "",
                        description: "",
                        groupID: "test-group",
                        quantity: 1,
                        dateAdded: "",
                        estimatedPrice: nil,
                        status: .available,
                        lastKnownRoom: .empty(),
                        updatedBy: "",
                        lastUpdated: nil,
                        propertyTag: PropertyTag(rawValue: "A0001"),
                        purchaseReceiptURL: nil
                    )
                ]
            }
        )
        vm.propertyTagInput = "A0001"
        vm.validateTag()
        XCTAssertTrue(vm.showTagError)
        XCTAssertEqual(vm.tagError, Strings.createItem.errors.tag.duplicate)
    }

    @MainActor
    func testCreateItemViewModelQuantityMismatch() {
        let vm = CreateItemViewModel(
            inventoryService: InventoryService(sheetId: "s", networkService: MockNetworkService()),
            roomService: RoomService(sheetId: "s", networkService: MockNetworkService()),
            receiptService: PurchaseReceiptService(),
            itemsProvider: { [] }
        )
        vm.propertyTagInput = "A0001"
        vm.validateTag()
        XCTAssertNil(vm.tagError)
        vm.newItem.quantity = 2
        vm.validateTag()
        XCTAssertTrue(vm.showTagError)
        XCTAssertEqual(vm.tagError, Strings.createItem.errors.tag.quantityMismatch)
    }

    @MainActor
    func testCreateItemViewModelPreventsDuplicateSaves() async {
        final class SlowMockNetworkService: MockNetworkService {
            override func sendRequest(_ request: URLRequest) async throws {
                try await Task.sleep(nanoseconds: 50_000_000)
                try await super.sendRequest(request)
            }
        }
        let mockNetwork = SlowMockNetworkService()
        let inventoryService = InventoryService(sheetId: "s", networkService: mockNetwork)
        let vm = CreateItemViewModel(
            inventoryService: inventoryService,
            roomService: RoomService(sheetId: "s", networkService: MockNetworkService()),
            receiptService: PurchaseReceiptService(),
            itemsProvider: { [] }
        )
        vm.newItem.name = "Test"
        vm.newItem.description = "Desc"
        vm.newItem.lastKnownRoom = Room(name: "Room1")

        async let first = vm.saveItem()
        async let second = vm.saveItem()
        _ = await (first, second)

        XCTAssertEqual(mockNetwork.sentRequests.count, 1)
    }
}
