import Foundation

actor ReceiptService {
    private let directory: URL
    private let indexURL: URL
    private var receipts: [Receipt] = []

    init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory) {
        self.directory = directory.appendingPathComponent("sale_receipts", isDirectory: true)
        self.indexURL = self.directory.appendingPathComponent("receipts.json")
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        loadIndex()
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([Receipt].self, from: data) else {
            receipts = []
            return
        }
        receipts = decoded
    }

    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(receipts) else { return }
        try? data.write(to: indexURL)
    }

    func uploadReceipt(_ data: Data, for saleId: String) throws -> Receipt {
        let fileURL = directory.appendingPathComponent("\(saleId).pdf")
        try data.write(to: fileURL)
        let receipt = Receipt(saleId: saleId, date: Date(), pdfURL: fileURL)
        receipts.append(receipt)
        saveIndex()
        return receipt
    }

    func fetchReceipt(for saleId: String) throws -> Data {
        let fileURL = directory.appendingPathComponent("\(saleId).pdf")
        return try Data(contentsOf: fileURL)
    }

    func allReceipts() -> [Receipt] { receipts }
}
