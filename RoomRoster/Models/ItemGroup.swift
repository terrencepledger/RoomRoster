import Foundation

/// Describes attributes shared by multiple inventory items.
///
/// `ItemGroup` instances are never persisted directly. Instead, each
/// `Item` references a group via its `groupID`. When adding many of the
/// same product, create one group and then generate individual `Item`
/// records—each may supply its own `propertyTag` if needed—so that the
/// data is normalized but items can still be tracked separately.

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
