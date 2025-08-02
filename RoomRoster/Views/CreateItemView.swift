import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private typealias l10n = Strings.createItem

struct CreateItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CreateItemViewModel
    var onCancel: (() -> Void)? = nil

    private func close() {
        if let onCancel { onCancel() } else { dismiss() }
    }

    @FocusState private var tagFieldFocused: Bool

    var body: some View {
#if os(macOS)
        content.macSheetFrame()
#else
        NavigationStack { content }
            .macSheetFrame()
#endif
    }

    private var content: some View {
        ZStack(alignment: .bottom) {
            formContent
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .allowsHitTesting(false)
                    .padding()
            }
        }
        .alert(l10n.addRoom.title, isPresented: $viewModel.showingAddRoomPrompt) {
            TextField(l10n.addRoom.placeholder, text: $viewModel.newRoomName)
            Button(l10n.addRoom.button) { Task { await viewModel.addRoom() } }
                .platformButtonStyle()
            Button(Strings.general.cancel, role: .cancel) { }
        }
        .navigationTitle(l10n.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Strings.general.cancel) { close() }
            }
        }
        .onAppear {
            Task { await viewModel.signIn() }
            Task { await viewModel.loadRooms() }
            Logger.page("CreateItemView")
        }
    }

    private var formContent: some View {
        Form {
            photoSection
            receiptSection
            basicInfoSection
            detailsSection
            Section {
                Button(Strings.general.save) {
                    Task {
                        await viewModel.saveItem()
                        if viewModel.errorMessage == nil {
                            HapticManager.shared.success()
                            close()
                        }
                    }
                }
                .disabled(
                    viewModel.newItem.name.isEmpty ||
                    viewModel.newItem.description.isEmpty ||
                    viewModel.tagError != nil ||
                    viewModel.newItem.lastKnownRoom == Room.placeholder()
                )
                .platformButtonStyle()
            }
        }
    }

    private var photoSection: some View {
        Section(header: Text(l10n.photo)) {
            CombinedImagePickerButton(image: $viewModel.pickedImage)
                .onChange(of: viewModel.pickedImage) { _, img in
                    viewModel.onImagePicked(img)
                }
            if viewModel.isUploading {
                HStack {
                    ProgressView()
                    Text(l10n.uploadingImage)
                }
            }
            if let error = viewModel.uploadError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            HStack {
                Text(l10n.imageURL)
                    .foregroundColor(.gray)
                Spacer()
                Text(viewModel.newItem.imageURL)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var receiptSection: some View {
        Section(header: Text("Purchase Receipt")) {
            ReceiptImageView(urlString: viewModel.newItem.purchaseReceiptURL)
            CombinedImagePickerButton(image: $viewModel.pickedReceiptImage)
                .onChange(of: viewModel.pickedReceiptImage) { _, img in
                    viewModel.onReceiptPicked(img)
                }
            PDFPickerButton(url: $viewModel.pickedReceiptPDF)
                .onChange(of: viewModel.pickedReceiptPDF) { _, url in
                    viewModel.onReceiptPDFPicked(url)
                }
            if viewModel.isUploadingReceipt {
                HStack {
                    ProgressView()
                    Text("Uploading receipt...")
                }
            }
            if let error = viewModel.receiptUploadError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            HStack {
                Text("Receipt Path")
                    .foregroundColor(.gray)
                Spacer()
                Text(viewModel.newItem.purchaseReceiptURL ?? "")
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var basicInfoSection: some View {
        Section(header: Text(l10n.basicInfo.title)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.basicInfo.name)
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField(l10n.basicInfo.enter.name, text: $viewModel.newItem.name)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.basicInfo.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField(l10n.basicInfo.enter.description, text: $viewModel.newItem.description)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.basicInfo.quantity)
                    .font(.caption)
                    .foregroundColor(.gray)
                Stepper(value: $viewModel.newItem.quantity, in: 1...Int.max) {
                    Text("\(viewModel.newItem.quantity)")
                }
                .onChange(of: viewModel.newItem.quantity) { _, _ in
                    viewModel.validateTag()
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.basicInfo.tag)
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField(l10n.basicInfo.enter.tag, text: $viewModel.propertyTagInput)
                    .focused($tagFieldFocused)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: tagFieldFocused) { _, focused in
                        if !focused { withAnimation { viewModel.validateTag() } }
                    }
                if viewModel.showTagError, let error = viewModel.tagError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation {
                                    if (viewModel.tagError?.count ?? 0) > 0 {
                                        if !tagFieldFocused {
                                            viewModel.propertyTagInput = ""
                                        }
                                        viewModel.validateTag()
                                    }
                                }
                            }
                        }
                }
            }
        }
    }

    private var detailsSection: some View {
        Section(header: Text(l10n.details.title)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.details.price)
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField(
                    l10n.details.enter.price,
                    value: $viewModel.newItem.estimatedPrice,
                    format: .number
                )
#if canImport(UIKit)
                .keyboardType(.decimalPad)
#endif
                .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.details.status)
                    .font(.caption)
                    .foregroundColor(.gray)
                Picker(l10n.details.status, selection: $viewModel.newItem.status) {
                    ForEach(Status.allCases, id: \.self) { status in
                        Text(status.label).tag(status)
                    }
                }
                .pickerStyle(.menu)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(l10n.details.room.title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Picker(l10n.details.enter.room, selection: $viewModel.newItem.lastKnownRoom) {
                    if viewModel.newItem.lastKnownRoom == Room.placeholder() {
                        Text(l10n.details.enter.room).tag(Room.placeholder())
                    }
                    ForEach(viewModel.rooms, id: \.self) { room in
                        Text(room.label).tag(room)
                    }
                    Text(l10n.details.room.add)
                        .foregroundColor(.blue)
                        .tag(Room(name: "__add_new__"))
                }
                .onChange(of: viewModel.newItem.lastKnownRoom) { _, newValue in
                    if newValue.name == "__add_new__" {
                        viewModel.showingAddRoomPrompt = true
                    }
                }
            }
        }
    }
}
