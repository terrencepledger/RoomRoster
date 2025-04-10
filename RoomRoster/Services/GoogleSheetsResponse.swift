//
//  GoogleSheetsResponse.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import Foundation

struct GoogleSheetsResponse: Codable {
    let range: String
    let majorDimension: String
    let values: [[String]]
}

extension GoogleSheetsResponse {
    func toItems() -> [Item] {
        guard values.count > 1 else { return [] } // Ensure there’s data beyond headers
        
        return values.dropFirst().compactMap { row in
            guard row.count >= 10 else { return nil } // Ensure row has enough columns
            
            return Item(
                id: row[0],
                imageURL: row[1],
                name: row[2],
                description: row[3],
                dateAdded: row[4],
                estimatedPrice: Double(row[5]) ?? nil,
                status: row[6],
                lastKnownRoom: row[7],
                updatedBy: row[8],
                lastUpdated: ISO8601DateFormatter().date(from: row[9]),
                propertyTag: row[10]
            )
        }
    }
}

