//
//  ContentView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI
import SwiftData
import Sentry

struct ContentView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var showCreateItemView = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
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
                .refreshable {
                    await viewModel.fetchInventory()
                }
                
                Button(action: {
                    showCreateItemView.toggle()
                    Logger.action("Pressed Add Item")
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showCreateItemView) {
            CreateItemView { newItem in
                Task {
                    do {
                        try await InventoryService().createItem(newItem)
                        await viewModel.fetchInventory()
                    } catch {
                        print("Error creating item: \(error)")
                    }
                }
            }
        }
        .task {
            await viewModel.fetchInventory()
        }
        .onAppear {
            Logger.page("ContentView")
        }
    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
