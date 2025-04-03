//
//  EditItemView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//


import SwiftUI

struct EditItemView: View {
    @Environment(\.dismiss) var dismiss
    @State var editableItem: Item
    var onSave: (Item) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("Name")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter name", text: $editableItem.name)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Description")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter description", text: $editableItem.description)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Details")) {
                    HStack {
                        Text("Image URL")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter image URL", text: $editableItem.imageURL)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Date Added")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter date", text: $editableItem.dateAdded)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Estimated Price")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter price", value: $editableItem.estimatedPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Status")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter status", text: $editableItem.status)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Last Known Room")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter room", text: $editableItem.lastKnownRoom)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Updated By")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter updater", text: $editableItem.updatedBy)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Save") {
                        onSave(editableItem)
                        dismiss()
                    }
                    .disabled(editableItem.name.isEmpty || editableItem.description.isEmpty)
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditItemView_Previews: PreviewProvider {
    static var previews: some View {
        EditItemView(editableItem: Item(
            id: "-1",
            imageURL: "https://example.com/image.jpg",
            name: "Chair",
            description: "A wooden chair",
            dateAdded: "2025-01-10",
            estimatedPrice: 45.0,
            status: "Available",
            lastKnownRoom: "Living Room",
            updatedBy: "User",
            lastUpdated: Date()
        )) { updatedItem in
            print("Updated item: \(updatedItem)")
        }
    }
}
