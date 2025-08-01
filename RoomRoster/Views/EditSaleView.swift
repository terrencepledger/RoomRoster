import SwiftUI

struct EditSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditSaleViewModel
    var onSave: (Sale) -> Void

    @State private var saveError: String?

    var body: some View {
        content
            .navigationTitle(Strings.saleDetails.editTitle)
            .overlay {
                if let saveError {
                    VStack { Spacer(); ErrorBanner(message: saveError) }
                        .allowsHitTesting(false)
                }
            }
    }

    private var content: some View {
        Form {
                Section(Strings.purchaseReceipt.saleSectionTitle) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.saleDetails.currentReceipt)
                            .font(.caption)
                            .foregroundColor(.gray)
                        ReceiptImageView(
                            urlString: viewModel.sale.receiptImageURL ??
                                viewModel.sale.receiptPDFURL ??
                                viewModel.originalReceiptImageURL ??
                                viewModel.originalReceiptPDFURL
                        )
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.saleDetails.newReceipt)
                            .font(.caption)
                            .foregroundColor(.gray)
                        CombinedImagePickerButton(image: $viewModel.pickedReceiptImage)
                        PDFPickerButton(url: $viewModel.pickedReceiptPDF)
                    }
                    if viewModel.isUploading {
                        HStack {
                            ProgressView()
                            Text(Strings.general.uploadingReceipt)
                        }
                    }
                    if let error = viewModel.uploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

            Section {
                Button(Strings.general.save) {
                    Task {
                        do {
                            try await viewModel.saveUpdates()
                            onSave(viewModel.sale)
                            dismiss()
                        } catch {
                            saveError = Strings.saleDetails.failedToUpdate
                            HapticManager.shared.error()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation { saveError = nil }
                            }
                        }
                    }
                }
                .platformButtonStyle()
            }
            .task { await viewModel.refreshSale() }
        }
    }
    }
