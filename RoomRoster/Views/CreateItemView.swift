import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private typealias l10n = Strings.createItem

struct CreateItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CreateItemViewModel
    var onCancel: (() -> Void)? = nil
    @EnvironmentObject private var inventory: InventoryViewModel

    private func close() {
        if let onCancel { onCancel() } else { dismiss() }
    }

    @FocusState private var tagFieldFocused: Bool
    @State private var successMessage: String?
    @State private var showScanner = false
#if os(macOS)
    private let fieldWidth: CGFloat = 240.0
#endif

    var body: some View {
#if os(macOS)
        content
            .macSheetFrame()
            .overlay {
                VStack {
                    Spacer()
                    bannerStack
                }
                .allowsHitTesting(false)
            }
#else
        NavigationStack { content }
            .macSheetFrame()
            .overlay {
                VStack {
                    Spacer()
                    bannerStack
                }
                .allowsHitTesting(false)
            }
#endif
    }

    private var content: some View {
        Form {
            Section {
                CombinedImagePickerButton(image: $viewModel.pickedImage, height: 80)
                    .onChange(of: viewModel.pickedImage) { img in
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
                    Text(l10n.imageURL).foregroundColor(.gray)
                        .padding(.leading, 4)
                    Spacer()
                    Text(viewModel.newItem.imageURL)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 4)
                }
            } header: {
                Text(l10n.photo)
                    .font(.headline)
            }

            Section {
                HStack(spacing: 8) {
                    ReceiptImageView(urlString: viewModel.newItem.purchaseReceiptURL, height: 80)
                    CombinedImagePickerButton(image: $viewModel.pickedReceiptImage, height: 80)
                }
                .onChange(of: viewModel.pickedReceiptImage) { img in
                    viewModel.onReceiptPicked(img)
                }

                PDFPickerButton(url: $viewModel.pickedReceiptPDF)
                    .onChange(of: viewModel.pickedReceiptPDF) { url in
                        viewModel.onReceiptPDFPicked(url)
                    }

                if viewModel.isUploadingReceipt {
                    HStack {
                        ProgressView()
                        Text(Strings.general.uploadingReceipt)
                    }
                }

                if let error = viewModel.receiptUploadError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                HStack {
                    Text(Strings.general.receiptPath).foregroundColor(.gray)
                        .padding(.leading, 4)
                    Spacer()
                    Text(viewModel.newItem.purchaseReceiptURL ?? "")
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 4)
                }
            } header: {
                Text(Strings.purchaseReceipt.sectionTitle)
                    .font(.headline)
            }

            Section {
#if os(macOS)
                LabeledContent {
                    TextField(l10n.basicInfo.enter.name, text: $viewModel.newItem.name)
                        .frame(width: fieldWidth)
                        .padding(.trailing, 4)
                } label: {
                    Text(l10n.basicInfo.name)
                        .padding(.leading, 4)
                }

                LabeledContent {
                    TextField(l10n.basicInfo.enter.description, text: $viewModel.newItem.description)
                        .frame(width: fieldWidth)
                        .padding(.trailing, 4)
                } label: {
                    Text(l10n.basicInfo.description)
                        .padding(.leading, 4)
                }

                quantityField

                LabeledContent {
                    TextField(l10n.basicInfo.enter.tag, text: $viewModel.propertyTagInput)
                        .focused($tagFieldFocused)
                        .frame(width: fieldWidth)
                        .padding(.trailing, 28)
                        .overlay(alignment: .trailing) {
                            scanButton
                                .padding(.trailing, 4)
                        }
                        .onChange(of: tagFieldFocused) { focused in
                            if !focused {
                                withAnimation { viewModel.validateTag() }
                            }
                        }
                } label: {
                    Text(l10n.basicInfo.tag)
                        .padding(.leading, 4)
                }
#else
                HStack {
                    Text(l10n.basicInfo.name)
                    Spacer()
                    TextField(l10n.basicInfo.enter.name, text: $viewModel.newItem.name)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing)
                }

                HStack {
                    Text(l10n.basicInfo.description)
                    Spacer()
                    TextField(l10n.basicInfo.enter.description, text: $viewModel.newItem.description)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing)
                }

                quantityField

                HStack {
                    Text(l10n.basicInfo.tag)
                    Spacer()
                    TextField(l10n.basicInfo.enter.tag, text: $viewModel.propertyTagInput)
                        .focused($tagFieldFocused)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 28)
                        .overlay(alignment: .trailing) {
                            scanButton
                        }
                        .onChange(of: tagFieldFocused) { focused in
                            if !focused {
                                withAnimation { viewModel.validateTag() }
                            }
                        }
                }
#endif

                if viewModel.showTagError, let error = viewModel.tagError {
                    HStack {
                        Spacer()
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
            } header: {
                Text(l10n.basicInfo.title)
                    .font(.headline)
            }

            #if os(macOS)
            Section {
                LabeledContent {
                    TextField(
                        l10n.details.enter.price,
                        value: $viewModel.newItem.estimatedPrice,
                        format: .number
                    )
                    .frame(width: fieldWidth)
                    .padding(.trailing, 4)
                } label: {
                    Text(l10n.details.price)
                        .padding(.leading, 4)
                }

                LabeledContent {
                    Picker(l10n.details.enter.status, selection: $viewModel.newItem.status) {
                        ForEach(Status.allCases, id: \.self) { status in
                            Text(status.label).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: fieldWidth)
                    .padding(.trailing, 4)
                } label: {
                    Text(l10n.details.status)
                        .padding(.leading, 4)
                }

                LabeledContent {
                    if viewModel.rooms.isEmpty {
                        ProgressView()
                            .frame(width: fieldWidth)
                    } else {
                        Picker("Room", selection: Binding<Room>(
                            get: { viewModel.newItem.lastKnownRoom },
                            set: { viewModel.newItem.lastKnownRoom = $0 }
                        )) {
                            Text("Placeholder").tag(Room.placeholder())
                            ForEach(viewModel.rooms, id: \.id) { room in
                                Text(room.label).tag(room)
                            }
                            Text("Add new room").tag(Room(name: "__add_new__"))
                        }
                        .frame(width: fieldWidth)
                        .padding(.trailing, 4)
                        .onChange(of: viewModel.newItem.lastKnownRoom) { newValue in
                            if newValue.name == "__add_new__" {
                                viewModel.showingAddRoomPrompt = true
                            }
                        }
                    }
                } label: {
                    Text(l10n.details.room.title)
                        .padding(.leading, 4)
                }
            } header: {
                Text(l10n.details.title)
                    .font(.headline)
            }
            #else
            Section {
                HStack {
                    Text(l10n.details.price)
                    Spacer()
                    TextField(
                        l10n.details.enter.price,
                        value: $viewModel.newItem.estimatedPrice,
                        format: .number
                    )
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing)
                }

                Picker(l10n.details.status, selection: $viewModel.newItem.status) {
                    ForEach(Status.allCases, id: \.self) { status in
                        Text(status.label).tag(status)
                    }
                }

                if viewModel.rooms.isEmpty {
                    ProgressView()
                } else {
                    Picker(l10n.details.room.title, selection: $viewModel.newItem.lastKnownRoom) {
                        if viewModel.newItem.lastKnownRoom == Room.placeholder() {
                            Text(l10n.details.enter.room).tag(Room.placeholder())
                        }
                        ForEach(viewModel.rooms, id: \.id) { room in
                            Text(room.label).tag(room)
                        }
                        Text(l10n.details.room.add)
                            .foregroundColor(.blue)
                            .tag(Room(name: "__add_new__"))
                    }
                    .onChange(of: viewModel.newItem.lastKnownRoom) { newValue in
                        if newValue.name == "__add_new__" {
                            viewModel.showingAddRoomPrompt = true
                        }
                    }
                }
            } header: {
                Text(l10n.details.title)
                    .font(.headline)
            }
            #endif

            Button(Strings.general.save) {
                Task {
                    await viewModel.saveItem()
                    if viewModel.errorMessage == nil {
                        withAnimation { successMessage = l10n.success }
                        HapticManager.shared.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { successMessage = nil }
                            close()
                        }
                    }
                }
            }
            .disabled(
                viewModel.isSaving ||
                viewModel.newItem.name.isEmpty ||
                viewModel.newItem.description.isEmpty ||
                viewModel.tagError != nil ||
                viewModel.newItem.lastKnownRoom == Room.placeholder()
            )
            .platformButtonStyle()
        }
        .alert(
            l10n.addRoom.title,
            isPresented: $viewModel.showingAddRoomPrompt,
            actions: {
                TextField(
                    l10n.addRoom.placeholder,
                    text: $viewModel.newRoomName
                )
                Button(l10n.addRoom.button) {
                    Task {
                        if let newRoom = await viewModel.addRoom() {
                            inventory.rooms.append(newRoom)
                        }
                    }
                }
                .platformButtonStyle()
                Button(Strings.general.cancel, role: .cancel) { }
            }
        )
        .navigationTitle(l10n.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Strings.general.cancel) { close() }
            }
        }
        .onAppear {
            viewModel.rooms = inventory.rooms
            Logger.page("CreateItemView")
        }
        .onChange(of: inventory.rooms) { newRooms in
            viewModel.rooms = newRooms
        }
#if os(iOS)
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView { code in
                viewModel.propertyTagInput = code
                viewModel.validateTag()
                showScanner = false
            }
        }
#endif
    }

    private var scanButton: some View {
        #if os(iOS)
        Button {
            showScanner = true
        } label: {
            Image(systemName: "barcode.viewfinder")
        }
        #else
        EmptyView()
        #endif
    }

#if os(macOS)
    private var quantityField: some View {
        LabeledContent {
            Stepper(value: $viewModel.newItem.quantity, in: 1...Int.max) {
                Text("\(viewModel.newItem.quantity)")
                    .frame(width: 40, alignment: .trailing)
            }
            .frame(width: fieldWidth)
            .padding(.trailing, 4)
        } label: {
            Text(l10n.basicInfo.quantity)
                .padding(.leading, 4)
        }
        .onChange(of: viewModel.newItem.quantity) { _ in
            viewModel.validateTag()
        }
    }
#else
    @ViewBuilder
    private var quantityField: some View {
        Stepper(value: $viewModel.newItem.quantity, in: 1...Int.max) {
            HStack {
                Text(l10n.basicInfo.quantity)
                Spacer()
                Text("\(viewModel.newItem.quantity)")
            }
        }
        .padding(.trailing)
        .onChange(of: viewModel.newItem.quantity) { _ in
            viewModel.validateTag()
        }
    }
#endif

    private var bannerStack: some View {
        VStack(spacing: 4) {
            if let message = successMessage {
                SuccessBanner(message: message)
            }
            if let error = viewModel.uploadError {
                ErrorBanner(message: error)
            }
            if let error = viewModel.receiptUploadError {
                ErrorBanner(message: error)
            }
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
        }
        .padding()
    }
}

