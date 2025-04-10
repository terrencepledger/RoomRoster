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
    
    func getRowNumber(for id: String) async throws -> Int {
        let response = try await fetchInventory()
        
        guard let index = response.values.dropFirst().firstIndex(where: { $0.first == id }) else {
            throw NSError(domain: "InventoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Row not found for id \(id)"])
        }
        
        return index + 2
    }
    
    func updateItem(_ item: Item) async throws {
        let rowNumber = try await getRowNumber(for: item.id)
        let range = "Inventory!A\(rowNumber):K\(rowNumber)"
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(range)?valueInputOption=USER_ENTERED"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let updatedValues: [[Any]] = [[
            item.id,
            item.imageURL,
            item.name,
            item.description,
            item.dateAdded,
            item.estimatedPrice ?? "",
            item.status,
            item.lastKnownRoom,
            item.updatedBy,
            item.lastUpdated?.iso8601String() ?? "",
            item.propertyTag ?? ""
        ]]
        
        let payload: [String: Any] = ["values": updatedValues]
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        guard let accessToken = await AuthenticationManager.shared.accessToken else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not signed in"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        print("Update response: \(String(data: data, encoding: .utf8) ?? "")")
    }
}
