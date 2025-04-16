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

    @State private var pickedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?

    @State private var temporaryImageURL: String?

    @State private var dateAddedDate: Date = Date()

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
                        Text("Property Tag")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Enter tag", text: Binding(
                            get: { editableItem.propertyTag ?? "" },
                            set: { editableItem.propertyTag = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
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
                        TextField("Enter status", text: $editableItem.status)
                            .textFieldStyle(.roundedBorder)
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
                        Task {
                            await uploadPickedImage()
                            if let newURL = temporaryImageURL {
                                editableItem.imageURL = newURL
                            }
                            onSave(editableItem)
                            dismiss()
                        }
                    }
                    .disabled(editableItem.name.isEmpty || editableItem.description.isEmpty)
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let parsed = Date.fromShortString(editableItem.dateAdded) {
                    dateAddedDate = parsed
                }
            }
        }
    }

    private func uploadPickedImage() async {
        guard let uiImage = pickedImage else {
            uploadError = "No image was selected."
            print("uploadPickedImage: pickedImage is nil")
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
            uploadError = "Upload failed: \(error.localizedDescription)"
            print("uploadPickedImage: Firebase upload error –", error)
        }
    }
}
