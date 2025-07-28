import SwiftUI

private typealias l10n = Strings.saleDetails

struct SalesDetailsView: View {
    let sale: Sale
    let itemName: String
    @State private var showingEdit = false
    @State private var editableSale = Sale(
        itemId: "",
        date: Date(),
        price: nil,
        condition: .new,
        buyerName: "",
        buyerContact: nil,
        soldBy: "",
        department: "",
        receiptImageURL: nil,
        receiptPDFURL: nil
    )
    @State private var shareURL: URL?
    @State private var errorMessage: String?
    private let downloader = FileDownloadService()

    var body: some View {
        List {
            Section {
                row(l10n.date, sale.date.toShortString())
                if let price = sale.price {
                    row(l10n.price, String(format: "$%.2f", price))
                }
                row(l10n.condition, sale.condition.label)
                row(l10n.buyerName, sale.buyerName)
                row(l10n.buyerContact, sale.buyerContact ?? "")
                row(l10n.soldBy, sale.soldBy)
                row(l10n.department, sale.department)
            }
            if sale.receiptImageURL != nil || sale.receiptPDFURL != nil {
                Section(l10n.receiptSection) {
                    ReceiptImageView(urlString: sale.receiptImageURL)
                    if let imgURLString = sale.receiptImageURL,
                       let url = URL(string: imgURLString) {
                        Button(Strings.itemDetails.downloadImage) {
                            Task {
                                do {
                                    shareURL = try await downloader.download(from: url)
                                    HapticManager.shared.success()
                                } catch {
                                    errorMessage = Strings.itemDetails.downloadFailed
                                    HapticManager.shared.error()
                                }
                            }
                        }
                        .platformButtonStyle()
                    }
                    if let pdf = sale.receiptPDFURL,
                       let url = URL(string: pdf) {
                        Button(Strings.itemDetails.downloadReceipt) {
                            Task {
                                do {
                                    shareURL = try await downloader.download(from: url)
                                    HapticManager.shared.success()
                                } catch {
                                    errorMessage = Strings.itemDetails.downloadFailed
                                    HapticManager.shared.error()
                                }
                            }
                        }
                        .platformButtonStyle()
                    }
                }
            }
        }
        .navigationTitle(itemName)
        .overlay {
            if let errorMessage {
                VStack { Spacer(); ErrorBanner(message: errorMessage) }
            }
        }
        .toolbar {
            Button(l10n.editButton) {
                editableSale = sale
                showingEdit = true
            }
        }
        .platformPopup(isPresented: $showingEdit) {
            EditSaleView(viewModel: EditSaleViewModel(sale: editableSale)) { updated in
                editableSale = updated
            }
        }
        .sheet(item: $shareURL) { url in
            ShareSheet(activityItems: [url])
        }
    }

    @ViewBuilder
    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).bold()
            Spacer()
            Text(value)
        }
    }
}
