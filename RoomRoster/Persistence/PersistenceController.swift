import Foundation
import CoreData

final class CachedItem: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var data: Data
}

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.managedObjectModel
        container = NSPersistentContainer(name: "RoomRosterModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved error \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static var managedObjectModel: NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "CachedItem"
        entity.managedObjectClassName = NSStringFromClass(CachedItem.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false

        let dataAttr = NSAttributeDescription()
        dataAttr.name = "data"
        dataAttr.attributeType = .binaryDataAttributeType
        dataAttr.isOptional = false

        entity.properties = [idAttr, dataAttr]
        model.entities = [entity]
        return model
    }
}

extension CachedItem {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CachedItem> {
        NSFetchRequest<CachedItem>(entityName: "CachedItem")
    }
}
