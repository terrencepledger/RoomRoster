//
//  EditItemView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

private typealias l10n = Strings.editItem

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: MainMenuCoordinator
    @EnvironmentObject var inventoryVM: InventoryViewModel
    @StateObject private var viewModel: EditItemViewModel
    var onSave: (Item) -> Void
    var onCancel: (() -> Void)? = nil

    @State private var propertyTagInput: String
    @State private var tagError: String? = nil
    @State private var showScanner = false
    @State private var showingAddRoomPrompt = false
    @State private var newRoomName = ""
    @FocusState private var tagFieldFocused: Bool
#if os(macOS)
    private let fieldWidth: CGFloat = 240.0
#endif

    init(editableItem: Item, onSave: @escaping (Item) -> Void, onCancel: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditItemViewModel(item: editableItem))
        self.onSave = onSave
        self.onCancel = onCancel
        _propertyTagInput = State(initialValue: editableItem.propertyTagRange?.stringValue() ?? editableItem.propertyTag?.rawValue ?? "")
    }

    private func close() {
        if let onCancel { onCancel() } else { dismiss() }
    }

    var body: some View {
        NavigationStack { content }
            .macSheetFrame()
            .onChange(of: coordinator.selectedTab) { _ in
                close()
            }
    }

    private var content: some View {
        ZStack(alignment: .bottom) {
            Form {
                // MARK: – Photo Section
                Section(header: Text(l10n.photo.title).font(.headline)) {
                    HStack(spacing: 8) {
                        VStack {
                            RemoteImageView(urlString: viewModel.editableItem.imageURL, height: 80)
                            Text(l10n.photo.current)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            CombinedImagePickerButton(image: $viewModel.pickedImage, height: 80)
                            Text(l10n.photo.new)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    // Upload status & URL display
                    if viewModel.isUploading {
                        HStack {
                            ProgressView()
                            Text(l10n.photo.loading)
                        }
                    }
                    if let error = viewModel.uploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // MARK: – Purchase Receipt
                Section(header: Text(Strings.purchaseReceipt.sectionTitle).font(.headline)) {
                    HStack(spacing: 8) {
                        VStack {
                            ReceiptImageView(urlString: viewModel.editableItem.purchaseReceiptURL, height: 80)
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
                        Text(viewModel.editableItem.purchaseReceiptURL ?? "")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                            .padding(.trailing, 4)
                    }
                }

                // MARK: – Basic Information
                Section(header: Text(l10n.basicInfo.title).font(.headline)) {
#if os(macOS)
                    LabeledContent {
                        TextField(l10n.basicInfo.enter.name, text: $viewModel.editableItem.name)
                            .frame(width: fieldWidth)
                            .padding(.trailing, 4)
                    } label: {
                        Text(l10n.basicInfo.name)
                            .padding(.leading, 4)
                    }
                    LabeledContent {
                        TextField(l10n.basicInfo.enter.description, text: $viewModel.editableItem.description)
                            .frame(width: fieldWidth)
                            .padding(.trailing, 4)
                    } label: {
                        Text(l10n.basicInfo.description)
                            .padding(.leading, 4)
                    }
                    quantityField
                    LabeledContent {
                        TextField(l10n.basicInfo.enter.tag, text: $propertyTagInput)
                            .focused($tagFieldFocused)
                            .frame(width: fieldWidth)
                            .padding(.trailing, 28)
                            .overlay(alignment: .trailing) {
                                scanButton
                                    .padding(.trailing, 4)
                            }
                            .onChange(of: tagFieldFocused) { focused in
                                if !focused {
                                    withAnimation { validateTag() }
                                }
                            }
                    } label: {
                        Text(l10n.basicInfo.tag)
                            .padding(.leading, 4)
                    }
                    if let error = tagError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                    withAnimation {
                                        if tagError != nil {
                                            if !tagFieldFocused {
                                                propertyTagInput = viewModel.editableItem.propertyTagRange?.stringValue() ?? viewModel.editableItem.propertyTag?.label ?? ""
                                            }
                                            validateTag()
                                        }
                                    }
                                }
                            }
                    }
#else
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.basicInfo.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.basicInfo.enter.name, text: $viewModel.editableItem.name)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.basicInfo.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.basicInfo.enter.description, text: $viewModel.editableItem.description)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                    }
                    quantityField
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.basicInfo.tag)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.basicInfo.enter.tag, text: $propertyTagInput)
                            .focused($tagFieldFocused)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing, 28)
                            .overlay(alignment: .trailing) {
                                scanButton
                                    .padding(.trailing, 8)
                            }
                            .onChange(of: tagFieldFocused) { focused in
                                if !focused {
                                    withAnimation {
                                        validateTag()
                                    }
                                }
                            }
                        if let error = tagError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                        withAnimation {
                                            if tagError != nil {
                                                if !tagFieldFocused {
                                                    propertyTagInput = viewModel.editableItem.propertyTagRange?.stringValue() ?? viewModel.editableItem.propertyTag?.label ?? ""
                                                }
                                                validateTag()
                                            }
                                        }
                                    }
                                }
                        }
                    }
#endif
                }

                // MARK: – Details
                Section(header: Text(l10n.details.title).font(.headline)) {
#if os(macOS)
                    LabeledContent {
                        TextField(l10n.details.enter.price,
                                  value: $viewModel.editableItem.estimatedPrice,
                                  format: .number)
                            .frame(width: fieldWidth)
                            .padding(.trailing, 4)
                    } label: {
                        Text(l10n.details.price)
                            .padding(.leading, 4)
                    }
                    LabeledContent {
                        Picker(l10n.details.enter.status, selection: $viewModel.editableItem.status) {
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
                        if !inventoryVM.rooms.isEmpty {
                            Picker(l10n.details.room.subtitle, selection: $viewModel.editableItem.lastKnownRoom) {
                                ForEach(inventoryVM.rooms, id: \.id) { room in
                                    Text(room.label).tag(room)
                                }
                                Text(l10n.details.room.add).tag(Room(name: "__add_new__"))
                            }
                            .frame(width: fieldWidth)
                            .onChange(of: viewModel.editableItem.lastKnownRoom) { newValue in
                                if newValue.name == "__add_new__" {
                                    showingAddRoomPrompt = true
                                }
                            }
                        } else {
                            ProgressView(l10n.details.room.loading)
                                .frame(width: fieldWidth)
                        }
                    } label: {
                        Text(l10n.details.room.title)
                            .padding(.leading, 4)
                    }
#else
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.details.price)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.details.enter.price,
                                  value: $viewModel.editableItem.estimatedPrice,
                                  format: .number)
#if canImport(UIKit)
                            .keyboardType(.decimalPad)
#endif
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.details.status)
                             .font(.caption)
                             .foregroundColor(.gray)
                        Picker(l10n.details.enter.status, selection: $viewModel.editableItem.status) {
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
                        if !inventoryVM.rooms.isEmpty {
                            Picker(l10n.details.room.subtitle, selection: $viewModel.editableItem.lastKnownRoom) {
                                ForEach(inventoryVM.rooms, id: \.id) { room in
                                    Text(room.label).tag(room)
                                }
                                Text(l10n.details.room.add).tag(Room(name: "__add_new__"))
                            }
                            .onChange(of: viewModel.editableItem.lastKnownRoom) { newValue in
                                if newValue.name == "__add_new__" {
                                    showingAddRoomPrompt = true
                                }
                            }
                        } else {
                            ProgressView(l10n.details.room.loading)
                        }
                    }
#endif
                }

                // MARK: – Save Button
                Section {
                    Button(Strings.general.save) {
                        withAnimation {
                            validateTag()
                        }
                        guard tagError == nil else { return }
                        Task {
                            Logger.action("Pressed Save Button")
                            await viewModel.save()
                            onSave(viewModel.editableItem)
                            HapticManager.shared.success()
                            close()
                        }
                    }
                    .disabled(
                        viewModel.editableItem.name.isEmpty ||
                        viewModel.editableItem.description.isEmpty ||
                        tagError != nil ||
                        viewModel.isSaving
                    )
                    .platformButtonStyle()
                }
            }
            VStack(spacing: 4) {
                if let error = viewModel.uploadError {
                    ErrorBanner(message: error)
                }
                if let error = viewModel.receiptUploadError {
                    ErrorBanner(message: error)
                }
            }
            .allowsHitTesting(false)
            .padding()
        }
        .alert(l10n.addRoomAlert.title, isPresented: $showingAddRoomPrompt, actions: {
            TextField(l10n.addRoomAlert.placeholder, text: $newRoomName)
            Button(l10n.addRoomAlert.add) {
                Task {
                    if let newRoom = await inventoryVM.addRoom(name: newRoomName) {
                        viewModel.editableItem.lastKnownRoom = newRoom
                    } else {
                        viewModel.editableItem.lastKnownRoom = Room.placeholder()
                    }
                    newRoomName = ""
                    HapticManager.shared.success()
                }
                }
                .platformButtonStyle()
                Button(Strings.general.cancel, role: .cancel) { }
            })
            .navigationTitle(l10n.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.general.cancel) { close() }
                }
            }
        .onAppear {
            Logger.page("EditItemView")
            // Initialized in init
        }
        .task {
            await inventoryVM.fetchInventory()
        }
        .task {
            await inventoryVM.loadRooms()
        }
#if os(iOS)
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView { code in
                propertyTagInput = code
                validateTag()
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
            Stepper(value: $viewModel.editableItem.quantity, in: 1...Int.max) {
                Text("\(viewModel.editableItem.quantity)")
                    .frame(width: 40, alignment: .trailing)
            }
            .frame(width: fieldWidth)
            .padding(.trailing, 4)
        } label: {
            Text(l10n.basicInfo.quantity)
                .padding(.leading, 4)
        }
        .onChange(of: viewModel.editableItem.quantity) { _ in
            validateTag()
        }
    }
#else
    @ViewBuilder
    private var quantityField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(l10n.basicInfo.quantity)
                .font(.caption)
                .foregroundColor(.gray)
            Stepper(value: $viewModel.editableItem.quantity, in: 1...Int.max) {
                Text("\(viewModel.editableItem.quantity)")
            }
            .padding(.trailing)
        }
        .onChange(of: viewModel.editableItem.quantity) { _ in
            validateTag()
        }
    }
#endif

    private func validateTag() {
        if propertyTagInput.isEmpty {
            viewModel.editableItem.propertyTag = nil
            viewModel.editableItem.propertyTagRange = nil
            tagError = nil
            return
        }
        if propertyTagInput == (viewModel.editableItem.propertyTagRange?.stringValue() ?? viewModel.editableItem.propertyTag?.label) {
            tagError = nil
            return
        }

        do {
            let tags = try ItemValidator.validateTags(
                propertyTagInput,
                quantity: viewModel.editableItem.quantity,
                currentItemID: viewModel.editableItem.id,
                allItems: inventoryVM.items
            )
            if tags.count == 1 {
                viewModel.editableItem.propertyTag = tags[0]
                viewModel.editableItem.propertyTagRange = nil
            } else {
                viewModel.editableItem.propertyTag = nil
                viewModel.editableItem.propertyTagRange = PropertyTagRange(tags: tags)
            }
            tagError = nil
        } catch {
            viewModel.editableItem.propertyTag = nil
            viewModel.editableItem.propertyTagRange = nil
            if let validationError = error as? ItemValidationError {
                switch validationError {
                case .invalidTagFormat:
                    tagError = l10n.errors.tag.format
                case .duplicateTag:
                    tagError = l10n.errors.tag.duplicate
                case .quantityMismatch:
                    tagError = l10n.errors.tag.quantityMismatch
                default:
                    tagError = nil
                }
            } else {
                tagError = nil
            }
        }
    }
}
