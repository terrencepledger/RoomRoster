//
//  RoomService.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/24/25.
//

import Foundation

struct RoomService {
    private let sheetId = AppConfig.shared.sheetId
    private let apiKey = AppConfig.shared.apiKey

    func fetchRooms() async throws -> [Room] {
        Logger.network("RoomService-fetchRooms")
        let response: GoogleSheetsResponse = try await NetworkService.shared.fetchData(
            from: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Rooms!A:A?key=\(apiKey)"
        )
        return response.values.compactMap { $0.first }.filter { !$0.isEmpty }.map { Room(name: $0) }
    }

    func addRoom(name: String) async throws {
        let url = "https://sheets.googleapi.com/v4/spreadsheets/\(sheetId)/values/Rooms:append?valueInputOption=USER_ENTERED"
        let payload: [String: Any] = ["values": [[name]]]
        Logger.network("RoomService-addRoom")
        let request = try await NetworkService.shared.authorizedRequest(
            url: URL(string: url)!,
            method: "POST",
            jsonBody: payload
        )

        try await NetworkService.shared.sendRequest(request)
    }
}
