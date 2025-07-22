//
//  EditItemView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import SwiftUI
import PhotosUI
import UIKit

private typealias l10n = Strings.editItem

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State var editableItem: Item
    var onSave: (Item) -> Void

    @EnvironmentObject var viewModel: InventoryViewModel

    @State private var pickedImage: UIImage?
    @State private var pickedReceiptImage: UIImage?
    @State private var pickedReceiptPDF: URL?
    @State private var isUploading = false
    @State private var isUploadingReceipt = false
    @State private var uploadError: String?
    @State private var receiptUploadError: String?
    @State private var temporaryImageURL: String?
    @State private var dateAddedDate: Date = Date()
    @State private var propertyTagInput: String = ""
    @State private var tagError: String? = nil
    @State private var showingAddRoomPrompt = false
    @State private var newRoomName = ""
    @FocusState private var tagFieldFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                // MARK: – Photo Section
                Section(header: Text(l10n.photo.title)) {
                    if let url = URL(string: editableItem.imageURL),
                            !editableItem.imageURL.isEmpty {
                        AsyncImage(url: url) { img in
                            img.resizable()
                               .scaledToFit()
                               .frame(height: 120)
                               .cornerRadius(8)
                        } placeholder: {
                            ProgressView().frame(height: 120)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 120)
                            .cornerRadius(8)
                            .overlay(Text(l10n.photo.emptyState).foregroundColor(.gray))
                    }

                    // Picker button
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.photo.enter)
                            .font(.caption)
                            .foregroundColor(.gray)
                        CombinedImagePickerButton(image: $pickedImage)
                    }

                    // Upload status & URL display
                    if isUploading {
                        HStack {
                            ProgressView()
                            Text(l10n.photo.loading)
                        }
                    }
                    if let error = uploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // MARK: – Purchase Receipt
                Section(header: Text("Purchase Receipt")) {
                    CombinedImagePickerButton(image: $pickedReceiptImage)
                        .onChange(of: pickedReceiptImage) { _, img in
                            Task { await saveReceiptImage(img) }
                        }
                    PDFPickerButton(url: $pickedReceiptPDF)
                        .onChange(of: pickedReceiptPDF) { _, url in
                            Task { await saveReceiptPDF(url) }
                        }

                    if isUploadingReceipt {
                        HStack {
                            ProgressView()
                            Text("Uploading receipt...")
                        }
                    }
                    if let error = receiptUploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    HStack {
                        Text("Receipt Path").foregroundColor(.gray)
                        Spacer()
                        Text(editableItem.purchaseReceiptURL ?? "")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // MARK: – Basic Information
                Section(header: Text(l10n.basicInfo.title)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.basicInfo.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.basicInfo.enter.name, text: $editableItem.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.basicInfo.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.basicInfo.enter.description, text: $editableItem.description)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.basicInfo.quantity)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.basicInfo.enter.quantity,
                                  value: $editableItem.quantity,
                                  format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.basicInfo.tag)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.basicInfo.enter.tag, text: $propertyTagInput)
                            .focused($tagFieldFocused)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: tagFieldFocused) { _,focused in
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
                                                    propertyTagInput = editableItem.propertyTag?.label ?? ""
                                                }
                                                validateTag()
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    
                }

                // MARK: – Details
                Section(header: Text(l10n.details.title)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.details.price)
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField(l10n.details.enter.price,
                                  value: $editableItem.estimatedPrice,
                                  format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.details.status)
                             .font(.caption)
                             .foregroundColor(.gray)
                        Picker(l10n.details.enter.status, selection: $editableItem.status) {
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
                        if !viewModel.rooms.isEmpty {
                            Picker(l10n.details.room.subtitle, selection: $editableItem.lastKnownRoom) {
                                ForEach(viewModel.rooms, id: \.id) { room in
                                    Text(room.label).tag(room)
                                }
                                Text(l10n.details.room.add).tag(Room(name: "__add_new__"))
                            }
                            .onChange(of: editableItem.lastKnownRoom) { _,newValue in
                                if newValue.name == "__add_new__" {
                                    showingAddRoomPrompt = true
                                }
                            }
                        } else {
                            ProgressView(l10n.details.room.loading)
                        }
                    }
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
                            await uploadPickedImage()
                            if let newURL = temporaryImageURL {
                                editableItem.imageURL = newURL
                            }
                            editableItem.propertyTag = PropertyTag(rawValue: propertyTagInput)
                            onSave(editableItem)
                            HapticManager.shared.success()
                            dismiss()
                        }
                    }
                    .disabled(editableItem.name.isEmpty || editableItem.description.isEmpty || tagError != nil)
                }
            }
            .alert(l10n.addRoomAlert.title, isPresented: $showingAddRoomPrompt, actions: {
                TextField(l10n.addRoomAlert.placeholder, text: $newRoomName)
                Button(l10n.addRoomAlert.add) {
                    Task {
                        if let newRoom = await viewModel.addRoom(name: newRoomName) {
                            editableItem.lastKnownRoom = newRoom
                        } else {
                            editableItem.lastKnownRoom = Room.placeholder()
                        }
                        newRoomName = ""
                        HapticManager.shared.success()
                    }
                }
                Button(Strings.general.cancel, role: .cancel) { }
            })
            .navigationTitle(l10n.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.general.cancel) { dismiss() }
                }
            }
            .onAppear {
                Logger.page("EditItemView")
                propertyTagInput = editableItem.propertyTag?.rawValue ?? ""
                if let parsed = Date.fromShortString(editableItem.dateAdded) {
                    dateAddedDate = parsed
                }
            }
            .task {
                await viewModel.fetchInventory()
            }
            .task {
                await viewModel.loadRooms()
            }
        }
    }

    private func validateTag() {
        if propertyTagInput.isEmpty || propertyTagInput == editableItem.propertyTag?.label {
            tagError = nil
            return
        }

        guard let tag = PropertyTag(rawValue: propertyTagInput) else {
            tagError = l10n.errors.tag.format
            return
        }

        let isDuplicate = viewModel.items.contains {
            $0.id != editableItem.id &&
            $0.propertyTag?.rawValue == tag.rawValue
        }

        if isDuplicate {
            tagError = l10n.errors.tag.duplicate
            return
        }

        tagError = nil
    }

    private func uploadPickedImage() async {
        guard let uiImage = pickedImage else { return }

        isUploading = true
        uploadError = nil

        defer { isUploading = false }
        do {
            let url = try await ImageUploadService()
                .uploadImageAsync(image: uiImage, forItemId: editableItem.id)
            temporaryImageURL = url.absoluteString
        } catch {
            Logger.log(error, extra: [
                "description": "Upload Image Failed"
            ])
            uploadError = l10n.errors.imageUpload(error.localizedDescription)
            HapticManager.shared.error()
        }
    }

    private func saveReceiptImage(_ image: UIImage?) async {
        guard let image else { return }
        isUploadingReceipt = true
        receiptUploadError = nil
        defer { isUploadingReceipt = false }
        do {
            let url = try PurchaseReceiptService()
                .saveReceipt(image: image, for: editableItem.id)
            editableItem.purchaseReceiptURL = url.path
        } catch {
            receiptUploadError = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    private func saveReceiptPDF(_ url: URL?) async {
        guard let url else { return }
        isUploadingReceipt = true
        receiptUploadError = nil
        defer { isUploadingReceipt = false }
        do {
            let data = try Data(contentsOf: url)
            let saved = try PurchaseReceiptService()
                .saveReceiptPDF(data, for: editableItem.id)
            editableItem.purchaseReceiptURL = saved.path
        } catch {
            receiptUploadError = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
