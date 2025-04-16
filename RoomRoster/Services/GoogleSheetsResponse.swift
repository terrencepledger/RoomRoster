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
        guard values.count > 1 else { return [] }
        return values.dropFirst().compactMap { row in
            return Item(from: row)
        }
    }
}

