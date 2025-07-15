import SwiftUI

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var recentLogs: [String] = []
    @Published var statusCounts: [Status: Int] = [:]
    @Published var roomCounts: [Room: Int] = [:]
    @Published var totalValue: Double = 0
    @Published var query: String = ""

    private let inventoryService: InventoryService
    init(
        inventoryService: InventoryService = .init()
    ) {
        self.inventoryService = inventoryService
    }

    func loadData() async {
        await fetchItems()
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
            let logs = sheet.values.flatMap { Array($0.dropFirst()) }
            recentLogs = Array(logs.suffix(maxEntries))
        } catch {
            Logger.log(error, extra: ["description": "Failed to fetch history for reports"])
        }
    }

    var filteredItems: [Item] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter { item in
            item.name.lowercased().contains(q) ||
            item.description.lowercased().contains(q) ||
            item.status.label.lowercased().contains(q) ||
            item.lastKnownRoom.name.lowercased().contains(q) ||
            (item.propertyTag?.label.lowercased().contains(q) ?? false)
        }
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
}
