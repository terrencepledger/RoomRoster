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
    case quantityMismatch
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

    /// Validates a property tag string which may contain a comma separated list
    /// or range of tags. Returns the parsed collection of tags.
    ///
    /// - Parameters:
    ///   - input: The raw tag string entered by the user.
    ///   - quantity: Expected number of items. Must match the number of parsed tags.
    ///   - currentItemID: If editing an existing item, its identifier so duplicates are ignored.
    ///   - allItems: Existing items used to check for duplicate tags.
    /// - Throws: ``ItemValidationError`` if the input is invalid or contains duplicates.
    /// - Returns: Parsed property tags.
    static func validateTags(
        _ input: String,
        quantity: Int,
        currentItemID: String?,
        allItems: [Item]
    ) throws -> [PropertyTag] {
        guard let range = PropertyTagRange(from: input) else {
            throw ItemValidationError.invalidTagFormat
        }

        if range.tags.count != quantity {
            throw ItemValidationError.quantityMismatch
        }

        var seen: Set<String> = []
        for tag in range.tags {
            // check duplicates within the range
            if !seen.insert(tag.rawValue.uppercased()).inserted {
                throw ItemValidationError.duplicateTag
            }

            // check duplicates against existing items
            let isDuplicate = allItems.contains {
                $0.id != currentItemID &&
                $0.propertyTag?.rawValue.caseInsensitiveCompare(tag.rawValue) == .orderedSame
            }
            if isDuplicate {
                throw ItemValidationError.duplicateTag
            }
        }

        return range.tags
    }
}
