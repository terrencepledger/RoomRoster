import SwiftUI
import Charts

private typealias l10n = Strings.reports

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @StateObject private var sheets = SpreadsheetManager.shared
    @State private var shareURL: URL?

    var body: some View {
        NavigationView {
            List {
                if sheets.currentSheet == nil {
                    Text(Strings.inventory.selectSheetPrompt)
                        .foregroundColor(.secondary)
                } else {
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
                    Chart {
                        ForEach(Status.allCases, id: \.self) { status in
                            let count = viewModel.statusCounts[status] ?? 0
                            SectorMark(angle: .value("Count", count))
                                .foregroundStyle(by: .value("Status", status.label))
                        }
                    }
                    .frame(height: 180)

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
                    Chart {
                        ForEach(viewModel.salesByMonth, id: \.date) { entry in
                            BarMark(
                                x: .value("Month", entry.date),
                                y: .value("Revenue", entry.total)
                            )
                        }
                    }
                    .frame(height: 180)

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
                    Chart {
                        ForEach(viewModel.roomCounts.keys.sorted(by: { $0.label < $1.label }), id: \.self) { room in
                            BarMark(
                                x: .value("Room", room.label),
                                y: .value("Items", viewModel.roomCounts[room] ?? 0)
                            )
                        }
                    }
                    .frame(height: 180)

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
                if sheets.currentSheet != nil {
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
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(activityItems: [url])
            }
        }
        .task {
            guard sheets.currentSheet != nil else { return }
            await viewModel.loadData()
        }
        .refreshable {
            guard sheets.currentSheet != nil else { return }
            await viewModel.loadData()
        }
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
