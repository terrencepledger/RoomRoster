//
//  InventoryService.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation

struct InventoryService {
    private let sheetId = AppConfig.shared.sheetId
    private let apiKey = AppConfig.shared.apiKey
    
    func fetchInventory() async throws -> GoogleSheetsResponse {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Inventory?key=\(apiKey)"
        return try await NetworkService.shared.fetchData(from: urlString)
    }
    
    func fetchItemHistory(itemId: String) async throws -> [String] {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/HistoryLog?key=\(apiKey)"
        let response: GoogleSheetsResponse = try await NetworkService.shared.fetchData(from: urlString)
        if let row = response.values.first(where: { $0.first == itemId }) {
            return Array(row.dropFirst()) // Ignore the Item ID
        }
        return []
    }
}
