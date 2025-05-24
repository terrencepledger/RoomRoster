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
                        TextField("Enter tag", text: Binding<String>(
                            get: { newItem.propertyTag ?? "" },
                            set: { newItem.propertyTag = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
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
                await AuthenticationManager.shared.signIn()
            }
            .onAppear {
                Logger.page("CreateItemView")
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
            Logger.log(error, extra: [
                "description": "Upload Image Failed"
            ])
            uploadError = "Upload failed: \(error.localizedDescription)"
        }

        isUploading = false
    }
}
