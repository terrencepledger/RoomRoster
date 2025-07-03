//
//  ItemValidator.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 5/31/25.
//

import Foundation

enum ItemValidationError: Error, Equatable {
    case emptyName
    case emptyDescription
    case invalidTagFormat
    case duplicateTag
}

struct ItemValidator {
    static func validateName(_ name: String) throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ItemValidationError.emptyName
        }
    }

    static func validateDescription(_ description: String) throws {
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ItemValidationError.emptyDescription
        }
    }

    static func validateTag(_ input: String, currentItemID: String?, allItems: [Item]) throws(ItemValidationError) -> PropertyTag {
        guard let tag = PropertyTag(rawValue: input) else {
            throw ItemValidationError.invalidTagFormat
        }

        let isDuplicate = allItems.contains {
            $0.id != currentItemID && $0.propertyTag?.rawValue.caseInsensitiveCompare(tag.rawValue) == .orderedSame
        }

        if isDuplicate {
            throw ItemValidationError.duplicateTag
        }

        return tag
    }
}
