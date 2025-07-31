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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.saleDetails.currentReceipt)
                            .font(.caption)
                            .foregroundColor(.gray)
                        ReceiptImageView(urlString: viewModel.originalReceiptImageURL)
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
