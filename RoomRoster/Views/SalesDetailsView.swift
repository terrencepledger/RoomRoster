import SwiftUI

private typealias l10n = Strings.saleDetails

struct SalesDetailsView: View {
    @State var sale: Sale
    let itemName: String
#if os(macOS)
    var openEdit: ((Sale) -> Void)? = nil
#endif

    init(sale: Sale, itemName: String
#if os(macOS)
         , openEdit: ((Sale) -> Void)? = nil
#endif
    ) {
        _sale = State(initialValue: sale)
        self.itemName = itemName
#if os(macOS)
        self.openEdit = openEdit
#endif
    }
    @State private var shareURL: URL?
    @State private var errorMessage: String?
#if !os(macOS)
    @State private var editSuccess: String?
    @State private var isEditing = false
#endif
    private let downloader = FileDownloadService()

    var body: some View {
#if os(macOS)
        content
#else
        NavigationStack { content }
            .navigationDestination(isPresented: $isEditing) { editSaleView }
#endif
    }

    private var content: some View {
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
            Section { 
                ReceiptImageView(urlString: sale.receiptImageURL)
                if let imgURLString = sale.receiptImageURL,
                   !imgURLString.isEmpty,
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
                   !pdf.isEmpty,
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
            } header: {
                Text(l10n.receiptSection)
                    .font(.headline)
            }
        }
        .navigationTitle(itemName)
        .overlay {
            if let errorMessage {
                VStack { Spacer(); ErrorBanner(message: errorMessage) }
                    .allowsHitTesting(false)
            }
#if !os(macOS)
            if let message = editSuccess {
                VStack { Spacer(); SuccessBanner(message: message) }
                    .allowsHitTesting(false)
            }
#endif
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(l10n.editButton) {
#if os(macOS)
                    openEdit?(sale)
#else
                    isEditing = true
#endif
                }
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

    private var editSaleView: some View {
        EditSaleView(viewModel: EditSaleViewModel(sale: sale)) { updated in
            sale = updated
#if !os(macOS)
            editSuccess = Strings.saleDetails.editSuccess
            HapticManager.shared.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { editSuccess = nil }
            }
#endif
        }
    }
}
