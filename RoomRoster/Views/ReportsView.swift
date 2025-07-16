import SwiftUI

private typealias l10n = Strings.reports

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var shareURL: URL?

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField(l10n.searchPlaceholder, text: $viewModel.query)
                            .textFieldStyle(.roundedBorder)
                        if !viewModel.query.isEmpty {
                            Button(l10n.clearSearch) { viewModel.query = "" }
                        }
                    }
                    Toggle(Strings.inventory.includeHistoryToggle, isOn: $viewModel.includeHistoryInSearch)
                        .font(.subheadline)
                    Toggle(Strings.inventory.includeSoldToggle, isOn: $viewModel.includeSoldItems)
                        .font(.subheadline)
                }

                if !viewModel.query.isEmpty {
                    Section(header: searchHeader) {
                        ForEach(viewModel.filteredItems, id: \.id) { item in
                            VStack(alignment: .leading) {
                                Text(item.name)
                                Text(item.lastKnownRoom.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text(l10n.inventorySummary)) {
                    ForEach(Status.allCases, id: \.self) { status in
                        HStack {
                            Text(status.label)
                            Spacer()
                            Text(String(viewModel.statusCounts[status] ?? 0))
                        }
                    }
                    HStack {
                        Text(l10n.totalValue)
                        Spacer()
                        Text("$\(viewModel.totalValue, specifier: "%.2f")")
                    }
                }

                Section(header: Text(l10n.salesOverview)) {
                    HStack {
                        Text(l10n.totalSold)
                        Spacer()
                        Text(String(viewModel.sales.count))
                    }
                    HStack {
                        Text(l10n.totalRevenue)
                        Spacer()
                        Text("$\(viewModel.totalSalesValue, specifier: "%.2f")")
                    }
                }

                Section(header: Text(l10n.roomsSummary)) {
                    ForEach(viewModel.roomCounts.keys.sorted(by: { $0.label < $1.label }), id: \.self) { room in
                        HStack {
                            Text(room.label)
                            Spacer()
                            Text(String(viewModel.roomCounts[room] ?? 0))
                        }
                    }
                }

                Section(header: Text(l10n.recentActivity)) {
                    ForEach(viewModel.recentLogs, id: \.self) { log in
                        Text(log)
                            .font(.footnote)
                    }
                }

            }
            .navigationTitle(l10n.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(l10n.exportOverview) {
                            shareURL = viewModel.exportOverviewCSV()
                        }
                        Button(l10n.exportCSV) {
                            shareURL = viewModel.exportCSV()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(activityItems: [url])
            }
        }
        .task { await viewModel.loadData() }
        .refreshable { await viewModel.loadData() }
        .onAppear { Logger.page("ReportsView") }
    }

    private var searchHeader: some View {
        HStack {
            Text(l10n.searchResults)
            Spacer()
            Button(l10n.exportSearch) { shareURL = viewModel.exportCSV() }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
