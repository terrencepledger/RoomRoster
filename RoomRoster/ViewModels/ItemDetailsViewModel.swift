//
//  ItemDetailsViewModel.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import SwiftUI

@MainActor
class ItemDetailsViewModel: ObservableObject {
    @Published var historyLogs: [String] = []
    @Published var isLoadingHistory: Bool = false
    @Published var errorMessage: String?

    private let service = InventoryService()

    func fetchItemHistory(for itemId: String) async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        do {
            let logs = try await service.fetchItemHistory(itemId: itemId)
            historyLogs = logs
        } catch {
            Logger.log(error, extra: [
                "description": "Error fetching item history"
            ])
            historyLogs = []
            errorMessage = Strings.itemDetails.failedToLoadHistory
            HapticManager.shared.error()
        }
    }
}
