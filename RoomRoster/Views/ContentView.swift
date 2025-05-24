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
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    if let error = errorMessage {
                        ErrorBanner(message: error)
                    }
                    Spacer()
                }

                List(viewModel.items) { item in
                    NavigationLink(destination: ItemDetailsView(item: item)) {
                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text("Status: \(item.status.label)")
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
                    Logger.action("Pressed Add Item Button")
                    showCreateItemView.toggle()
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
                        let createdBy = AuthenticationManager.shared.userName
                        await HistoryLogService().logCreation(for: newItem, createdBy: createdBy)
                        await viewModel.fetchInventory()
                    } catch {
                        Logger.log(error, extra: ["description": "Error creating item, updating log, or re-fetching"])
                        withAnimation {
                            errorMessage = "Failed to save item. Please try again."
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation {
                                errorMessage = nil
                            }
                        }
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
