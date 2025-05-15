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
    private let service = InventoryService()
    
    func fetchItemHistory(for itemId: String) async {
        do {
            self.historyLogs = try await service.fetchItemHistory(itemId: itemId)
        } catch {
            // TODO: Handle error appropriately
            Logger.log(error, extra: [
                "description": "Error fetching item history"
            ])
        }
    }
}
