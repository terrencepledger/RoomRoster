//
//  InventoryViewModel.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI

@MainActor
class InventoryViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var rooms: [Room] = []
    @Published var recentLogs: [String: [String]] = [:]
    @Published var errorMessage: String?
    private let service: InventoryService
    private let roomService: RoomService

    init(
        inventoryService: InventoryService = InventoryService(),
        roomService: RoomService = RoomService()
    ) {
        self.service = inventoryService
        self.roomService = roomService
    }

    func loadRooms() async {
        do {
            self.rooms = try await roomService.fetchRooms()
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }
            Logger.log(error, extra: ["description": "Failed to fetch rooms"])
            errorMessage = Strings.inventory.failedToLoadRooms
            HapticManager.shared.error()
        }
    }

    func addRoom(name: String) async -> Room? {
        do {
            return try await roomService.addRoom(name: name)
        } catch {
            Logger.log(error, extra: ["description": "Failed to add room"])
            errorMessage = Strings.inventory.failedToAddRoom
            HapticManager.shared.error()
            return nil
        }
    }
    
    func fetchInventory() async {
        do {
            let response = try await service.fetchInventory()
            self.items = response.toItems()
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }
            Logger.log(error, extra: [
                "description": "Error fetching inventory"
            ])
            errorMessage = Strings.inventory.failedToLoad
            HapticManager.shared.error()
        }
    }

    func loadRecentLogs(for items: [Item], maxPerItem: Int = 5) async {
        do {
            let sheet = try await service.fetchAllHistory()
            
            var newLogs: [String: [String]] = [:]
            for item in items {
                if let row = sheet.values.first(where: { $0.first == item.id }) {
                    newLogs[item.id] = Array(row.dropFirst()).prefix(maxPerItem).map { $0 }
                } else {
                    newLogs[item.id] = []
                }
            }
            recentLogs = newLogs
        } catch {
            Logger.log(error, extra: ["context": "Failed to load item logs"])
            errorMessage = Strings.inventory.failedToLoadLogs
            HapticManager.shared.error()
        }
    }

    func move(items: [Item], to room: Room) async {
        for item in items {
            var updated = item
            updated.lastKnownRoom = room
            do {
                try await service.updateItem(updated)
            } catch {
                Logger.log(error, extra: ["description": "Failed to move item"])
                errorMessage = Strings.inventory.failedToUpdate
                HapticManager.shared.error()
            }
        }
        await fetchInventory()
    }

    func updateStatus(items: [Item], to status: Status) async {
        for item in items {
            var updated = item
            updated.status = status
            do {
                try await service.updateItem(updated)
            } catch {
                Logger.log(error, extra: ["description": "Failed to update status"])
                errorMessage = Strings.inventory.failedToUpdate
                HapticManager.shared.error()
            }
        }
        await fetchInventory()
    }
}
