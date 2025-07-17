//  HistoryLogService.swift
//  RoomRoster

import Foundation

enum HistoryAction: CustomStringConvertible {
    case created(by: String, date: Date)
    case edited(field: String, oldValue: String, newValue: String, by: String, date: Date)
    case deleted(by: String, date: Date)
    case sold(price: Double?, buyer: String, by: String, date: Date)

    var description: String {
        switch self {
        case .created(let by, let date):
            return "Created by \(by) on \(date.toShortString())"

        case .edited(let field, let oldValue, let newValue, let by, let date):
            return "Edited '\(field)' from '\(oldValue)' to '\(newValue)' by \(by) on \(date.toShortString())"

        case .deleted(let by, let date):
            return "Deleted by \(by) on \(date.toShortString())"

        case .sold(let price, let buyer, let by, let date):
            let priceString = price.map { "\($0)" } ?? "0"
            return "Sold to \(buyer) for \(priceString) by \(by) on \(date.toShortString())"
        }
    }
}

enum HistoryLogError: Error, LocalizedError {
    case missingUserContext

    var errorDescription: String? {
        switch self {
        case .missingUserContext:
            return "No user context provided for logging the creation event."
        }
    }
}

final class HistoryLogService {
    static let shared = HistoryLogService()
    private var sheetId: String { SpreadsheetManager.shared.currentSheet?.id ?? "" }

    func logChanges(old: Item, new: Item, updatedBy: String?) async {
        let user = updatedBy ?? "Unknown"
        if updatedBy == nil {
            Logger.log(HistoryLogError.missingUserContext)
        }

        let actions = detectItemChanges(old: old, new: new, updatedBy: user)
        for action in actions {
            await appendHistoryLog(for: old.id, action: action)
        }
    }

    func logCreation(for item: Item, createdBy: String?) async {
        let user = createdBy ?? "Unknown"
        if createdBy == nil {
            Logger.log(HistoryLogError.missingUserContext)
        }

        let action = HistoryAction.created(by: user, date: Date())
        await appendHistoryLog(for: item.id, action: action)
    }

    func logSale(_ sale: Sale) async {
        let action = HistoryAction.sold(
            price: sale.price,
            buyer: sale.buyerName,
            by: sale.soldBy,
            date: sale.date
        )
        await appendHistoryLog(for: sale.itemId, action: action)
    }

    private func appendHistoryLog(for itemId: String, action: HistoryAction) async {
        let message = action.description
        do {
            try await appendHistoryEntries(for: itemId, logEntries: [message])
        } catch {
            Logger.log(error, extra: [
                "description": "Failed to append history log",
                "itemId": itemId,
                "log": message
            ])
        }
    }

    private func appendHistoryEntries(for itemId: String, logEntries: [String]) async throws {
        let historyURLString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/HistoryLog"
        Logger.network("HistoryLogService-appendHistoryEntries")
        guard let historyURL = URL(string: historyURLString) else { throw NetworkError.invalidURL }
        let historyResponse: GoogleSheetsResponse = try await NetworkService.shared.fetchAuthorizedData(from: historyURL)

        if let existingRowIndex = historyResponse.values.firstIndex(where: { $0.first == itemId }) {
            let existingRow = historyResponse.values[existingRowIndex]
            let nextColIndex = existingRow.count + 1
            let startColLetter = SheetsUtils.columnName(for: nextColIndex)
            let endColLetter = SheetsUtils.columnName(for: nextColIndex + logEntries.count - 1)
            let spreadsheetRow = existingRowIndex + 1
            let updateRange = "HistoryLog!\(startColLetter)\(spreadsheetRow):\(endColLetter)\(spreadsheetRow)"

            let updateURLString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(updateRange)?valueInputOption=USER_ENTERED"
            guard let updateURL = URL(string: updateURLString) else { throw NetworkError.invalidURL }

            let request = try await NetworkService.shared.authorizedRequest(
                url: updateURL,
                method: "PUT",
                jsonBody: ["values": [logEntries]]
            )
            try await NetworkService.shared.sendRequest(request)
        } else {
            let appendURLString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/HistoryLog:append?valueInputOption=USER_ENTERED"
            guard let appendURL = URL(string: appendURLString) else { throw NetworkError.invalidURL }

            let request = try await NetworkService.shared.authorizedRequest(
                url: appendURL,
                method: "POST",
                jsonBody: ["values": [[itemId] + logEntries]]
            )
            try await NetworkService.shared.sendRequest(request)
        }
    }

    private func detectItemChanges(old: Item, new: Item, updatedBy: String) -> [HistoryAction] {
        ItemField.allCases.compactMap { field in
            Item.schema[field]?.diff(old: old, new: new, by: updatedBy, at: .now)
        }
    }
}
