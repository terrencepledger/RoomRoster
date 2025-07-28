//
//  ItemDetailsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private typealias l10n = Strings.itemDetails

struct ItemDetailsView: View {
    @State var item: Item
    @State private var isEditing = false
    @State private var errorMessage: String? = nil
    @State private var showingSellSheet = false
    @State private var showingSaleDetails = false
    @State private var sale: Sale?
    @State private var saleSuccess: String?
    @State private var saleError: String?
    @StateObject private var viewModel = ItemDetailsViewModel()
    @State private var shareURL: URL?

    @EnvironmentObject var inventoryVM: InventoryViewModel

    init(item: Item) {
        _item = State(initialValue: item)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }
                    if let message = saleSuccess {
                        SuccessBanner(message: message)
                    }
                    if let sellError = saleError {
                        ErrorBanner(message: sellError)
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

                    if item.purchaseReceiptURL != nil {
                        Text("Purchase Receipt")
                            .font(.headline)
                        ReceiptImageView(urlString: item.purchaseReceiptURL)
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

                        if let current = item.depreciatedValue {
                            HStack {
                                Text(l10n.depreciatedPriceTitle).bold()
                                Text("$\(current, specifier: "%.2f")")
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
                    VStack {
                        Button(l10n.editItem) {
                            Logger.action("Pressed Edit Button")
                            HapticManager.shared.impact()
                            isEditing = true
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        if item.status == .sold {
                            Button(Strings.saleDetails.title) {
                                Logger.action("Pressed Sale Details Button")
                                HapticManager.shared.impact()
                                showingSaleDetails = true
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else {
                            Button(Strings.sellItem.title) {
                                Logger.action("Pressed Sell Button")
                                HapticManager.shared.impact()
                                showingSellSheet = true
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(l10n.title)
        .toolbar {
            ToolbarItem(placement: toolbarDetailsPlacement) {
                let hasImage = URL(string: item.imageURL) != nil
                let hasReceipt = item.purchaseReceiptURL != nil

                if hasImage || hasReceipt {
                    Menu {
                        if hasImage, let url = URL(string: item.imageURL) {
                            Button(l10n.downloadImage) {
                                Task {
                                    do {
                                        shareURL = try await viewModel.downloadImage(from: url)
                                        HapticManager.shared.success()
                                    } catch {
                                        Logger.log(error, extra: ["description": "Failed to download image"])
                                        HapticManager.shared.error()
                                        viewModel.errorMessage = l10n.downloadFailed
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                            withAnimation { viewModel.errorMessage = nil }
                                        }
                                    }
                                }
                            }
                            .platformButtonStyle()
                        }

                        if hasReceipt {
                            Button(l10n.downloadReceipt) {
                                Task {
                                    do {
                                        shareURL = try await viewModel.downloadReceipt(for: item.id)
                                        HapticManager.shared.success()
                                    } catch {
                                        Logger.log(error, extra: ["description": "Failed to download receipt"])
                                        HapticManager.shared.error()
                                        viewModel.errorMessage = l10n.downloadFailed
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                            withAnimation { viewModel.errorMessage = nil }
                                        }
                                    }
                                }
                            }
                            .platformButtonStyle()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
        }
        .platformPopup(isPresented: $isEditing) {
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
                        await inventoryVM.fetchInventory()
                    } catch {
                        Logger.log(error, extra: [
                            "description": "Error updating item",
                            "item": String(describing: updatedItem)
                        ])
                        withAnimation {
                            viewModel.errorMessage = l10n.failedToUpdate
                        }
                        HapticManager.shared.error()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { viewModel.errorMessage = nil }
                        }
                    }
                }
            }
            .environmentObject(inventoryVM)
        }
        .platformPopup(isPresented: $showingSellSheet) {
            SellItemView(viewModel: SellItemViewModel(item: item)) { result in
                showingSellSheet = false
                switch result {
                case .success(let updatedItem):
                    self.item = updatedItem
                    saleSuccess = Strings.sellItem.success
                    Task {
                        await inventoryVM.fetchInventory()
                        await loadSale()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { saleSuccess = nil }
                    }
                case .failure:
                    saleError = Strings.sellItem.failure
                    HapticManager.shared.error()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { saleError = nil }
                    }
                }
            }
        }
        .platformPopup(isPresented: $showingSaleDetails) {
            if let sale {
                SalesDetailsView(sale: sale, itemName: item.name)
            }
        }
        .sheet(item: $shareURL) { url in
            ShareSheet(activityItems: [url])
        }
        .onAppear {
            Logger.page("ItemDetailsView")
            Task { await AuthenticationManager.shared.signIn() }
        }
        .task {
            await viewModel.fetchItemHistory(for: item.id)
        }
        .task {
            await loadSale()
        }
        .refreshable {
            Logger.action("Refreshing")
            await viewModel.fetchItemHistory(for: item.id)
        }
    }

    private func loadSale() async {
        guard item.status == .sold else { return }
        do {
            sale = try await SalesService().fetchSale(for: item.id)
        } catch {
            Logger.log(error, extra: ["description": "Failed to load sale details"])
        }
    }

    private var toolbarDetailsPlacement: ToolbarItemPlacement {
#if os(iOS)
        .navigationBarTrailing
#else
        .automatic
#endif
    }
}

