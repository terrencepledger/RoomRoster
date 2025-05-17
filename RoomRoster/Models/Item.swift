//
//  Item.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import Foundation
import SwiftData
import SwiftUICore

struct Item: Identifiable {
    var id: String
    var imageURL: String
    var name: String
    var description: String
    var quantity: Int
    var dateAdded: String
    var estimatedPrice: Double?
    var status: String
    var lastKnownRoom: String
    var updatedBy: String
    var lastUpdated: Date?
    var propertyTag: String?
}

extension Item {
    var statusColor: Color {
        switch status {
        case "Available": return .green
        case "Checked Out": return .orange
        case "Discarded": return .red
        case "Sold": return .blue
        default: return .gray
        }
    }
}

extension Item {
    static let schema: [ItemField: AnyFieldBinding] = [
        .id: FieldBinding(field: .id, label: "ID", keyPath: \.id, encode: { $0 }, decode: { $0 }),
        .imageURL: FieldBinding(field: .imageURL, label: "Image URL", keyPath: \.imageURL, encode: { $0 }, decode: { $0 }),
        .name: FieldBinding(field: .name, label: "Name", keyPath: \.name, encode: { $0 }, decode: { $0 }),
        .description: FieldBinding(field: .description, label: "Description", keyPath: \.description, encode: { $0 }, decode: { $0 }),
        .quantity: FieldBinding(field: .quantity, label: "Quantity", keyPath: \.quantity, encode: { "\($0)" }, decode: { Int($0) }),
        .dateAdded: FieldBinding(field: .dateAdded, label: "Date Added", keyPath: \.dateAdded, encode: { $0 }, decode: { $0 }),
        .estimatedPrice: FieldBinding(field: .estimatedPrice, label: "Estimated Price", keyPath: \.estimatedPrice, encode: { $0.map { "\($0)" } ?? "" }, decode: { Double($0) }),
        .status: FieldBinding(field: .status, label: "Status", keyPath: \.status, encode: { $0 }, decode: { $0 }),
        .lastKnownRoom: FieldBinding(field: .lastKnownRoom, label: "Last Known Room", keyPath: \.lastKnownRoom, encode: { $0 }, decode: { $0 }),
        .updatedBy: FieldBinding(field: .updatedBy, label: "Updated By", keyPath: \.updatedBy, encode: { $0 }, decode: { $0 }),
        .lastUpdated: FieldBinding(field: .lastUpdated, label: "Last Updated", keyPath: \.lastUpdated, encode: {
            if let date = $0 {
                ISO8601DateFormatter().string(from: date)
            } else {
                ""
            }}, decode: { ISO8601DateFormatter().date(from: $0) }),
        .propertyTag: FieldBinding(field: .propertyTag, label: "Property Tag", keyPath: \.propertyTag, encode: { $0 ?? "" }, decode: { $0.isEmpty ? nil : $0 })
    ]

    init?(from row: [String]) {
        var item = Item.empty()
        let padded = row.padded(to: ItemField.allCases.count)

        for (i, field) in ItemField.allCases.enumerated() {
            Item.schema[field]?.apply(to: &item, from: padded[i])
        }

        guard !item.id.isEmpty, !item.name.isEmpty else { return nil }
        self = item
    }

    func toRow() -> [String] {
        return ItemField.allCases.map { field in
            Item.schema[field]?.extract(from: self) ?? ""
        }
    }

    static func empty() -> Item {
        .init(id: "", imageURL: "", name: "", description: "", quantity: 0,
              dateAdded: "", estimatedPrice: nil, status: "",
              lastKnownRoom: "", updatedBy: "", lastUpdated: nil, propertyTag: nil)
    }
}
