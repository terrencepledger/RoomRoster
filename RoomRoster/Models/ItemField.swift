//
//  ItemField.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

enum ItemField: CaseIterable {
    case id, imageURL, name, description, quantity,
         dateAdded, estimatedPrice, status, lastKnownRoom,
         updatedBy, lastUpdated, propertyTag

    var label: String {
        switch self {
        case .id: return "ID"
        case .imageURL: return "Image URL"
        case .name: return "Name"
        case .description: return "Description"
        case .quantity: return "Quantity"
        case .dateAdded: return "Date Added"
        case .estimatedPrice: return "Estimated Price"
        case .status: return "Status"
        case .lastKnownRoom: return "Last Known Room"
        case .updatedBy: return "Updated By"
        case .lastUpdated: return "Last Updated"
        case .propertyTag: return "Property Tag"
        }
    }
}
