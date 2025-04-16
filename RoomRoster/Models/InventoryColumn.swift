//
//  InventoryColumn.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/12/25.
//

enum InventoryColumn: Int, CaseIterable {
    case id            // A
    case imageURL      // B
    case name          // C
    case description   // D
    case quantity      // E
    case dateAdded     // F
    case estimatedPrice// G
    case status        // H
    case lastKnownRoom // I
    case updatedBy     // J
    case lastUpdated   // K
    case propertyTag   // L

    static var expectedCount: Int { allCases.count }
}
