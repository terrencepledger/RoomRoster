//
//  InventoryColumn.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/12/25.
//

enum InventoryColumn: Int, CaseIterable {
    case id            // Item ID
    case imageURL      // Image URL
    case name          // Name
    case description   // Description
    case dateAdded     // Date Added
    case estimatedPrice// Estimated Price
    case status        // Status
    case lastKnownRoom // Last Known Room
    case updatedBy     // Updated By
    case lastUpdated   // Last Updated
    case propertyTag   // Property Tag

    static var expectedCount: Int {
        return Self.allCases.count
    }
}
