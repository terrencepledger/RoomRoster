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
    
    func appendHistoryLog(for item: Item, action: String) async throws {
        let historyURLString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/HistoryLog?key=\(apiKey)"
        let historyResponse: GoogleSheetsResponse = try await NetworkService.shared.fetchData(from: historyURLString)
        
        var existingRowIndex: Int? = nil
        for (i, row) in historyResponse.values.enumerated() {
            if row.first == item.id {
                existingRowIndex = i
                break
            }
        }
        
        let timestamp = Date().toShortString()
        let updatedBy = await AuthenticationManager.shared.userName ?? "Unknown User"
        let logEntry = "\(action) | \(timestamp) | \(updatedBy)"
        
        if let rowIndex = existingRowIndex {
            let existingRow = historyResponse.values[rowIndex]
            let nextColIndex = existingRow.count + 1
            
            let unicodeA = Int(("A" as UnicodeScalar).value)
            guard let uniCodeScalar = UnicodeScalar(unicodeA + nextColIndex - 1) else {
                throw NSError(domain: "InventoryService", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve unicode scalar"])
            }
            let colLetter = String(uniCodeScalar)
            
            let spreadsheetRow = rowIndex + 1
            let updateRange = "HistoryLog!\(colLetter)\(spreadsheetRow)"
            
            let updateURLString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(updateRange)?valueInputOption=USER_ENTERED"
            guard let updateURL = URL(string: updateURLString) else {
                throw NetworkError.invalidURL
            }
            
            let payload: [String: Any] = ["values": [[logEntry]]]
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            
            guard let accessToken = await AuthenticationManager.shared.accessToken else {
                throw NSError(domain: "Auth", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "User is not signed in"])
            }
            
            var updateRequest = URLRequest(url: updateURL)
            updateRequest.httpMethod = "PUT"
            updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            updateRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            updateRequest.httpBody = jsonData
            
            _ = try await URLSession.shared.data(for: updateRequest)
        } else {
            let appendURLString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/HistoryLog:append?valueInputOption=USER_ENTERED"
            guard let appendURL = URL(string: appendURLString) else {
                throw NetworkError.invalidURL
            }
            
            let payload: [String: Any] = ["values": [[item.id, logEntry]]]
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            
            guard let accessToken = await AuthenticationManager.shared.accessToken else {
                throw NSError(domain: "Auth", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "User is not signed in"])
            }
            
            var appendRequest = URLRequest(url: appendURL)
            appendRequest.httpMethod = "POST"
            appendRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            appendRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            appendRequest.httpBody = jsonData
            
            _ = try await URLSession.shared.data(for: appendRequest)
        }
    }
    
    func createItem(_ item: Item) async throws {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Inventory:append?valueInputOption=USER_ENTERED"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let currentDate = Date()
        let createdBy = await AuthenticationManager.shared.userName ?? "Unknown User"
        
        let rowValues: [[Any]] = [[
            item.id,
            item.imageURL,
            item.name,
            item.description,
            item.quantity,
            item.dateAdded,
            item.estimatedPrice ?? "",
            item.status,
            item.lastKnownRoom,
            createdBy,
            currentDate.toShortString(),
            item.propertyTag ?? ""
        ]]
        
        let payload: [String: Any] = ["values": rowValues]
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        guard let accessToken = await AuthenticationManager.shared.accessToken else {
            throw NSError(domain: "Auth", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "User is not signed in"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        _ = try await URLSession.shared.data(for: request)
        try await appendHistoryLog(for: item, action: "Created")
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
        
        let updatedDate = Date().toShortString()
        let updatedBy = await AuthenticationManager.shared.userName ?? "Unknown User"
        
        let updatedValues: [[Any]] = [[
            item.id,
            item.imageURL,
            item.name,
            item.description,
            item.quantity,
            item.dateAdded,
            item.estimatedPrice ?? "",
            item.status,
            item.lastKnownRoom,
            updatedBy,
            updatedDate,
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
        
        _ = try await URLSession.shared.data(for: request)
        try await appendHistoryLog(for: item, action: "Updated")
    }
}
