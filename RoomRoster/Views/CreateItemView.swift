//
//  CreateItemView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/11/25.
//

import SwiftUI

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
        lastKnownRoom: "",
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
    @FocusState private var tagFieldFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo")) {
                    CombinedImagePickerButton(image: $pickedImage)
                        .onChange(of: pickedImage) { _,_ in
                            Task { await uploadPickedImage() }
                        }

                    if isUploading {
                        HStack {
                            ProgressView()
                            Text("Uploading Image…")
                        }
                    }
                    if let error = uploadError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    HStack {
                        Text("Image URL").foregroundColor(.gray)
                        Spacer()
                        Text(newItem.imageURL)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Enter name", text: $newItem.name)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Description")
                        Spacer()
                        TextField("Enter description", text: $newItem.description)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Enter Quantity",
                                  value: $newItem.quantity,
                                  format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Property Tag")
                        Spacer()
                        TextField("Enter tag", text: $propertyTagInput)
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

                Section(header: Text("Details")) {
                    HStack {
                        Text("Estimated Price")
                        Spacer()
                        TextField("Enter price", value: $newItem.estimatedPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Status", selection: $newItem.status) {
                        ForEach(Status.allCases, id: \.self) { status in
                            Text(status.label).tag(status)
                        }
                    }
                }

                Button("Save") {
                    validateTag()
                    guard tagError == nil else { return }

                    onSave(newItem)
                    dismiss()
                }
                .disabled(newItem.name.isEmpty || newItem.description.isEmpty || tagError != nil)
            }
            .navigationTitle("Create Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await AuthenticationManager.shared.signIn()
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
                tagError = "Invalid tag format. Use formatting like A1234."
                showTagError = true
            }
            newItem.propertyTag = nil
            return
        }

        let isDuplicate = viewModel.items.contains { $0.propertyTag?.rawValue == tag.rawValue }
        if isDuplicate {
            withAnimation {
                tagError = "That tag already exists."
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
            uploadError = "Upload failed: \(error.localizedDescription)"
        }

        isUploading = false
    }
}
