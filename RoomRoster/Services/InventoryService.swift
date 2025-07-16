//
//  InventoryService.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation

actor InventoryService {
    private let manager: InventoryManager
    private var cachedHistory: GoogleSheetsResponse?
    private let networkService: NetworkServiceProtocol
    init(
        manager: InventoryManager = .shared,
        networkService: NetworkServiceProtocol = NetworkService.shared
    ) {
        self.manager = manager
        self.networkService = networkService
    }

    func fetchInventory() async throws -> GoogleSheetsResponse {
        let sheetId = await manager.sheetId
        let apiKey = await manager.apiKey
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Inventory?key=\(apiKey)"
        Logger.network("InventoryService-fetchInventory")
        return try await networkService.fetchData(from: urlString)
    }

    /// Convenience method to fetch a single item from the inventory sheet.
    /// - Parameter id: The unique identifier of the item.
    /// - Returns: The matching ``Item`` if found, otherwise `nil`.
    func fetchItem(withId id: String) async throws -> Item? {
        let response = try await fetchInventory()
        guard let row = response.values.dropFirst().first(where: { $0.first == id }) else {
            return nil
        }
        return Item(from: row)
    }

    func fetchAllHistory() async throws -> GoogleSheetsResponse {
        if let sheet = cachedHistory { return sheet }
        let sheetId = await manager.sheetId
        let apiKey = await manager.apiKey
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/HistoryLog!A:Z?key=\(apiKey)"
        Logger.network("InventoryService-fetchHistory")
        let sheet: GoogleSheetsResponse = try await networkService.fetchData(from: urlString)
        cachedHistory = sheet
        return sheet
    }

    func fetchItemHistory(itemId: String) async throws -> [String] {
        let sheet = try await fetchAllHistory()
        guard let row = sheet.values.first(where: { $0.first == itemId }) else { return [] }
        return Array(row.dropFirst())
    }

    func createItem(_ item: Item) async throws {
        let sheetId = await manager.sheetId
        let apiKey = await manager.apiKey
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Inventory:append?valueInputOption=USER_ENTERED"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let request = try await networkService.authorizedRequest(
            url: url,
            method: "POST",
            jsonBody: ["values": [item.toRow()]]
        )
        Logger.network("InventoryService-createItem")
        try await networkService.sendRequest(request)
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
        let sheetId = await manager.sheetId
        let apiKey = await manager.apiKey
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(range)?valueInputOption=USER_ENTERED"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let request = try await networkService.authorizedRequest(
            url: url,
            method: "PUT",
            jsonBody: ["values": [item.toRow()]]
        )
        Logger.network("InventoryService-updateItem")
        try await networkService.sendRequest(request)
    }
}
