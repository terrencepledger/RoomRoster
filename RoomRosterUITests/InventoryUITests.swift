import XCTest

final class InventoryUITests: XCTestCase {
    func testInventoryScreenShownOnLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Inventory"].waitForExistence(timeout: 5))
    }
}

