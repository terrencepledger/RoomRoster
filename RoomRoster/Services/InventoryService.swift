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
            return Array(row.dropFirst())
        }
        return []
    }
    
    func createItem(_ item: Item) async throws {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Inventory:append?valueInputOption=USER_ENTERED"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let request = try await NetworkService.shared.authorizedRequest(
            url: url,
            method: "POST",
            jsonBody: ["values": [item.toRow()]]
        )
        try await NetworkService.shared.sendRequest(request)
    }
    
    func getRowNumber(for id: String) async throws -> Int {
        let response = try await fetchInventory()
        
        guard let index = response.values.dropFirst().firstIndex(where: { $0.first == id }) else {
            throw NSError(domain: "InventoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Row not found for id \(id)"])
        }
        
        return index + 1
    }
    
    func updateItem(_ item: Item) async throws {
        let rowNumber = try await getRowNumber(for: item.id)
        let range = "Inventory!A\(rowNumber):L\(rowNumber)"
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(range)?valueInputOption=USER_ENTERED"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let request = try await NetworkService.shared.authorizedRequest(
            url: url,
            method: "PUT",
            jsonBody: ["values": [item.toRow()]]
        )
        try await NetworkService.shared.sendRequest(request)
    }
}
