import XCTest

final class InventoryUITests: XCTestCase {
    func testInventoryScreenShownOnLaunch() {
        let app = XCUIApplication()
        app.launch()
        let inventoryTab = app.tabBars.buttons["Inventory"]
        XCTAssertTrue(inventoryTab.waitForExistence(timeout: 5))
        XCTAssertTrue(inventoryTab.isSelected)
    }
}

