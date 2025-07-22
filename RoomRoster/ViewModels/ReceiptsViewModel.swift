import Foundation

@MainActor
final class ReceiptsViewModel: ObservableObject {
    private let service: ReceiptService
    @Published var receipts: [Receipt] = []

    init(service: ReceiptService = ReceiptService()) {
        self.service = service
    }

    func loadReceipts() async {
        receipts = await service.allReceipts()
    }
}
