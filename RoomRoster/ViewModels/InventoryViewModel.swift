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
}
