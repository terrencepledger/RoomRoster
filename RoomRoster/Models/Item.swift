//
//  Item.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import Foundation
import SwiftData
import SwiftUICore

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
    var propertyTag: String?
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

extension Item {
    init?(from row: [String]) {
        let paddedRow = row.padded(to: InventoryColumn.expectedCount)

        var id: String = ""
        var imageURL: String = ""
        var name: String = ""
        var description: String = ""
        var dateAdded: String = ""
        var estimatedPrice: Double? = nil
        var status: String = ""
        var lastKnownRoom: String = ""
        var updatedBy: String = ""
        var lastUpdated: Date? = nil
        var propertyTag: String? = nil

        for column in InventoryColumn.allCases {
            let value = paddedRow[column.rawValue]
            switch column {
            case .id:
                id = value
            case .imageURL:
                imageURL = value
            case .name:
                name = value
            case .description:
                description = value
            case .dateAdded:
                dateAdded = value
            case .estimatedPrice:
                estimatedPrice = Double(value)
            case .status:
                status = value
            case .lastKnownRoom:
                lastKnownRoom = value
            case .updatedBy:
                updatedBy = value
            case .lastUpdated:
                lastUpdated = ISO8601DateFormatter().date(from: value)
            case .propertyTag:
                propertyTag = value.isEmpty ? nil : value
            }
        }

        guard !id.isEmpty, !name.isEmpty else {
            return nil
        }

        self.init(id: id,
                  imageURL: imageURL,
                  name: name,
                  description: description,
                  dateAdded: dateAdded,
                  estimatedPrice: estimatedPrice,
                  status: status,
                  lastKnownRoom: lastKnownRoom,
                  updatedBy: updatedBy,
                  lastUpdated: lastUpdated,
                  propertyTag: propertyTag)
    }
}

