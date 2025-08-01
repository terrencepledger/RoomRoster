import XCTest
@testable import RoomRoster

final class PropertyTagRangeTests: XCTestCase {
    func testParseSingleTag() {
        let range = PropertyTagRange(from: "A0001")
        XCTAssertEqual(range?.tags, [PropertyTag(rawValue: "A0001")!])
    }

    func testParseRange() {
        let range = PropertyTagRange(from: "A0001-A0003")
        XCTAssertEqual(range?.tags, ["A0001", "A0002", "A0003"].compactMap { PropertyTag(rawValue: $0) })
    }

    func testParseListAndRange() {
        let range = PropertyTagRange(from: "A0001-A0002,B0001")
        let expected = ["A0001", "A0002", "B0001"].compactMap { PropertyTag(rawValue: $0) }
        XCTAssertEqual(range?.tags, expected)
    }

    func testInvalidRangeReturnsNil() {
        XCTAssertNil(PropertyTagRange(from: "A0003-A0001"))
    }
}
