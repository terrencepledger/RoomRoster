//
//  ItemDetailsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI

private typealias l10n = Strings.itemDetails

struct ItemDetailsView: View {
    @State var item: Item
    @State private var isEditing = false
    @State private var errorMessage: String? = nil
    @State private var showingSellSheet = false
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
                            Text(l10n.quantity).bold()
                            Text(String(describing: item.quantity))
                        }

                        if let tag = item.propertyTag {
                            HStack {
                                Text(l10n.tag)
                                    .font(.headline)
                                
                                Text(tag.label)
                            }
                        }

                        Divider()

                        HStack {
                            Text(l10n.dateAdded).bold()
                            Text(item.dateAdded)
                        }

                        if let price = item.estimatedPrice {
                            HStack {
                                Text(l10n.priceTitle).bold()
                                Text("$\(price, specifier: "%.2f")")
                            }
                        }

                        HStack {
                            Text(l10n.status).bold()
                            Text(item.status.label)
                                .foregroundColor(item.status.color)
                        }

                        HStack {
                            Text(l10n.room).bold()
                            Text(item.lastKnownRoom.name)
                        }

                        if let date = item.lastUpdated?.toShortString() {
                            Text(l10n.dateUpdated(date))
                        }

                        Divider()

                        Text(l10n.logs.title)
                            .font(.headline)

                        if viewModel.isLoadingHistory {
                            ProgressView(l10n.logs.loading)
                                .padding(.vertical)
                        }
                        else if viewModel.historyLogs.isEmpty {
                            Text(l10n.logs.emptyState)
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.historyLogs, id: \.self) { log in
                                Text(l10n.logs.row(log))
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
                    Button(l10n.editItem) {
                        Logger.action("Pressed Edit Button")
                        isEditing = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()

                    Button(Strings.sellItem.title) {
                        Logger.action("Pressed Sell Button")
                        showingSellSheet = true
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .navigationTitle(l10n.title)
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
                            errorMessage = l10n.failedToUpdate
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { errorMessage = nil }
                        }
                    }
                }
            }
            .environmentObject(inventoryVM)
        }
        .sheet(isPresented: $showingSellSheet) {
            SellItemView(viewModel: SellItemViewModel(item: item))
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
