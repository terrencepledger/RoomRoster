import Foundation

/// Collection of shared attributes for a set of related items.
///
/// An `ItemGroup` stores common metadata—name, description, images—that
/// would otherwise be duplicated on every `Item`. The group itself is
/// **not** persisted to the backend. Instead each `Item` stores the ID of
/// its group in `groupID` so the UI can display them together.
///
/// Workflow guidelines:
/// - When you have multiple identical products that need individual
///   property tags, create a single `ItemGroup` and then create separate
///   `Item` records referencing that group. Tools like `PropertyTagRange`
///   can help generate the items in bulk.
/// - For loose items without tags, you can either omit the group entirely
///   or store them as a single `Item` with a `quantity` greater than `1`.

struct ItemGroup: Identifiable, Hashable {
    var id: String
    var name: String
    var description: String
    var imageURL: String
    var estimatedPrice: Double?
}

extension ItemGroup {
    static func empty() -> ItemGroup {
        .init(id: UUID().uuidString, name: "", description: "", imageURL: "", estimatedPrice: nil)
    }
}
