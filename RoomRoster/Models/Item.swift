//
//  Item.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import Foundation
import SwiftData
import SwiftUICore

// Sample Item Model Update
struct Item: Identifiable {
    var id: String
    var imageURL: String
    var name: String
    var description: String
    var dateAdded: String
    var estimatedPrice: Double?
    var status: String
    var lastKnownRoom: String
    var updatedBy: String
    var lastUpdated: Date?
}

extension Item {
    var statusColor: Color {
        switch status {
        case "Available": return .green
        case "Checked Out": return .orange
        case "Discarded": return .red
        case "Sold": return .blue
        default: return .gray
        }
    }
}
