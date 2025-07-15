//
//  RoomRosterTests.swift
//  RoomRosterTests
//
//  Created by Terrence Pledger on 1/30/25.
//

import XCTest
@testable import RoomRoster

final class RoomRosterTests: XCTestCase {
    func testAppConfigDefaults() {
        let config = AppConfig.shared
        XCTAssertFalse(config.apiKey.isEmpty, "API key should be set in AppConfig")
        XCTAssertFalse(config.sheetId.isEmpty, "Sheet ID should be set to enable Sheet operations")
    }

    /// Runs all unit test suites in this target.
    func runAllUnitTests() {
        let suites: [XCTestSuite] = [
            RoomRosterTests.defaultTestSuite,
            InventoryServiceTests.defaultTestSuite,
            ItemValidatorTests.defaultTestSuite,
            RoomServiceTests.defaultTestSuite,
            ViewModelTests.defaultTestSuite
        ]
        for suite in suites {
            suite.run()
        }
    }
}
