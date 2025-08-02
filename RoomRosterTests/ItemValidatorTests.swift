import XCTest
@testable import RoomRoster

final class ItemValidatorTests: XCTestCase {
    func testValidateNameThrowsForEmpty() {
        XCTAssertThrowsError(try ItemValidator.validateName(" ")) { error in
            XCTAssertEqual(error as? ItemValidationError, .emptyName)
        }
    }

    func testValidateTagDuplicateThrows() {
        let item = Item(
            id: "1",
            imageURL: "",
            name: "A",
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
        XCTAssertThrowsError(try ItemValidator.validateTags("A0001", quantity: 1, currentItemID: nil, allItems: [item])) { error in
            XCTAssertEqual(error as? ItemValidationError, .duplicateTag)
        }
    }

    func testValidateTagSuccess() throws {
        let tags = try ItemValidator.validateTags("A0001", quantity: 1, currentItemID: nil, allItems: [])
        XCTAssertEqual(tags, [PropertyTag(rawValue: "A0001")!])
    }

    func testValidateRangeQuantityMismatch() {
        XCTAssertThrowsError(
            try ItemValidator.validateTags("A0001-A0002", quantity: 1, currentItemID: nil, allItems: [])
        ) { error in
            XCTAssertEqual(error as? ItemValidationError, .quantityMismatch)
        }
    }

    func testValidateRangeSuccess() throws {
        let tags = try ItemValidator.validateTags("A0001-A0002", quantity: 2, currentItemID: nil, allItems: [])
        XCTAssertEqual(tags.map(\.rawValue), ["A0001", "A0002"])
    }
}
