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
                    TextField("Name", text: $editableItem.name)
                    TextField("Description", text: $editableItem.description)
                }
                
                Section(header: Text("Details")) {
                    TextField("Image URL", text: $editableItem.imageURL)
                    TextField("Date Added", text: $editableItem.dateAdded)
                    TextField("Estimated Price", value: $editableItem.estimatedPrice, format: .number)
                    TextField("Status", text: $editableItem.status)
                    TextField("Last Known Room", text: $editableItem.lastKnownRoom)
                    TextField("Updated By", text: $editableItem.updatedBy)
                }
                
                Section {
                    Button("Save") {
                        onSave(editableItem)
                        dismiss()
                    }
                    // Disable save if essential fields are empty.
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
