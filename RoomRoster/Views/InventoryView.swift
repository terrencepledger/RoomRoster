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
    @StateObject private var sheets = SpreadsheetManager.shared
#if os(macOS)
    @Binding var selectedItemID: String?
    @State private var selectedItem: Item?
    private enum Pane: Hashable {
        case item(Item)
        case create
        case edit(Item)
        case sell(Item)
    }
    @State private var pane: Pane?
#else
    @State private var showCreateItemView = false
#endif
    @State private var expandedRooms: Set<Room> = []
    @State private var searchText: String = ""
    @State private var includeHistoryInSearch: Bool = false
    @State private var includeSoldItems: Bool = false
    @State private var logVersion = 0

    #if os(macOS)
    init(selectedItemID: Binding<String?>) {
        self._selectedItemID = selectedItemID
        self._selectedItem = State(initialValue: nil)
    }
    #else
    init() {}
    #endif

    var groupedItems: [(room: Room, items: [(Item, String)])] {
        let filtered = filteredItemsWithContext
        let grouped = Dictionary(grouping: filtered, by: { $0.0.lastKnownRoom })
        return grouped
            .map { (key, value) in (room: key, items: value) }
            .sorted { $0.room.label < $1.room.label }
    }

    var body: some View {
        Group {
#if os(macOS)
            NavigationSplitView {
                listPane
            } detail: {
                detailPane
            }
#else
            NavigationView {
                listPane
            }
#endif
        }
#if !os(macOS)
        .platformPopup(isPresented: $showCreateItemView) {
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
#endif
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                if sheets.currentSheet != nil {
                    Button(action: {
                        Logger.action("Pressed Add Item Toolbar")
                        pane = .create
                    }) {
                        Label(l10n.addItemButton, systemImage: "plus")
                    }
                }
            }
            #endif
        }
        .navigationTitle(l10n.title)
        .onAppear {
            Logger.page("InventoryView")
        }
        .task {
            guard sheets.currentSheet != nil else { return }
            await viewModel.fetchInventory()
            await viewModel.loadRecentLogs(for: viewModel.items)
            if let id = selectedItemID,
               let match = viewModel.items.first(where: { $0.id == id }) {
                selectedItem = match
                pane = .item(match)
            }
        }
        .refreshable {
            guard sheets.currentSheet != nil else { return }
            await viewModel.fetchInventory()
            await viewModel.loadRecentLogs(for: viewModel.items)
            if let id = selectedItemID,
               let match = viewModel.items.first(where: { $0.id == id }) {
                selectedItem = match
                pane = .item(match)
            }
        }
    }

#if os(macOS)
    @ViewBuilder
    private var detailPane: some View {
        switch pane {
        case .item(let item):
            ItemDetailsView(
                item: item,
                openEdit: { _ in pane = .edit(item) },
                openSell: { _ in pane = .sell(item) }
            )
            .environmentObject(viewModel)
        case .create:
            CreateItemView(
                viewModel: CreateItemViewModel(
                    inventoryService: InventoryService(),
                    roomService: RoomService(),
                    itemsProvider: { viewModel.items },
                    onSave: { newItem in
                        selectedItem = newItem
                        selectedItemID = newItem.id
                        pane = .item(newItem)
                        Task { await viewModel.fetchInventory() }
                    }
                ),
                onCancel: { pane = selectedItem != nil ? .item(selectedItem!) : nil }
            )
        case .edit(let item):
            EditItemView(
                editableItem: item,
                onSave: { updated in
                    selectedItem = updated
                    selectedItemID = updated.id
                    pane = .item(updated)
                    Task {
                        await viewModel.fetchInventory()
                        await viewModel.loadRecentLogs(for: viewModel.items)
                    }
                },
                onCancel: { pane = .item(item) }
            )
            .environmentObject(viewModel)
        case .sell(let item):
            SellItemView(
                viewModel: SellItemViewModel(item: item),
                onComplete: { result in
                selectedItem = item
                selectedItemID = item.id
                pane = .item(item)
                if case let .success(updated) = result {
                    selectedItem = updated
                    selectedItemID = updated.id
                    pane = .item(updated)
                    Task {
                        await viewModel.fetchInventory()
                        await viewModel.loadRecentLogs(for: viewModel.items)
                    }
                }
                },
                onCancel: { pane = .item(item) }
            )
        case nil:
            Text(l10n.selectItemPrompt)
                .foregroundColor(.secondary)
        }
    }
#endif

#if os(macOS)
    private var selectionBinding: Binding<Item?>? {
        Binding(
            get: { selectedItem },
            set: { newValue in
                selectedItem = newValue
                selectedItemID = newValue?.id
                if let value = newValue { pane = .item(value) } else { pane = nil }
            }
        )
    }
#else
    private var selectionBinding: Binding<Item?>? { nil }
#endif

    @ViewBuilder
    private var listPane: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }
                Spacer()
            }

            List(selection: selectionBinding) {
                if sheets.currentSheet == nil {
                    Text(l10n.selectSheetPrompt)
                        .foregroundColor(.secondary)
                } else {
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

                    if viewModel.items.isEmpty {
                        Text(l10n.emptyState)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(groupedItems, id: \.room) { group in
                            Section(header: sectionHeader(for: group.room)) {
                                if expandedRooms.contains(group.room) {
                                    ForEach(group.items, id: \.0.id) { (item, context) in
#if os(macOS)
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
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .tag(item)
                                        .contentShape(Rectangle())
#else
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
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                        .simultaneousGesture(
                                            TapGesture().onEnded { HapticManager.shared.impact() }
                                        )
#endif
                                    }
                                }
                            }
                        }
                    }
                }
            }
#if os(macOS)
            .listStyle(.inset)
#endif

#if os(iOS)
            if sheets.currentSheet != nil {
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
#endif
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
            Image(systemName: expandedRooms.contains(room) ? "chevron.down" : "chevron.right")
                .foregroundColor(.blue)
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
