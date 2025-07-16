import XCTest
@testable import RoomRoster

final class SheetsUtilsTests: XCTestCase {
    func testColumnName() {
        XCTAssertEqual(SheetsUtils.columnName(for: 1), "A")
        XCTAssertEqual(SheetsUtils.columnName(for: 26), "Z")
        XCTAssertEqual(SheetsUtils.columnName(for: 27), "AA")
        XCTAssertEqual(SheetsUtils.columnName(for: 52), "AZ")
    }

    func testRowIndex() {
        let rows = [["id1", "row1"], ["id2", "row2"], ["id3", "row3"]]
        XCTAssertEqual(SheetsUtils.rowIndex(for: "id1", in: rows), 0)
        XCTAssertEqual(SheetsUtils.rowIndex(for: "id3", in: rows), 2)
        XCTAssertNil(SheetsUtils.rowIndex(for: "id4", in: rows))
    }
}
