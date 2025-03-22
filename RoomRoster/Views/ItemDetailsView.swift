//
//  ItemDetailsView.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import SwiftUI

struct ItemDetailsView: View {
    @State var item: Item
    @State private var historyLogs: [String] = []
    @State private var isEditing = false
    @StateObject private var viewModel = ItemDetailsViewModel()
    
    init(item: Item) {
        _item = State(initialValue: item)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = URL(string: item.imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 250)
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(item.description)
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Divider()
                    
                    HStack {
                        Text("Date Added:").bold()
                        Text(item.dateAdded)
                    }
                    
                    if let price = item.estimatedPrice {
                        HStack {
                            Text("Estimated Price:").bold()
                            Text("$\(price, specifier: "%.2f")")
                        }
                    }
                    
                    HStack {
                        Text("Status:").bold()
                        Text(item.status)
                            .foregroundColor(item.statusColor)
                    }
                    
                    HStack {
                        Text("Last Known Room:").bold()
                        Text(item.lastKnownRoom)
                    }
                    
                    if let date = item.lastUpdated {
                        Text("Last Updated: \(date.description(with: .autoupdatingCurrent))")
                    }
                    
                    Divider()
                    
                    Text("History Log")
                        .font(.headline)
                        .padding(.top)
                    
                    if viewModel.historyLogs.isEmpty {
                        Text("No history available")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.historyLogs, id: \.self) { log in
                            Text(log)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    isEditing = true
                }) {
                    Text("Edit Item")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationTitle("Item Details")
        .task {
            try? await AuthenticationManager.shared.signIn()
            await viewModel.fetchItemHistory(for: item.id)
        }
        .sheet(isPresented: $isEditing) {
            EditItemView(editableItem: item) { updatedItem in
                self.item = updatedItem
                
                Task {
                    do {
                        try await InventoryService().updateItem(updatedItem)
                        // Optionally, you could trigger a refresh of the inventory list.
                    } catch {
                        print("Error updating item: \(error)")
                    }
                }
            }
        }
    }
}


// Preview for Testing
struct ItemDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailsView(item: Item(
            id: "12345",
            imageURL: "https://cataas.com/cat/says/Hello",
            name: "Wooden Chair",
            description: "A sturdy chair",
            dateAdded: "2025-01-10",
            estimatedPrice: 35.00,
            status: "Available",
            lastKnownRoom: "Sanctuary",
            updatedBy: "John Doe",
            lastUpdated: Date.now
        ))
    }
}
