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
    @State private var expandedRooms: Set<Room> = []
    @State private var searchText: String = ""
    @State private var includeHistoryInSearch: Bool = false
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
                    if let error = errorMessage {
                        ErrorBanner(message: error)
                    }
                    Spacer()
                }

                List {
                    Section {
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.roundedBorder)

                        Toggle("Include History", isOn: $includeHistoryInSearch)
                            .font(.subheadline)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    .task {
                        await viewModel.fetchInventory()
                        await viewModel.loadRecentLogs(for: viewModel.items)
                    }
                    Text("Logs loaded: \(viewModel.recentLogs.count)")
                    Text("Include: \(String(describing: includeHistoryInSearch))")

                    ForEach(groupedItems, id: \.room) { group in
                        Section(header: sectionHeader(for: group.room)) {
                            if expandedRooms.contains(group.room) {
                                ForEach(group.items, id: \.0.id) { (item, context) in
                                    NavigationLink(destination: ItemDetailsView(item: item)) {
                                        VStack(alignment: .leading) {
                                            Text(item.name).font(.headline)
                                            Text("Status: \(item.status.label)")
                                            if let tag = item.propertyTag {
                                                Text("Tag: \(tag.label)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            if !context.isEmpty {
                                                Text("Matched in: \(context)")
                                                    .font(.caption)
                                                    .italic()
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Inventory")
                .refreshable {
                    await viewModel.fetchInventory()
                    await viewModel.loadRecentLogs(for: viewModel.items)
                }
                .onAppear {
                    Logger.page("ContentView")
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
            CreateItemView(viewModel: viewModel) { newItem in
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
    }

    var filteredItemsWithContext: [(Item, String)] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            return viewModel.items.map { ($0, "") }
        }

        return viewModel.items.compactMap { item in
            if item.name.lowercased().contains(query) {
                return (item, "name")
            } else if item.description.lowercased().contains(query) {
                return (item, "description")
            } else if let tag = item.propertyTag?.label.lowercased(), tag.contains(query) {
                return (item, "property tag")
            } else if item.status.label.lowercased().contains(query) {
                return (item, "status")
            } else if item.updatedBy.lowercased().contains(query) {
                return (item, "updated by")
            } else if item.dateAdded.lowercased().contains(query) {
                return (item, "date added")
            }

            if includeHistoryInSearch {
                let logs = viewModel.recentLogs[item.id] ?? []
                for log in logs {
                    let lower = log.lowercased()
                    print("Query: \(query), log: \(lower)")
                    if lower.contains(query) {
                        if let field = extractFieldName(from: log) {
                            return (item, "history (\(field))")
                        } else {
                            return (item, "history")
                        }
                    }
                }
            }

            return nil
        }
    }

    private func extractFieldName(from log: String) -> String? {
        if let range = log.range(of: "Edited '"), let end = log[range.upperBound...].firstIndex(of: "'") {
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
        }
    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
