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
    private let service = InventoryService()
    
    func fetchInventory() async {
        do {
            let response = try await service.fetchInventory()
            self.items = response.toItems()
        } catch {
            // Handle error appropriately (e.g., update UI or show an alert)
            print("Error fetching inventory: \(error)")
        }
    }
}
