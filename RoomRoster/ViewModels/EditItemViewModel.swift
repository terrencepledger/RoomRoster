//
//  EditItemViewModel.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import SwiftUI

@MainActor
class ItemDetailsViewModel: ObservableObject {
    @Published var editableItem: Item
    private let service = InventoryService()

    func refreshItemData() async {
        do {
            historyLogs = try await InventoryService().fetchItem(withId: editableItem.id)
        } catch {
            Logger.log(error, extra: ["description": "Failed to refresh item in edit view"])
        }
    }
}
