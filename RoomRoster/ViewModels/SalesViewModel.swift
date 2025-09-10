import SwiftUI

@MainActor
final class SalesViewModel: ObservableObject {
    @Published var sales: [Sale] = []
    @Published var errorMessage: String? = nil
    @Published private(set) var itemsById: [String: Item] = [:]

    private let salesService: SalesService
    private let inventoryService: InventoryService

    init(
        salesService: SalesService = .init(),
        inventoryService: InventoryService = .init()
    ) {
        self.salesService = salesService
        self.inventoryService = inventoryService
    }

    func loadSales() async {
        errorMessage = nil
        do {
            itemsById = [:]
            sales = try await salesService.fetchSales()
            for sale in sales {
                if let item = try? await inventoryService.fetchItem(withId: sale.itemId) {
                    itemsById[sale.itemId] = item
                }
            }
        } catch {
            Logger.log(error, extra: ["description": "Failed to load sales"])
            errorMessage = Strings.sales.failedToLoad
            HapticManager.shared.error()
        }
    }

    func itemName(for sale: Sale) -> String {
        itemsById[sale.itemId]?.name ?? Strings.general.loading
    }

    func filteredSales(
        query: String,
        dateRange: DateInterval?,
        minPrice: Double?,
        maxPrice: Double?
    ) -> [Sale] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return sales.filter { sale in
            if !q.isEmpty {
                let name = itemName(for: sale).lowercased()
                if !name.contains(q) { return false }
            }
            if let range = dateRange {
                if !range.contains(sale.date) { return false }
            }
            if let min = minPrice {
                guard let price = sale.price, price >= min else { return false }
            }
            if let max = maxPrice {
                guard let price = sale.price, price <= max else { return false }
            }
            return true
        }
    }
}
