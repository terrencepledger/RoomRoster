//
//  EditItemView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import SwiftUI
import PhotosUI

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State var editableItem: Item
    var onSave: (Item) -> Void

    let viewModel: InventoryViewModel = InventoryViewModel()

    @State private var pickedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?

    @State private var temporaryImageURL: String?

    @State private var dateAddedDate: Date = Date()
    @State private var propertyTagInput: String = ""
    @FocusState private var tagFieldFocused: Bool
    @State private var tagError: String? = nil

    var body: some View {
        NavigationView {
            Form {
                // MARK: – Photo Section
                Section(header: Text("Photo")) {
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
                            .overlay(Text("No Image").foregroundColor(.gray))
                    }

                    // Picker button
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select or Take Photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                        CombinedImagePickerButton(image: $pickedImage)
                    }

                    // Upload status & URL display
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
                }

                // MARK: – Basic Information
                Section(header: Text("Basic Information")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter name", text: $editableItem.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter description", text: $editableItem.description)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantity")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter quantity",
                                  value: $editableItem.quantity,
                                  format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Property Tag")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter tag", text: $propertyTagInput)
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
                Section(header: Text("Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date Added")
                            .font(.caption)
                            .foregroundColor(.gray)

                        DatePicker("", selection: $dateAddedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .clipped()
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: dateAddedDate) { _, newDate in
                                editableItem.dateAdded = newDate.toShortString()
                            }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated Price")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter price",
                                  value: $editableItem.estimatedPrice,
                                  format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                             .font(.caption)
                             .foregroundColor(.gray)
                        Picker("Status", selection: $editableItem.status) {
                            ForEach(Status.allCases, id: \.self) { status in
                                Text(status.label).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Known Room")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter room", text: $editableItem.lastKnownRoom)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                // MARK: – Save Button
                Section {
                    Button("Save") {
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
                            dismiss()
                        }
                    }
                    .disabled(editableItem.name.isEmpty || editableItem.description.isEmpty || tagError != nil)
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
        }
    }

    private func validateTag() {
        if propertyTagInput.isEmpty || propertyTagInput == editableItem.propertyTag?.label {
            tagError = nil
            return
        }

        guard let tag = PropertyTag(rawValue: propertyTagInput) else {
            tagError = "Invalid format. Use format like A1234."
            return
        }

        let isDuplicate = viewModel.items.contains {
            $0.id != editableItem.id &&
            $0.propertyTag?.rawValue == tag.rawValue
        }

        if isDuplicate {
            tagError = "That tag already exists."
            return
        }

        tagError = nil
    }

    private func uploadPickedImage() async {
        guard let uiImage = pickedImage else {
            uploadError = "No image was selected."
            return
        }

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
            uploadError = "Upload failed: \(error.localizedDescription)"
        }
    }
}
