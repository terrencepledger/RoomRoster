import SwiftUI

@MainActor
final class SellItemViewModel: ObservableObject {
    @Published var sale = Sale(
        itemId: "",
        date: Date(),
        price: nil,
        condition: .new,
        buyerName: "",
        buyerContact: "",
        soldBy: "",
        department: ""
    )

    private let salesService: SalesService
    private let inventoryService: InventoryService

    var item: Item

    init(
        item: Item,
        salesService: SalesService = .init(),
        inventoryService: InventoryService = .init()
    ) {
        self.item = item
        self.salesService = salesService
        self.inventoryService = inventoryService
        sale.itemId = item.id
        sale.price = item.estimatedPrice
    }

    func submitSale() async throws {
        try await salesService.recordSale(sale)
        var updated = item
        updated.status = .sold
        updated.lastUpdated = Date()
        updated.updatedBy = sale.soldBy
        try await inventoryService.updateItem(updated)
        await salesService.sendReceipts(to: sale.buyerContact, sellerEmail: sale.soldBy, sale: sale)
    }
}
