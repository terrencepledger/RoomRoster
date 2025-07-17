//
//  RoomRosterTests.swift
//  RoomRosterTests
//
//  Created by Terrence Pledger on 1/30/25.
//

import XCTest
@testable import RoomRoster

final class RoomRosterTests: XCTestCase {
    func testAppConfigLoads() {
        let config = AppConfig.shared
        XCTAssertNotNil(config.sentryDSN)
    }

}
