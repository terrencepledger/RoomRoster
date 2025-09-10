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
    @StateObject private var auth = AuthenticationManager.shared
#if os(macOS)
    @Binding var selectedItemID: String?
    @State private var selectedItem: Item?
    private enum Pane: Hashable {
        case item(Item)
        case create
        case edit(Item)
        case sell(Item)
        case saleDetails(Sale, Item)
    }
    @State private var pane: Pane?
#endif
    @State private var expandedRooms: Set<Room> = []
    @State private var searchText: String = ""
    @State private var includeHistoryInSearch: Bool = false
    @State private var includeSoldItems: Bool = false
    @State private var includeDiscardedItems: Bool = false
    @State private var logVersion = 0
    @State private var successMessage: String?
    @State private var createItemViewModel: CreateItemViewModel?
#if !os(macOS)
    @State private var path = NavigationPath()
#endif
    @State private var showingScanner = false

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
            ZStack(alignment: .bottomTrailing) {
                NavigationSplitView {
                    listPane
                } detail: {
                    detailPane
                }
                if let message = successMessage {
                    SuccessBanner(message: message)
                        .allowsHitTesting(false)
                        .padding()
                }
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                        .allowsHitTesting(false)
                        .padding()
                }
            }
#else
            NavigationStack(path: $path) {
                ZStack(alignment: .bottomTrailing) {
                    listPane
                    if let message = successMessage {
                        SuccessBanner(message: message)
                            .allowsHitTesting(false)
                            .padding()
                    }
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                            .allowsHitTesting(false)
                            .padding()
                    }
                }
                .platformPopup(
                    isPresented: Binding(
                        get: { createItemViewModel != nil },
                        set: { if !$0 { createItemViewModel = nil } }
                    )
                ) {
                    if let createItemViewModel {
                        CreateItemView(viewModel: createItemViewModel)
                            .environmentObject(viewModel)
                    }
                }
                .navigationDestination(for: Item.self) { item in
                    ItemDetailsView(item: item)
                        .environmentObject(viewModel)
                }
            }
#endif
        }
        .toolbar {
#if os(macOS)
            ToolbarItemGroup(placement: .primaryAction) {
                if sheets.currentSheet != nil {
                    Button(action: { openCreateItem() }) {
                        Label(l10n.addItemButton, systemImage: "plus")
                    }
                }
            }
#else
            if sheets.currentSheet != nil {
                Button(action: {
                    Logger.action("Pressed Scan Toolbar")
                    showingScanner = true
                }) {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
                Button(action: { openCreateItem() }) {
                    Label(l10n.addItemButton, systemImage: "plus")
                }
            }
#endif
        }
        .navigationTitle(l10n.title)
#if os(iOS)
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView { code in
                handleScanned(code)
                showingScanner = false
            }
        }
#endif
        .onAppear {
            Logger.page("InventoryView")
        }
        .task {
            guard auth.isSignedIn, sheets.currentSheet != nil else { return }
            await viewModel.loadRooms()
            await viewModel.fetchInventory()
            await viewModel.loadRecentLogs(for: viewModel.items)
#if os(macOS)
            if let id = selectedItemID,
               let match = viewModel.items.first(where: { $0.id == id }) {
                selectedItem = match
                pane = .item(match)
            }
#endif
        }
        .refreshable {
            guard auth.isSignedIn, sheets.currentSheet != nil else { return }
            await viewModel.loadRooms()
            await viewModel.fetchInventory()
            await viewModel.loadRecentLogs(for: viewModel.items)
#if os(macOS)
            if let id = selectedItemID,
               let match = viewModel.items.first(where: { $0.id == id }) {
                selectedItem = match
                pane = .item(match)
            }
#endif
        }
#if os(macOS)
        .onChange(of: viewModel.items) { _ in
            syncSelectionWithInventory()
        }
#endif
        .onChange(of: auth.isSignedIn) { signedIn in
            if signedIn, sheets.currentSheet != nil {
                Task {
                    await viewModel.loadRooms()
                    await viewModel.fetchInventory()
                    await viewModel.loadRecentLogs(for: viewModel.items)
                }
            }
        }
        .onChange(of: sheets.currentSheet?.id) { sheetID in
            if sheetID != nil, auth.isSignedIn {
                Task {
                    await viewModel.loadRooms()
                    await viewModel.fetchInventory()
                    await viewModel.loadRecentLogs(for: viewModel.items)
                }
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
                openSell: { _ in pane = .sell(item) },
                openSaleDetails: { sale, item in pane = .saleDetails(sale, item) }
            )
            .id(item)
            .environmentObject(viewModel)
        case .create:
            if let createItemViewModel {
                CreateItemView(
                    viewModel: createItemViewModel,
                    onCancel: { pane = selectedItem != nil ? .item(selectedItem!) : nil }
                )
                .environmentObject(viewModel)
            }
        case .edit(let item):
            EditItemView(
                editableItem: item,
                onSave: { updated in
                    let oldItem = item
                    selectedItem = updated
                    selectedItemID = updated.id
                    pane = .item(updated)
                    Task {
                        do {
                            try await InventoryService().updateItem(updated)
                            let updatedBy = AuthenticationManager.shared.userName
                            await HistoryLogService()
                                .logChanges(old: oldItem, new: updated, updatedBy: updatedBy)
                            await viewModel.fetchInventory()
                            await viewModel.loadRecentLogs(for: viewModel.items)
                            successMessage = Strings.editItem.success
                            HapticManager.shared.success()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation { successMessage = nil }
                            }
                        } catch {
                            Logger.log(error, extra: [
                                "description": "Error updating item",
                                "item": String(describing: updated)
                            ])
                            withAnimation { viewModel.errorMessage = Strings.itemDetails.failedToUpdate }
                            HapticManager.shared.error()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation { viewModel.errorMessage = nil }
                            }
                        }
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
                    successMessage = Strings.sellItem.success
                    HapticManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { successMessage = nil }
                    }
                }
                },
                onCancel: { pane = .item(item) }
            )
        case .saleDetails(let sale, let item):
            SalesDetailsView(sale: sale, itemName: item.name)
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
#if os(macOS)
            List(selection: selectionBinding) {
                listContent
            }
            .listStyle(.inset)
#else
            List {
                listContent
            }

            if sheets.currentSheet != nil {
                VStack(spacing: 16) {
#if os(iOS)
                    Button(action: {
                        Logger.action("Pressed Scan Button")
                        HapticManager.shared.impact()
                        showingScanner = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
#endif
                    Button(action: { openCreateItem() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                .padding()
            }
#endif
        }
    }

    @ViewBuilder
    private var listContent: some View {
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
                HStack {
                    Toggle(l10n.includeSoldToggle, isOn: $includeSoldItems)
                    Toggle(l10n.includeDiscardedToggle, isOn: $includeDiscardedItems)
                }
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
                                        .foregroundColor(item.status.color)
                                    if let range = item.propertyTagRange {
                                        let label = range.tags.count > 1 ? l10n.tags(range.stringValue()) : l10n.tag(range.stringValue())
                                        Text(label)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    } else if let tag = item.propertyTag?.label {
                                        Text(l10n.tag(tag))
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
                                NavigationLink(value: item) {
                                    VStack(alignment: .leading) {
                                        Text(item.name).font(.headline)
                                        Text(l10n.status(item.status.label))
                                            .foregroundColor(item.status.color)
                                        if let range = item.propertyTagRange {
                                            let label = range.tags.count > 1 ? l10n.tags(range.stringValue()) : l10n.tag(range.stringValue())
                                            Text(label)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        } else if let tag = item.propertyTag?.label {
                                            Text(l10n.tag(tag))
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
#endif
                            }
                        }
                    }
                }
            }
        }
    }

    var filteredItemsWithContext: [(Item, String)] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        var baseItems = viewModel.items
        if !includeSoldItems {
            baseItems = baseItems.filter { $0.status != .sold }
        }
        if !includeDiscardedItems {
            baseItems = baseItems.filter { $0.status != .discarded }
        }
        guard !query.isEmpty else {
            return baseItems.map { ($0, "") }
        }

        return baseItems.compactMap { item in
            if item.name.lowercased().contains(query) {
                return (item, l10n.query.name)
            } else if item.description.lowercased().contains(query) {
                return (item, l10n.query.description)
            } else if let tag = (item.propertyTagRange?.stringValue() ?? item.propertyTag?.label)?.lowercased(),
                      tag.contains(query) {
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

#if os(macOS)
    private func syncSelectionWithInventory() {
        guard let id = selectedItemID,
              let match = viewModel.items.first(where: { $0.id == id }) else {
            return
        }
        selectedItem = match
        if case .item = pane {
            pane = .item(match)
        }
    }
#endif

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

extension InventoryView {
    /// Returns a display string for the item's property tags and whether it's a range.
    private func propertyTagString(for item: Item) -> (String, Bool)? {
        if let range = item.propertyTagRange {
            return (range.label, range.tags.count > 1)
        }
        if let tag = item.propertyTag {
            return (tag.label, false)
        }
        if let groupID = item.groupID {
            let tags = viewModel.items
                .filter { $0.groupID == groupID }
                .flatMap { $0.propertyTagRange?.tags ?? ($0.propertyTag.map { [$0] } ?? []) }
                .sorted { $0.rawValue < $1.rawValue }
            guard !tags.isEmpty else { return nil }
            let range = PropertyTagRange(tags: tags)
            return (range.label, tags.count > 1)
        }
        return nil
    }

    func openCreateItem(prefilledTag: String? = nil) {
        Logger.action("Pressed Add Item Button")
        HapticManager.shared.impact()
        let vm = CreateItemViewModel(
            inventoryService: InventoryService(),
            roomService: RoomService(),
            itemsProvider: { viewModel.items },
            onSave: { newItem in
#if os(macOS)
                selectedItem = newItem
                selectedItemID = newItem.id
                pane = .item(newItem)
                Task {
                    await viewModel.fetchInventory()
                    successMessage = Strings.createItem.success
                    HapticManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { successMessage = nil }
                    }
                }
#else
                Task {
                    let createdBy = AuthenticationManager.shared.userName
                    await HistoryLogService().logCreation(for: newItem, createdBy: createdBy)
                    await viewModel.fetchInventory()
                    successMessage = Strings.createItem.success
                    HapticManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation { successMessage = nil }
                    }
                }
#endif
            }
        )
        if let prefilledTag {
            vm.propertyTagInput = prefilledTag
            vm.validateTag()
        }
        createItemViewModel = vm
#if os(macOS)
        pane = .create
#endif
    }

    func handleScanned(_ code: String) {
        guard let tag = PropertyTag(rawValue: code) else {
            openCreateItem(prefilledTag: code)
            return
        }
        if let match = viewModel.items.first(where: { item in
            if let pt = item.propertyTag, pt.rawValue == tag.rawValue { return true }
            if let range = item.propertyTagRange, range.tags.contains(tag) { return true }
            return false
        }) {
#if os(macOS)
            selectedItem = match
            selectedItemID = match.id
            pane = .item(match)
#else
            path.append(match)
#endif
        } else {
            openCreateItem(prefilledTag: tag.rawValue)
        }
    }
}
