//
//  SpreadsheetManager.swift
//  RoomRoster
//
//  Created by Codex Bot on 4/28/24.
//

import Foundation
import SwiftUI

@MainActor
final class SpreadsheetManager: ObservableObject {
    static let shared = SpreadsheetManager()

    @Published private(set) var spreadsheets: [Spreadsheet] = []
    @Published var currentSheet: Spreadsheet?
    @Published private(set) var isLoading: Bool = false

    private let networkService: NetworkServiceProtocol
    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
        if let id = UserDefaults.standard.string(forKey: "SelectedSheetID"),
           let name = UserDefaults.standard.string(forKey: "SelectedSheetName") {
            self.currentSheet = Spreadsheet(id: id, name: name)
        }
    }

    func loadSheets() async {
        guard AuthenticationManager.shared.isSignedIn else { return }
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let driveURL = URL(string: "https://www.googleapis.com/drive/v3/files?q=mimeType='application/vnd.google-apps.spreadsheet'&fields=files(id,name)")!
            let list: DriveFilesResponse = try await networkService.fetchAuthorizedData(from: driveURL)
            var valid: [Spreadsheet] = []
            for file in list.files {
                if try await isValidSpreadsheet(file.id) {
                    valid.append(Spreadsheet(id: file.id, name: file.name))
                }
            }
            spreadsheets = valid
        } catch {
            Logger.log(error, extra: ["description": "Failed to load sheets"])
        }
    }

    private func isValidSpreadsheet(_ id: String) async throws -> Bool {
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(id)?fields=sheets.properties.title")!
        let meta: SheetsMetadata = try await networkService.fetchAuthorizedData(from: url)
        let titles = meta.sheets.map { $0.properties.title }
        let required: Set<String> = ["Inventory", "HistoryLog", "Rooms", "Sales"]
        return required.isSubset(of: Set(titles))
    }

    func select(_ sheet: Spreadsheet) {
        currentSheet = sheet
        UserDefaults.standard.set(sheet.id, forKey: "SelectedSheetID")
        UserDefaults.standard.set(sheet.name, forKey: "SelectedSheetName")
    }

    func signOut() {
        currentSheet = nil
        spreadsheets = []
        UserDefaults.standard.removeObject(forKey: "SelectedSheetID")
        UserDefaults.standard.removeObject(forKey: "SelectedSheetName")
    }
}

private struct DriveFilesResponse: Codable {
    struct File: Codable { let id: String; let name: String }
    let files: [File]
}

private struct SheetsMetadata: Codable {
    struct Sheet: Codable {
        struct Properties: Codable { let title: String }
        let properties: Properties
    }
    let sheets: [Sheet]
}
