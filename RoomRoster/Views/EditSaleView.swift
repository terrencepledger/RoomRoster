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
        }
    }
    }
