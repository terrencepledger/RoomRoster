import SwiftUI

struct EditSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: MainMenuCoordinator
    @StateObject var viewModel: EditSaleViewModel
    var onSave: (Sale) -> Void

    @State private var saveError: String?

    var body: some View {
        content
            .navigationTitle(Strings.saleDetails.editTitle)
            .overlay(alignment: .bottom) {
                VStack(spacing: 4) {
                    if let error = viewModel.uploadError {
                        ErrorBanner(message: error)
                    }
                    if let saveError {
                        ErrorBanner(message: saveError)
                    }
                }
                .allowsHitTesting(false)
            }
            .onChange(of: coordinator.selectedTab) { _ in
                dismiss()
            }
    }

    private var content: some View {
        Form {
                Section {
                    HStack(spacing: 8) {
                        VStack {
                            ReceiptImageView(
                                urlString: viewModel.sale.receiptImageURL ??
                                    viewModel.sale.receiptPDFURL ??
                                    viewModel.originalReceiptImageURL ??
                                    viewModel.originalReceiptPDFURL,
                                height: 80
                            )
                            Text(Strings.saleDetails.currentReceipt)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            CombinedImagePickerButton(image: $viewModel.pickedReceiptImage, height: 80)
                            Text(Strings.saleDetails.newReceipt)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    PDFPickerButton(url: $viewModel.pickedReceiptPDF)
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
                } header: {
                    Text(Strings.purchaseReceipt.saleSectionTitle)
                        .font(.headline)
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
