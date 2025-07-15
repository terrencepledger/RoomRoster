import XCTest
@testable import RoomRoster

final class ItemValidatorTests: XCTestCase {
    func testValidateNameThrowsForEmpty() {
        XCTAssertThrowsError(try ItemValidator.validateName(" ")) { error in
            XCTAssertEqual(error as? ItemValidationError, .emptyName)
        }
    }

    func testValidateTagDuplicateThrows() {
        let item = Item(id: "1", imageURL: "", name: "A", description: "", quantity: 1, dateAdded: "", estimatedPrice: nil, status: .available, lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: PropertyTag(rawValue: "A0001"))
        XCTAssertThrowsError(try ItemValidator.validateTag("A0001", currentItemID: nil, allItems: [item])) { error in
            XCTAssertEqual(error as? ItemValidationError, .duplicateTag)
        }
    }

    func testValidateTagSuccess() throws {
        let tag = try ItemValidator.validateTag("A0001", currentItemID: nil, allItems: [])
        XCTAssertEqual(tag.rawValue, "A0001")
    }
}
