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
    
    var body: some View {
        NavigationView {
            Form {
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
                }
                
                Section(header: Text("Details")) {
                    HStack {
                        Text("Image URL")
                        Spacer()
                        TextField("Enter image URL", text: $newItem.imageURL)
                            .multilineTextAlignment(.trailing)
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
}
