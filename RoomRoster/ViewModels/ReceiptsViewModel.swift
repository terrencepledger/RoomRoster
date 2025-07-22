import SwiftUI

@MainActor
final class ReceiptsViewModel: ObservableObject {
    @Published var receipts: [Receipt] = []

    private let receiptService: ReceiptService

    init(receiptService: ReceiptService = .init()) {
        self.receiptService = receiptService
    }

    func loadReceipts() {
        receipts = (try? receiptService.listReceipts()) ?? []
    }
}
