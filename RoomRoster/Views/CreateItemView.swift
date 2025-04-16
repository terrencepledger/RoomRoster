//
//  CreateItemView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/11/25.
//

import SwiftUI

struct CreateItemView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (Item) -> Void
    
    @State private var newItem = Item(
        id: UUID().uuidString,
        imageURL: "",
        name: "",
        description: "",
        dateAdded: Date().toShortString(),
        estimatedPrice: nil,
        status: "Available",
        lastKnownRoom: "",
        updatedBy: "",
        lastUpdated: nil,
        propertyTag: nil
    )

    @State private var pickedImage: UIImage? = nil
    @State private var isUploading = false
    @State private var uploadError: String? = nil

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
                        Text("Property Tag")
                        Spacer()
                        TextField("Enter tag", text: Binding<String>(
                            get: { newItem.propertyTag ?? "" },
                            set: { newItem.propertyTag = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Details")) {
                    HStack {
                        TextField("Image URL", text: $newItem.imageURL)
                            .multilineTextAlignment(.trailing)
                            .disabled(true)
                    }

                    HStack {
                        Text("Estimated Price")
                        Spacer()
                        TextField("Enter price", value: $newItem.estimatedPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        TextField("Enter status", text: $newItem.status)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Last Known Room")
                        Spacer()
                        TextField("Enter room", text: $newItem.lastKnownRoom)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Button("Save") {
                    onSave(newItem)
                    dismiss()
                }
                .disabled(newItem.name.isEmpty || newItem.description.isEmpty)
            }
            .navigationTitle("Create Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                try? await AuthenticationManager.shared.signIn()
            }
        }
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
            uploadError = "Upload failed: \(error.localizedDescription)"
        }

        isUploading = false
    }
}
