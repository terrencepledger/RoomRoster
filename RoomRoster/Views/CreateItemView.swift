//
//  CreateItemView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/11/25.
//

import SwiftUI

private typealias l10n = Strings.createItem

struct CreateItemView: View {
    @Environment(\.dismiss) var dismiss

    var viewModel: InventoryViewModel
    var onSave: (Item) -> Void

    @State private var newItem = Item(
        id: UUID().uuidString,
        imageURL: "",
        name: "",
        description: "",
        quantity: 1,
        dateAdded: Date().toShortString(),
        estimatedPrice: nil,
        status: .available,
        lastKnownRoom: .placeholder(),
        updatedBy: "",
        lastUpdated: nil,
        propertyTag: nil
    )

    @State private var pickedImage: UIImage? = nil
    @State private var isUploading = false
    @State private var uploadError: String? = nil
    @State private var tagError: String?
    @State private var propertyTagInput: String = ""
    @State private var showTagError: Bool = false
    @State private var showingAddRoomPrompt = false
    @State private var newRoomName = ""
    @FocusState private var tagFieldFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(l10n.photo)) {
                    CombinedImagePickerButton(image: $pickedImage)
                        .onChange(of: pickedImage) { _,_ in
                            Task { await uploadPickedImage() }
                        }

                    if isUploading {
                        HStack {
                            ProgressView()
                            Text(l10n.uploadingImage)
                        }
                    }
                    if let error = uploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    HStack {
                        Text(l10n.imageURL).foregroundColor(.gray)
                        Spacer()
                        Text(newItem.imageURL)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text(l10n.basicInfo.title)) {
                    HStack {
                        Text(l10n.basicInfo.name)
                        Spacer()
                        TextField(l10n.basicInfo.enter.name, text: $newItem.name)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(l10n.basicInfo.description)
                        Spacer()
                        TextField(l10n.basicInfo.enter.description, text: $newItem.description)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(l10n.basicInfo.quantity)
                        Spacer()
                        TextField(l10n.basicInfo.enter.quantity,
                                  value: $newItem.quantity,
                                  format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text(l10n.basicInfo.tag)
                        Spacer()
                        TextField(l10n.basicInfo.enter.tag, text: $propertyTagInput)
                            .focused($tagFieldFocused)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: tagFieldFocused) { _, focused in
                                if !focused {
                                    withAnimation {
                                        validateTag()
                                    }
                                }
                            }
                    }
                    if showTagError, let error = tagError {
                        HStack {
                            Spacer()
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                        withAnimation {
                                            if (tagError?.count ?? 0) > 0 {
                                                if !tagFieldFocused {
                                                    propertyTagInput = ""
                                                }
                                                validateTag()
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }

                Section(header: Text(l10n.details.title)) {
                    HStack {
                        Text(l10n.details.price)
                        Spacer()
                        TextField(l10n.details.enter.price, value: $newItem.estimatedPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker(l10n.details.status, selection: $newItem.status) {
                        ForEach(Status.allCases, id: \.self) { status in
                            Text(status.label).tag(status)
                        }
                    }

                    Picker(l10n.details.room.title, selection: $newItem.lastKnownRoom) {
                        if newItem.lastKnownRoom == Room.placeholder() {
                            Text(l10n.details.enter.room).tag(Room.placeholder())
                        }
                        ForEach(viewModel.rooms, id: \.self) { room in
                            Text(room.label).tag(room)
                        }
                        Text(l10n.details.room.add)
                            .foregroundColor(.blue)
                            .tag(Room(name: "__add_new__"))
                    }
                    .onChange(of: newItem.lastKnownRoom) { _,newValue in
                        if newValue.name == "__add_new__" {
                            showingAddRoomPrompt = true
                        }
                    }
                }

                Button(Strings.general.save) {
                    validateTag()
                    guard tagError == nil else { return }

                    onSave(newItem)
                    dismiss()
                }
                .disabled(newItem.name.isEmpty || newItem.description.isEmpty || tagError != nil || newItem.lastKnownRoom == Room.placeholder())
            }
            .alert(l10n.addRoom.title, isPresented: $showingAddRoomPrompt, actions: {
                TextField(l10n.addRoom.placeholder, text: $newRoomName)
                Button(l10n.addRoom.button) {
                    Logger.action("Pressed Add Room Button")
                    Task {
                        if let newRoom = await viewModel.addRoom(name: newRoomName) {
                            newItem.lastKnownRoom = newRoom
                        } else {
                            newItem.lastKnownRoom = Room.placeholder()
                        }
                        newRoomName = ""
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
            .task {
                Task {
                    await AuthenticationManager.shared.signIn()
                }
                Task {
                    await viewModel.loadRooms()
                }
            }
            .onAppear {
                Logger.page("CreateItemView")
            }
        }
    }

    private func validateTag() {
        if propertyTagInput.isEmpty {
            withAnimation {
                showTagError = false
                tagError = nil
            }
            newItem.propertyTag = nil
            return
        }

        guard let tag = PropertyTag(rawValue: propertyTagInput) else {
            withAnimation {
                tagError = l10n.errors.tag.format
                showTagError = true
            }
            newItem.propertyTag = nil
            return
        }

        let isDuplicate = viewModel.items.contains { $0.propertyTag?.rawValue == tag.rawValue }
        if isDuplicate {
            withAnimation {
                tagError = l10n.errors.tag.duplicate
                showTagError = true
            }
            newItem.propertyTag = nil
            return
        }

        showTagError = false
        tagError = nil
        newItem.propertyTag = tag
    }

    private func uploadPickedImage() async {
        guard let image = pickedImage else { return }
        isUploading = true
        uploadError = nil

        do {
            let url = try await ImageUploadService().uploadImageAsync(
                image: image,
                forItemId: newItem.id
            )
            newItem.imageURL = url.absoluteString
        } catch {
            Logger.log(error, extra: [
                "description": "Upload Image Failed"
            ])
            uploadError = l10n.errors.imageUpload(error.localizedDescription)
        }

        isUploading = false
    }
}
