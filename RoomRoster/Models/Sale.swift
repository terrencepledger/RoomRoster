import Foundation

struct Sale: Hashable {
    var itemId: String
    var date: Date
    var price: Double?
    var condition: Condition
    var buyerName: String
    var buyerContact: String?
    var soldBy: String
    var department: String
    var receiptImageURL: String?
    var receiptPDFURL: String?
}

extension Sale {
    init?(from row: [String]) {
        let padded = row.padded(to: 10)
        guard !padded[0].isEmpty,
              let date = Date.fromShortString(padded[1]) else { return nil }
        itemId = padded[0]
        self.date = date
        price = Double(padded[2])
        condition = Condition(rawValue: padded[3]) ?? .new
        buyerName = padded[4]
        buyerContact = padded[5]
        soldBy = padded[6]
        department = padded[7]
        receiptImageURL = padded[8].isEmpty ? nil : padded[8]
        receiptPDFURL = padded[9].isEmpty ? nil : padded[9]
    }
    func toRow() -> [String] {
        [
            itemId,
            date.toShortString(),
            price.map { "\($0)" } ?? "",
            condition.rawValue,
            buyerName,
            buyerContact ?? "",
            soldBy,
            department,
            receiptImageURL ?? "",
            receiptPDFURL ?? ""
        ]
    }
}
