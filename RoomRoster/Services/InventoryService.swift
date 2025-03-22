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
    
    func updateItem(_ item: Item) async throws {
        guard let rowNumber = Int(item.id) else {
            throw NSError(domain: "InvalidItemID", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item ID must be numeric for row mapping."])
        }
        
        // Construct the range – adjust as necessary for your sheet's layout.
        let range = "Inventory!A\(rowNumber):J\(rowNumber)"
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(range)?valueInputOption=USER_ENTERED&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        // Build the updated row values.
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
            item.lastUpdated?.iso8601String() ?? ""
        ]]
        
        let payload: [String: Any] = ["values": updatedValues]
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        // Create the URLRequest with method PUT.
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Execute the request.
        let (data, _) = try await URLSession.shared.data(for: request)
        print("Update response: \(String(data: data, encoding: .utf8) ?? "")")
    }
}
