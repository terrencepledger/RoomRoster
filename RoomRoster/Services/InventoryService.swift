//
//  InventoryService.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation

actor InventoryService {
    private let sheetIdProvider: @MainActor () -> String?
    private var cachedHistory: GoogleSheetsResponse?
    private let networkService: NetworkServiceProtocol
    private let cache: InventoryCache
    init(
        sheetIdProvider: @escaping @MainActor () -> String? = { SpreadsheetManager.shared.currentSheet?.id },
        networkService: NetworkServiceProtocol = NetworkService.shared,
        cache: InventoryCache = .shared
    ) {
        self.sheetIdProvider = sheetIdProvider
        self.networkService = networkService
        self.cache = cache
    }

    init(
        sheetId: String,
        networkService: NetworkServiceProtocol = NetworkService.shared,
        cache: InventoryCache = .shared
    ) {
        self.sheetIdProvider = { sheetId }
        self.networkService = networkService
        self.cache = cache
    }

    func fetchInventory() async throws -> GoogleSheetsResponse {
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Inventory"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        Logger.network("InventoryService-fetchInventory")
        let sheet: GoogleSheetsResponse = try await networkService.fetchAuthorizedData(from: url)
        let items = sheet.values.dropFirst().compactMap { Item(from: $0) }
        await cache.save(items: items)
        return sheet
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

    func fetchCachedItems() async -> [Item] {
        await cache.fetchItems()
    }

    func fetchAllHistory() async throws -> GoogleSheetsResponse {
        if let sheet = cachedHistory { return sheet }
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/HistoryLog!A:Z"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        Logger.network("InventoryService-fetchHistory")
        let sheet: GoogleSheetsResponse = try await networkService.fetchAuthorizedData(from: url)
        cachedHistory = sheet
        return sheet
    }

    func fetchItemHistory(itemId: String) async throws -> [String] {
        let sheet = try await fetchAllHistory()
        guard let row = sheet.values.first(where: { $0.first == itemId }) else { return [] }
        return Array(row.dropFirst())
    }

    func createItem(_ item: Item) async throws {
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
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
        await cache.upsert(item)
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
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
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
        await cache.upsert(item)
    }
}
