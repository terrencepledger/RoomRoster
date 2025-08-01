import SwiftUI

@MainActor
final class EditSaleViewModel: ObservableObject {
    @Published var sale: Sale
    let originalReceiptImageURL: String?
    let originalReceiptPDFURL: String?
    @Published var pickedReceiptImage: PlatformImage?
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
        self.originalReceiptImageURL = sale.receiptImageURL
        self.originalReceiptPDFURL = sale.receiptPDFURL
        self.saleService = saleService
        self.receiptService = receiptService
    }

    func refreshSale() async {
        do {
            if let fetched = try await saleService.fetchSale(for: sale.itemId) {
                sale = fetched
            }
        } catch {
            Logger.log(error, extra: ["description": "Failed to refresh sale in edit view"])
        }
    }

    func onReceiptPicked(_ image: PlatformImage?) {
        pickedReceiptImage = image
    }

    func onReceiptPDFPicked(_ url: URL?) {
        pickedReceiptPDF = url
    }

    private func uploadImage(_ image: PlatformImage) async {
        isUploading = true
        uploadError = nil
        do {
            let url = try await receiptService.uploadReceipt(image: image, for: sale.itemId)
            sale.receiptImageURL = url.absoluteString
        } catch {
            uploadError = Strings.purchaseReceipt.errors.uploadFailed(error.localizedDescription)
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
            uploadError = Strings.purchaseReceipt.errors.uploadFailed(error.localizedDescription)
            HapticManager.shared.error()
        }
        isUploading = false
    }

    func saveUpdates() async throws {
        if let image = pickedReceiptImage {
            await uploadImage(image)
        }
        if let url = pickedReceiptPDF {
            await uploadPDF(url)
        }
        try await saleService.updateSale(sale)
    }
}
