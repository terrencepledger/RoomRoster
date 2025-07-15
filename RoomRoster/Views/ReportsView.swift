import SwiftUI

private typealias l10n = Strings.reports

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var shareURL: URL?

    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField(l10n.searchPlaceholder, text: $viewModel.query)
                }

                if !viewModel.query.isEmpty {
                    Section(header: Text(l10n.searchResults)) {
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
                    Button(l10n.exportCSV) {
                        shareURL = viewModel.exportCSV()
                    }
                }
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(activityItems: [url])
            }
        }
        .task { await viewModel.loadData() }
        .onAppear { Logger.page("ReportsView") }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
