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
    private let sheetId: String
    private let apiKey: String
    private let networkService: NetworkServiceProtocol

    init(
        sheetId: String = AppConfig.shared.sheetId,
        apiKey: String = AppConfig.shared.apiKey,
        networkService: NetworkServiceProtocol = NetworkService.shared
    ) {
        self.sheetId = sheetId
        self.apiKey = apiKey
        self.networkService = networkService
    }

    func fetchRooms() async throws -> [Room] {
        Logger.network("RoomService-fetchRooms")
        let response: GoogleSheetsResponse = try await networkService.fetchData(
            from: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Rooms!A:A?key=\(apiKey)"
        )
        return response.values.compactMap { $0.first }.filter { !$0.isEmpty }.map { Room(name: $0) }
    }

    func addRoom(name: String) async throws -> Room {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RoomServiceError.invalidName }

        let url = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Rooms:append?valueInputOption=USER_ENTERED"
        let payload: [String: Any] = ["values": [[trimmed]]]
        Logger.network("RoomService-addRoom")
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        let request = try await networkService.authorizedRequest(
            url: url,
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
