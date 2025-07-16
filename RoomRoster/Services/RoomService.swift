//
//  RoomService.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/24/25.
//

import Foundation

enum RoomServiceError: Error {
    case invalidName
    case notFound
}

struct RoomService {
    private let manager: InventoryManager
    private let networkService: NetworkServiceProtocol

    init(
        manager: InventoryManager = .shared,
        networkService: NetworkServiceProtocol = NetworkService.shared
    ) {
        self.manager = manager
        self.networkService = networkService
    }

    func fetchRooms() async throws -> [Room] {
        let sheetId = await manager.sheetId
        let apiKey = await manager.apiKey
        Logger.network("RoomService-fetchRooms")
        let response: GoogleSheetsResponse = try await networkService.fetchData(
            from: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Rooms!A:A?key=\(apiKey)"
        )
        return response.values.compactMap { $0.first }.filter { !$0.isEmpty }.map { Room(name: $0) }
    }

    func addRoom(name: String) async throws -> Room {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RoomServiceError.invalidName }

        let sheetId = await manager.sheetId
        let apiKey = await manager.apiKey
        let url = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Rooms:append?valueInputOption=USER_ENTERED"
        let payload: [String: Any] = ["values": [[trimmed]]]
        Logger.network("RoomService-addRoom")
        let request = try await networkService.authorizedRequest(
            url: URL(string: url)!,
            method: "POST",
            jsonBody: payload
        )
        try await networkService.sendRequest(request)

        let rooms = try await fetchRooms()
        guard let newRoom = rooms.last(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            throw RoomServiceError.notFound
        }
        return newRoom
    }
}
