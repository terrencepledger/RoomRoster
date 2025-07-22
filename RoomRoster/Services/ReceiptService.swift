import Foundation

actor ReceiptService {
    private let directory: URL

    init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory) {
        self.directory = directory.appendingPathComponent("receipts", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func saveReceipt(_ data: Data, for sale: Sale) throws -> Receipt {
        let filename = "\(sale.itemId)_\(sale.date.toShortString()).pdf"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url)
        return Receipt(saleId: sale.itemId, date: sale.date, url: url)
    }

    func loadReceipt(for receipt: Receipt) throws -> Data {
        return try Data(contentsOf: receipt.url)
    }

    func listReceipts() throws -> [Receipt] {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return files.compactMap { file in
            guard file.pathExtension == "pdf" else { return nil }
            let name = file.deletingPathExtension().lastPathComponent
            let parts = name.split(separator: "_", maxSplits: 1).map(String.init)
            guard parts.count == 2, let date = Date.fromShortString(parts[1]) else { return nil }
            return Receipt(saleId: parts[0], date: date, url: file)
        }
    }
}
