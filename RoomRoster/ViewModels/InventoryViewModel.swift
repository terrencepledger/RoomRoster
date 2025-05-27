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
    private let service = InventoryService()

    func loadRooms() async {
        do {
            self.rooms = try await RoomService().fetchRooms()
        } catch {
            Logger.log(error, extra: ["description": "Failed to fetch rooms"])
        }
    }

    func addRoom(name: String) async -> Room? {
        do {
            try await RoomService().addRoom(name: name)
            await loadRooms()
            return Room(name: name)
        } catch {
            Logger.log(error, extra: ["description": "Failed to add room"])
            return nil
        }
    }
    
    func fetchInventory() async {
        do {
            let response = try await service.fetchInventory()
            self.items = response.toItems()
        } catch {
            Logger.log(error, extra: [
                "description": "Error fetching inventory"
            ])
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
        }
    }
}
