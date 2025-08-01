//
//  EditItemViewModel.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import SwiftUI
import Foundation

@MainActor
final class EditItemViewModel: ObservableObject {
    @Published var editableItem: Item
    @Published var pickedReceiptImage: PlatformImage?
    @Published var pickedReceiptPDF: URL?
    @Published var isUploadingReceipt: Bool = false
    @Published var receiptUploadError: String?
    @Published var isSaving: Bool = false

    private let inventoryService: InventoryService
    private let historyService: HistoryLogService
    private let receiptService: PurchaseReceiptService

    init(
        item: Item,
        inventoryService: InventoryService = .init(),
        historyService: HistoryLogService = .init(),
        receiptService: PurchaseReceiptService = .init()
    ) {
        self.editableItem = item
        self.inventoryService = inventoryService
        self.historyService = historyService
        self.receiptService = receiptService
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

    func onReceiptPicked(_ image: PlatformImage?) {
        pickedReceiptImage = image
    }

    func onReceiptPDFPicked(_ url: URL?) {
        pickedReceiptPDF = url
    }

    private func saveReceiptImage(_ image: PlatformImage) async {
        isUploadingReceipt = true
        receiptUploadError = nil
        do {
            let url = try await receiptService.uploadReceipt(image: image, for: editableItem.id)
            editableItem.purchaseReceiptURL = url.absoluteString
        } catch {
            receiptUploadError = error.localizedDescription
            HapticManager.shared.error()
        }
        isUploadingReceipt = false
    }

    private func saveReceiptPDF(from url: URL) async {
        isUploadingReceipt = true
        receiptUploadError = nil
        do {
            let data = try Data(contentsOf: url)
            let saved = try await receiptService.uploadReceiptPDF(data, for: editableItem.id)
            editableItem.purchaseReceiptURL = saved.absoluteString
        } catch {
            receiptUploadError = error.localizedDescription
            HapticManager.shared.error()
        }
        isUploadingReceipt = false
    }
}
