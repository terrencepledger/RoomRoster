//
//  InventoryView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI
import SwiftData
import Sentry

private typealias l10n = Strings.inventory

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var showCreateItemView = false
    @State private var expandedRooms: Set<Room> = []
    @State private var searchText: String = ""
    @State private var includeHistoryInSearch: Bool = false
    @State private var includeSoldItems: Bool = false
    @State private var logVersion = 0

    var groupedItems: [(room: Room, items: [(Item, String)])] {
        let filtered = filteredItemsWithContext
        let grouped = Dictionary(grouping: filtered, by: { $0.0.lastKnownRoom })
        return grouped
            .map { (key, value) in (room: key, items: value) }
            .sorted { $0.room.label < $1.room.label }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }
                    Spacer()
                }

                List {
                    Section {
                        TextField(l10n.searchPlaceholder, text: $searchText)
                            .textFieldStyle(.roundedBorder)

                        Toggle(l10n.includeHistoryToggle, isOn: $includeHistoryInSearch)
                            .font(.subheadline)
                            .padding(.top, 4)
                        Toggle(l10n.includeSoldToggle, isOn: $includeSoldItems)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)

                    ForEach(groupedItems, id: \.room) { group in
                        Section(header: sectionHeader(for: group.room)) {
                            if expandedRooms.contains(group.room) {
                                ForEach(group.items, id: \.0.id) { (item, context) in
                                    NavigationLink(destination: ItemDetailsView(item: item).environmentObject(viewModel)) {
                                        VStack(alignment: .leading) {
                                            Text(item.name).font(.headline)
                                            Text(l10n.status(item.status.label))
                                            if let tag = item.propertyTag {
                                                Text(l10n.tag(tag.label))
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            if !context.isEmpty {
                                                Text(l10n.matchedLabel(context))
                                                    .font(.caption)
                                                    .italic()
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .simultaneousGesture(
                                        TapGesture().onEnded { HapticManager.shared.impact() }
                                    )
                                }
                            }
                        }
                    }
                }

                Button(action: {
                    Logger.action("Pressed Add Item Button")
                    HapticManager.shared.impact()
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
            CreateItemView(
                viewModel: CreateItemViewModel(
                    inventoryService: InventoryService(),
                    roomService: RoomService(),
                    itemsProvider: { viewModel.items },
                    onSave: { newItem in
                        Task {
                            do {
                                try await InventoryService().createItem(newItem)
                                let createdBy = AuthenticationManager.shared.userName
                                await HistoryLogService().logCreation(for: newItem, createdBy: createdBy)
                                await viewModel.fetchInventory()
                            } catch {
                                Logger.log(error, extra: ["description": "Error creating item, updating log, or re-fetching"])
                                withAnimation {
                                    viewModel.errorMessage = l10n.failedToSave
                                }
                                HapticManager.shared.error()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                    withAnimation { viewModel.errorMessage = nil }
                                }
                            }
                        }
                    }
                )
            )
        }
        .navigationTitle(l10n.title)
        .onAppear {
            Logger.page("InventoryView")
        }
        .task {
            await viewModel.fetchInventory()
            await viewModel.loadRecentLogs(for: viewModel.items)
        }
        .refreshable {
            await viewModel.fetchInventory()
            await viewModel.loadRecentLogs(for: viewModel.items)
        }
    }

    var filteredItemsWithContext: [(Item, String)] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        var baseItems = viewModel.items
        if !includeSoldItems {
            baseItems = baseItems.filter { $0.status != .sold }
        }
        guard !query.isEmpty else {
            return baseItems.map { ($0, "") }
        }

        return baseItems.compactMap { item in
            if item.name.lowercased().contains(query) {
                return (item, l10n.query.name)
            } else if item.description.lowercased().contains(query) {
                return (item, l10n.query.description)
            } else if let tag = item.propertyTag?.label.lowercased(), tag.contains(query) {
                return (item, l10n.query.tag)
            } else if item.status.label.lowercased().contains(query) {
                return (item, l10n.query.status)
            } else if item.updatedBy.lowercased().contains(query) {
                return (item, l10n.query.updatedBy)
            } else if item.dateAdded.lowercased().contains(query) {
                return (item, l10n.query.dateAdded)
            }

            if includeHistoryInSearch {
                let logs = viewModel.recentLogs[item.id] ?? []
                for log in logs {
                    let lower = log.lowercased()
                    if lower.contains(query) {
                        if let field = extractFieldName(from: log) {
                            return (item, l10n.query.historyField(field))
                        } else {
                            return (item, l10n.query.history)
                        }
                    }
                }
            }

            return nil
        }
    }

    private func extractFieldName(from log: String) -> String? {
        let delimiter = "Edited '"
        if let range = log.range(of: delimiter), let end = log[range.upperBound...].firstIndex(of: "'") {
            return String(log[range.upperBound..<end])
        }
        return nil
    }

    @ViewBuilder
    private func sectionHeader(for room: Room) -> some View {
        HStack {
            Text(room.label)
                .font(.headline)
            Spacer()
            Button(action: {
                if expandedRooms.contains(room) {
                    expandedRooms.remove(room)
                } else {
                    expandedRooms.insert(room)
                }
            }) {
                Image(systemName: expandedRooms.contains(room) ? "chevron.down" : "chevron.right")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if expandedRooms.contains(room) {
                expandedRooms.remove(room)
            } else {
                expandedRooms.insert(room)
            }
            HapticManager.shared.impact()
        }
    }
}
