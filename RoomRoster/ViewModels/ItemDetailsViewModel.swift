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
    private let downloader = FileDownloadService()
    private let receiptService = PurchaseReceiptService()

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

    func downloadImage(from url: URL) async throws -> URL {
        try await downloader.download(from: url)
    }

    func downloadReceipt(for itemId: String) async throws -> URL {
        let data = try await receiptService.loadReceipt(for: itemId)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(itemId).pdf")
        try data.write(to: fileURL)
        return fileURL
    }
}
