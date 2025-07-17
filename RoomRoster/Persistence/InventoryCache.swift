import Foundation
import CoreData

actor InventoryCache {
    static let shared = InventoryCache()
    private let container = PersistenceController.shared.container

    func fetchItems() -> [Item] {
        let context = container.viewContext
        let request: NSFetchRequest<CachedItem> = CachedItem.fetchRequest()
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { try? JSONDecoder().decode(Item.self, from: $0.data) }
    }

    func fetchItem(id: String) -> Item? {
        let context = container.viewContext
        let request: NSFetchRequest<CachedItem> = CachedItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        guard let cached = try? context.fetch(request).first else { return nil }
        return try? JSONDecoder().decode(Item.self, from: cached.data)
    }

    func save(items: [Item]) {
        let context = container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = CachedItem.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        _ = try? context.execute(deleteRequest)
        for item in items {
            let cached = CachedItem(context: context)
            cached.id = item.id
            cached.data = (try? JSONEncoder().encode(item)) ?? Data()
        }
        try? context.save()
    }

    func upsert(_ item: Item) {
        let context = container.viewContext
        let request: NSFetchRequest<CachedItem> = CachedItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.id)
        let cached = (try? context.fetch(request).first) ?? CachedItem(context: context)
        cached.id = item.id
        cached.data = (try? JSONEncoder().encode(item)) ?? Data()
        try? context.save()
    }
}
