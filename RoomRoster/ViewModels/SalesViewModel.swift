import SwiftUI

@MainActor
final class SalesViewModel: ObservableObject {
    @Published var sales: [Sale] = []
    @Published var errorMessage: String? = nil

    private let salesService: SalesService

    init(salesService: SalesService = .init()) {
        self.salesService = salesService
    }

    func loadSales() async {
        do {
            sales = try await salesService.fetchSales()
        } catch {
            Logger.log(error, extra: ["description": "Failed to load sales"])
            errorMessage = Strings.sales.failedToLoad
        }
    }
}
