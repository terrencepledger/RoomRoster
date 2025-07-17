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
    private let sheetIdProvider: @MainActor () -> String?
    private let networkService: NetworkServiceProtocol

    init(
        sheetIdProvider: @escaping @MainActor () -> String? = { SpreadsheetManager.shared.currentSheet?.id },
        networkService: NetworkServiceProtocol = NetworkService.shared
    ) {
        self.sheetIdProvider = sheetIdProvider
        self.networkService = networkService
    }

    init(
        sheetId: String,
        networkService: NetworkServiceProtocol = NetworkService.shared
    ) {
        self.sheetIdProvider = { sheetId }
        self.networkService = networkService
    }

    func fetchRooms() async throws -> [Room] {
        Logger.network("RoomService-fetchRooms")
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        guard let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Rooms!A:A") else { throw NetworkError.invalidURL }
        let response: GoogleSheetsResponse = try await networkService.fetchAuthorizedData(from: url)
        return response.values.compactMap { $0.first }.filter { !$0.isEmpty }.map { Room(name: $0) }
    }

    func addRoom(name: String) async throws -> Room {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RoomServiceError.invalidName }

        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        guard sheetId.rangeOfCharacter(from: CharacterSet.urlPathAllowed.inverted) == nil else {
            throw NetworkError.invalidURL
        }
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Rooms:append?valueInputOption=USER_ENTERED"
        let payload: [String: Any] = ["values": [[trimmed]]]
        Logger.network("RoomService-addRoom")
        guard let url = URL(string: urlString) else {
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
