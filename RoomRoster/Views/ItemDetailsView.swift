//
//  ItemDetailsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI

struct ItemDetailsView: View {
    @State var item: Item
    @State private var isEditing = false
    @State private var errorMessage: String? = nil
    @StateObject private var viewModel = ItemDetailsViewModel()

    let inventoryVM = InventoryViewModel()

    init(item: Item) {
        _item = State(initialValue: item)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let error = errorMessage {
                        ErrorBanner(message: error)
                    }
                    if let url = URL(string: item.imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 250)
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(item.description)
                            .font(.body)
                            .foregroundColor(.gray)

                        HStack {
                            Text("Quantity:").bold()
                            Text(String(describing: item.quantity))
                        }

                        if let tag = item.propertyTag {
                            HStack {
                                Text("Property Tag:")
                                    .font(.headline)
                                
                                Text(tag.label)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Date Added:").bold()
                            Text(item.dateAdded)
                        }

                        if let price = item.estimatedPrice {
                            HStack {
                                Text("Estimated Price:").bold()
                                Text("$\(price, specifier: "%.2f")")
                            }
                        }

                        HStack {
                            Text("Status:").bold()
                            Text(item.status.label)
                                .foregroundColor(item.status.color)
                        }

                        HStack {
                            Text("Last Known Room:").bold()
                            Text(item.lastKnownRoom.name)
                        }

                        if let date = item.lastUpdated?.toShortString() {
                            Text("Last Updated: \(date)")
                        }

                        Divider()

                        Text("History Log")
                            .font(.headline)

                        // Show a spinner while history logs are loading
                        if viewModel.isLoadingHistory {
                            ProgressView("Loading history…")
                                .padding(.vertical)
                        }
                        // Then show no-history or the logs
                        else if viewModel.historyLogs.isEmpty {
                            Text("No history available")
                                .foregroundColor(.gray)
                            Text(String(describing: viewModel.historyLogs))
                        } else {
                            ForEach(viewModel.historyLogs, id: \.self) { log in
                                Text("* \(log)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Edit Item") {
                        Logger.action("Pressed Edit Button")
                        isEditing = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .navigationTitle("Item Details")
        .sheet(isPresented: $isEditing) {
            EditItemView(editableItem: item) { updatedItem in
                let oldItem = item
                Task {
                    do {
                        try await InventoryService().updateItem(updatedItem)
                        item = updatedItem
                        let updatedBy = AuthenticationManager.shared.userName
                        await HistoryLogService()
                            .logChanges(old: oldItem, new: updatedItem, updatedBy: updatedBy)
                        await viewModel.fetchItemHistory(for: item.id)
                    } catch {
                        Logger.log(error, extra: [
                            "description": "Error updating item",
                            "item": String(describing: updatedItem)
                        ])
                        withAnimation {
                            errorMessage = "Failed to update item. Please try again."
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { errorMessage = nil }
                        }
                    }
                }
            }
            .environmentObject(inventoryVM)
        }
        .onAppear {
            Logger.page("ItemDetailsView")
        }
        .task {
            await AuthenticationManager.shared.signIn()
        }
        .task {
            await viewModel.fetchItemHistory(for: item.id)
        }
        .refreshable {
            Logger.action("Refreshing")
            await viewModel.fetchItemHistory(for: item.id)
        }
    }
}
