//
//  Item.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import Foundation

struct Item: Identifiable {
    var id: String
    var imageURL: String
    var name: String
    var description: String
    var quantity: Int
    var dateAdded: String
    var estimatedPrice: Double?
    var status: Status
    var lastKnownRoom: Room
    var updatedBy: String
    var lastUpdated: Date?
    var propertyTag: PropertyTag?
}

extension Item {
    static let schema: [ItemField: AnyFieldBinding] = [
        .id: FieldBinding(field: .id, label: "ID", keyPath: \.id, encode: { $0 }, decode: { $0 }),
        .imageURL: FieldBinding(
            field: .imageURL, label: "Image URL", keyPath: \.imageURL, encode: { $0 }, decode: { $0 }
        ),
        .name: FieldBinding(field: .name, label: "Name", keyPath: \.name, encode: { $0 }, decode: { $0 }),
        .description: FieldBinding(
            field: .description, label: "Description", keyPath: \.description, encode: { $0 }, decode: { $0 }
        ),
        .quantity: FieldBinding(
            field: .quantity, label: "Quantity", keyPath: \.quantity, encode: { "\($0)" }, decode: { Int($0) }
        ),
        .dateAdded: FieldBinding(
            field: .dateAdded, label: "Date Added", keyPath: \.dateAdded, encode: { $0 }, decode: { $0 }
        ),
        .estimatedPrice: FieldBinding(
            field: .estimatedPrice, label: "Estimated Price", keyPath: \.estimatedPrice,
            encode: { $0.map { "\($0)" } ?? "" }, decode: { Double($0) }
        ),
        .status: FieldBinding(
            field: .status, label: "Status", keyPath: \.status, encode: { $0.rawValue },
            decode: { Status(rawValue: $0) ?? .available }
        ),
        .lastKnownRoom: FieldBinding(
            field: .lastKnownRoom,
            label: "Room",
            keyPath: \.lastKnownRoom,
            encode: { $0.name },
            decode: { Room(name: $0) }
        ),
        .updatedBy: FieldBinding(
            field: .updatedBy, label: "Updated By", keyPath: \.updatedBy, encode: { $0 }, decode: { $0 }
        ),
        .lastUpdated: FieldBinding(
            field: .lastUpdated, label: "Last Updated", keyPath: \.lastUpdated,
            encode: {
                if let date = $0 {
                    date.toShortString()
                } else {
                    ""
                }
            },
            decode: { Date.fromShortString($0) }
        ),
        .propertyTag: FieldBinding(
            field: .propertyTag,
            label: "Property Tag",
            keyPath: \.propertyTag,
            encode: { $0?.rawValue ?? "" },
            decode: { PropertyTag(rawValue: $0) }
        )
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
              dateAdded: "", estimatedPrice: nil, status: .available,
              lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: nil)
    }
}
