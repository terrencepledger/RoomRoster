import SwiftUI

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var recentLogs: [String] = []
    @Published var recentLogsByItem: [String: [String]] = [:]
    @Published var statusCounts: [Status: Int] = [:]
    @Published var roomCounts: [Room: Int] = [:]
    @Published var totalValue: Double = 0
    @Published var query: String = ""
    @Published var includeHistoryInSearch: Bool = false
    @Published var includeSoldItems: Bool = false
    @Published var sales: [Sale] = []
    @Published var totalSalesValue: Double = 0

    private let inventoryService: InventoryService
    private let salesService: SalesService
    init(
        inventoryService: InventoryService = .init(),
        salesService: SalesService = .init()
    ) {
        self.inventoryService = inventoryService
        self.salesService = salesService
    }

    func loadData() async {
        await fetchItems()
        await fetchSales()
        await loadRecentLogs()
    }

    func fetchItems() async {
        do {
            let response = try await inventoryService.fetchInventory()
            let items = response.toItems()
            self.items = items
            computeSummaries(for: items)
            computeTotalValue(for: items)
        } catch {
            Logger.log(error, extra: ["description": "Failed to fetch inventory for reports"])
        }
    }

    func fetchSales() async {
        do {
            sales = try await salesService.fetchSales()
            totalSalesValue = sales.compactMap { $0.price }.reduce(0, +)
        } catch {
            Logger.log(error, extra: ["description": "Failed to fetch sales for reports"])
        }
    }

    private func computeSummaries(for items: [Item]) {
        statusCounts = Dictionary(grouping: items, by: { $0.status }).mapValues { $0.count }
        roomCounts = Dictionary(grouping: items, by: { $0.lastKnownRoom }).mapValues { $0.count }
    }

    private func computeTotalValue(for items: [Item]) {
        totalValue = items.compactMap { $0.estimatedPrice }.reduce(0, +)
    }

    func loadRecentLogs(maxEntries: Int = 10) async {
        do {
            let sheet = try await inventoryService.fetchAllHistory()
            let itemsById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

            var logsByItem: [String: [String]] = [:]
            var flattened: [String] = []

            for row in sheet.values {
                guard let itemId = row.first else { continue }
                let logs = Array(row.dropFirst())
                logsByItem[itemId] = logs
                let prefix = itemsById[itemId]?.name ?? itemId
                flattened.append(contentsOf: logs.map { "\(prefix): \($0)" })
            }

            recentLogsByItem = logsByItem
            recentLogs = Array(flattened.suffix(maxEntries))
        } catch {
            Logger.log(error, extra: ["description": "Failed to fetch history for reports"])
        }
    }

    var filteredItems: [Item] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var base = items
        if !includeSoldItems {
            base = base.filter { $0.status != .sold }
        }
        guard !q.isEmpty else { return base }

        return base.filter { item in
            if item.name.lowercased().contains(q) { return true }
            if item.description.lowercased().contains(q) { return true }
            if let tag = item.propertyTag?.label.lowercased(), tag.contains(q) { return true }
            if item.status.label.lowercased().contains(q) { return true }
            if item.updatedBy.lowercased().contains(q) { return true }
            if item.dateAdded.lowercased().contains(q) { return true }

            if includeHistoryInSearch {
                for log in recentLogsByItem[item.id] ?? [] {
                    if log.lowercased().contains(q) { return true }
                }
            }

            return false
        }
    }

    var salesByMonth: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: sales) { sale in
            calendar.date(from: calendar.dateComponents([.year, .month], from: sale.date)) ?? sale.date
        }
        return groups.map { key, values in
            let total = values.compactMap { $0.price }.reduce(0, +)
            return (key, total)
        }
        .sorted { $0.date < $1.date }
    }

    func exportCSV() -> URL? {
        let header = ItemField.allCases.map { $0.label }.joined(separator: ",")
        let lines: [String] = filteredItems.map { item in
            ItemField.allCases.map { field in
                if let binding = Item.schema[field] {
                    let value = binding.extract(from: item).replacingOccurrences(of: "\"", with: "\"\"")
                    return "\"\(value)\""
                }
                return ""
            }.joined(separator: ",")
        }
        let csv = ([header] + lines).joined(separator: "\n")
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("inventory.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            Logger.log(error, extra: ["description": "Failed to export CSV"])
            return nil
        }
    }

    func exportOverviewCSV() -> URL? {
        var lines: [String] = []
        lines.append("Inventory Summary")
        for status in Status.allCases {
            let count = statusCounts[status] ?? 0
            lines.append("\(status.label),\(count)")
        }
        lines.append("\(Strings.reports.totalValue),\(totalValue)")
        lines.append("")
        lines.append("Items by Room")
        for room in roomCounts.keys.sorted(by: { $0.label < $1.label }) {
            let count = roomCounts[room] ?? 0
            lines.append("\(room.label),\(count)")
        }

        let csv = lines.joined(separator: "\n")
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("overview.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            Logger.log(error, extra: ["description": "Failed to export overview CSV"])
            return nil
        }
    }
}
