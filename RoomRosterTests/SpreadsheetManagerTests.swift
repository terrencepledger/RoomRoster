import XCTest
@testable import RoomRoster

final class SpreadsheetManagerTests: XCTestCase {
    @MainActor
    override func tearDown() {
        SpreadsheetManager.shared.signOut()
        UserDefaults.standard.removeObject(forKey: "SelectedSheetID")
        UserDefaults.standard.removeObject(forKey: "SelectedSheetName")
    }

    @MainActor
    func testSelectPersistsSheet() {
        let sheet = Spreadsheet(id: "123", name: "Test Sheet")
        SpreadsheetManager.shared.select(sheet)
        XCTAssertEqual(SpreadsheetManager.shared.currentSheet?.id, "123")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "SelectedSheetID"), "123")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "SelectedSheetName"), "Test Sheet")
    }
}
