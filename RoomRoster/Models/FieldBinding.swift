//
//  AnyFieldBinding.swift
//  RoomRoster
//
//  Created by Terrence on 5/16/25.
//

import Foundation

protocol AnyFieldBinding {
    var field: ItemField { get }
    var label: String { get }
    func extract(from item: Item) -> String
    func apply(to item: inout Item, from value: String)
    func diff(old: Item, new: Item, by: String, at: Date) -> HistoryAction?
}

struct FieldBinding<Value: Equatable>: AnyFieldBinding {
    let field: ItemField
    let label: String
    let keyPath: WritableKeyPath<Item, Value>
    let encode: (Value) -> String
    let decode: (String) -> Value?

    func extract(from item: Item) -> String {
        encode(item[keyPath: keyPath])
    }

    func apply(to item: inout Item, from value: String) {
        if let decoded = decode(value) {
            item[keyPath: keyPath] = decoded
        }
    }

    func diff(old: Item, new: Item, by: String, at: Date) -> HistoryAction? {
        let oldValue = old[keyPath: keyPath]
        let newValue = new[keyPath: keyPath]
        guard oldValue != newValue else { return nil }

        return .edited(
            field: label,
            oldValue: encode(oldValue),
            newValue: encode(newValue),
            by: by,
            date: at
        )
    }
}
