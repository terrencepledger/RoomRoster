//
//  EditItemViewModel.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import SwiftUI

@MainActor
final class EditItemViewModel: ObservableObject {
    @Published var editableItem: Item
    @Published var isSaving: Bool = false

    private let inventoryService: InventoryService
    private let historyService: HistoryLogService

    init(
        item: Item,
        inventoryService: InventoryService = .init(),
        historyService: HistoryLogService = .init()
    ) {
        self.editableItem = item
        self.inventoryService = inventoryService
        self.historyService = historyService
    }

    func loadItemData() async {
        do {
            if let item = try await inventoryService.fetchItem(withId: editableItem.id) {
                editableItem = item
            }
        } catch {
            Logger.log(error, extra: ["description": "Failed to refresh item in edit view"])
        }
    }

    func saveUpdates(updatedBy: String?) async throws {
        isSaving = true
        defer { isSaving = false }

        let previous = editableItem
        try await inventoryService.updateItem(editableItem)
        await historyService.logChanges(old: previous, new: editableItem, updatedBy: updatedBy)
    }
}
