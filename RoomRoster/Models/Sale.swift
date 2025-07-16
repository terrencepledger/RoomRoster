import Foundation

struct Sale {
    var itemId: String
    var date: Date
    var price: Double?
    var condition: Condition
    var buyerName: String
    var buyerContact: String
    var soldBy: String
    var department: String
}

extension Sale {
    func toRow() -> [String] {
        [
            itemId,
            date.toShortString(),
            price.map { "\($0)" } ?? "",
            condition.rawValue,
            buyerName,
            buyerContact,
            soldBy,
            department
        ]
    }
}
