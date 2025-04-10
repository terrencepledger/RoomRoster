//
//  ContentView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = InventoryViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.items) { item in
                NavigationLink(destination: ItemDetailsView(item: item)) {
                    VStack(alignment: .leading) {
                        Text(item.name).font(.headline)
                        Text("Status: \(item.status)")
                        Text("Room: \(item.lastKnownRoom)")
                        if let tag = item.propertyTag {
                            Text("Tag: \(tag)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Inventory")
            .task {
                await viewModel.fetchInventory()
            }
            .refreshable {
                await viewModel.fetchInventory()
            }
        }
    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
