import SwiftUI

struct EditSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: EditSaleViewModel
    var onSave: (Sale) -> Void

    var body: some View {
#if os(macOS)
        content
#else
        NavigationStack { content }
#endif
    }

    private var content: some View {
        Form {
                Section("Sale Receipt") {
                    ReceiptImageView(urlString: viewModel.sale.receiptImageURL)
                    CombinedImagePickerButton(image: $viewModel.pickedReceiptImage)
                        .onChange(of: viewModel.pickedReceiptImage) { _, img in
                            viewModel.onReceiptPicked(img)
                        }
                    PDFPickerButton(url: $viewModel.pickedReceiptPDF)
                        .onChange(of: viewModel.pickedReceiptPDF) { _, url in
                            viewModel.onReceiptPDFPicked(url)
                        }
                    if viewModel.isUploading {
                        HStack {
                            ProgressView()
                            Text("Uploading receipt...")
                        }
                    }
                    if let error = viewModel.uploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(Strings.saleDetails.editTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                try await viewModel.saveUpdates()
                                onSave(viewModel.sale)
                                dismiss()
                            } catch {
                                HapticManager.shared.error()
                            }
                        }
                    }
                    .platformButtonStyle()
                }
            }
        }
    }
