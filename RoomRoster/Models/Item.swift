//
//  Item.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 1/30/25.
//

import Foundation

/// Represents a single unit of inventory or a collection of identical
/// units that do not need their own property tags.
///
/// - Each item always has a unique `id` and may optionally belong to an
///   `ItemGroup` via `groupID` when multiple records describe the same
///   product.
/// - If `quantity` is greater than `1`, the record indicates a stack of
///   identical items that share all attributes and **have no individual
///   `PropertyTag` values**. Use this when tracking generics like cables
///   or low‑value parts.
/// - When every unit requires a distinct tag, create separate `Item`
///   instances, each with `quantity == 1` and its own `propertyTag`, but
///   reuse the same `groupID` so the items can be managed collectively.
///   Bulk creation helpers (e.g., `PropertyTagRange`) can generate these
///   items from a list or range of tags.

struct Item: Identifiable, Hashable {
    var id: String
    var imageURL: String
    var name: String
    var description: String
    var groupID: String?
    var quantity: Int
    var dateAdded: String
    var estimatedPrice: Double?
    var status: Status
    var lastKnownRoom: Room
    var updatedBy: String
    var lastUpdated: Date?
    var propertyTag: PropertyTag?
    var propertyTagRange: PropertyTagRange? = nil
    var purchaseReceiptURL: String?

    var isGrouped: Bool {
        groupID != nil || quantity > 1
    }
}

struct PropertyTagFieldBinding: AnyFieldBinding {
    let field: ItemField = .propertyTag
    let label: String = "Property Tag"

    func extract(from item: Item) -> String {
        if let range = item.propertyTagRange {
            return range.stringValue()
        }
        return item.propertyTag?.rawValue ?? ""
    }

    func apply(to item: inout Item, from value: String) {
        guard !value.isEmpty else {
            item.propertyTag = nil
            item.propertyTagRange = nil
            return
        }
        if let range = PropertyTagRange(from: value) {
            if range.tags.count == 1 {
                item.propertyTag = range.tags[0]
                item.propertyTagRange = nil
            } else {
                item.propertyTagRange = range
                item.propertyTag = nil
            }
        } else {
            item.propertyTag = nil
            item.propertyTagRange = nil
        }
    }

    func diff(old: Item, new: Item, by: String, at: Date) -> HistoryAction? {
        let oldValue = extract(from: old)
        let newValue = extract(from: new)
        guard oldValue != newValue else { return nil }
        return .edited(field: label, oldValue: oldValue, newValue: newValue, by: by, date: at)
    }
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
        .propertyTag: PropertyTagFieldBinding(),
        .purchaseReceiptURL: FieldBinding(
            field: .purchaseReceiptURL,
            label: "Purchase Receipt URL",
            keyPath: \.purchaseReceiptURL,
            encode: { $0 ?? "" },
            decode: { $0 }
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
        .init(id: "", imageURL: "", name: "", description: "", groupID: nil, quantity: 0,
              dateAdded: "", estimatedPrice: nil, status: .available,
              lastKnownRoom: .empty(), updatedBy: "", lastUpdated: nil, propertyTag: nil,
              propertyTagRange: nil, purchaseReceiptURL: nil)
    }
}
