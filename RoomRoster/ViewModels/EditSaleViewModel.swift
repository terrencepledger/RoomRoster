import SwiftUI

@MainActor
final class EditSaleViewModel: ObservableObject {
    @Published var sale: Sale
    @Published var pickedReceiptImage: UIImage?
    @Published var pickedReceiptPDF: URL?
    @Published var isUploading: Bool = false
    @Published var uploadError: String?

    private let saleService: SalesService
    private let receiptService: SaleReceiptService

    init(
        sale: Sale,
        saleService: SalesService = .init(),
        receiptService: SaleReceiptService = .init()
    ) {
        self.sale = sale
        self.saleService = saleService
        self.receiptService = receiptService
    }

    func onReceiptPicked(_ image: UIImage?) {
        pickedReceiptImage = image
        guard let image else { return }
        Task { await uploadImage(image) }
    }

    func onReceiptPDFPicked(_ url: URL?) {
        pickedReceiptPDF = url
        guard let url else { return }
        Task { await uploadPDF(url) }
    }

    private func uploadImage(_ image: UIImage) async {
        isUploading = true
        uploadError = nil
        do {
            let url = try await receiptService.uploadReceipt(image: image, for: sale.itemId)
            sale.receiptImageURL = url.absoluteString
        } catch {
            uploadError = error.localizedDescription
            HapticManager.shared.error()
        }
        isUploading = false
    }

    private func uploadPDF(_ url: URL) async {
        isUploading = true
        uploadError = nil
        do {
            let data = try Data(contentsOf: url)
            let saved = try await receiptService.uploadReceiptPDF(data, for: sale.itemId)
            sale.receiptPDFURL = saved.absoluteString
        } catch {
            uploadError = error.localizedDescription
            HapticManager.shared.error()
        }
        isUploading = false
    }

    func saveUpdates() async throws {
        try await saleService.updateSale(sale)
    }
}
