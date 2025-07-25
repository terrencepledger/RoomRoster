import Foundation

actor SalesService {
    private let sheetIdProvider: @MainActor () -> String?
    private let networkService: NetworkServiceProtocol
    private let gmailService: GmailService
    private let receiptService: SaleReceiptService

    init(
        sheetIdProvider: @escaping @MainActor () -> String? = { SpreadsheetManager.shared.currentSheet?.id },
        networkService: NetworkServiceProtocol = NetworkService.shared,
        gmailService: GmailService = GmailService(),
        receiptService: SaleReceiptService = SaleReceiptService()
    ) {
        self.sheetIdProvider = sheetIdProvider
        self.networkService = networkService
        self.gmailService = gmailService
        self.receiptService = receiptService
    }

    init(
        sheetId: String,
        networkService: NetworkServiceProtocol = NetworkService.shared,
        gmailService: GmailService = GmailService(),
        receiptService: SaleReceiptService = SaleReceiptService()
    ) {
        self.sheetIdProvider = { sheetId }
        self.networkService = networkService
        self.gmailService = gmailService
        self.receiptService = receiptService
    }

    func recordSale(_ sale: Sale) async throws {
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Sales:append?valueInputOption=USER_ENTERED"
        guard let url = URL(string: urlString) else { throw NetworkError.invalidURL }
        let request = try await networkService.authorizedRequest(
            url: url,
            method: "POST",
            jsonBody: ["values": [sale.toRow()]]
        )
        Logger.network("SalesService-recordSale")
        try await networkService.sendRequest(request)
    }

    func fetchSale(for itemId: String) async throws -> Sale? {
        Logger.network("SalesService-fetchSale")
        let sales = try await fetchSales()
        return sales.first { $0.itemId == itemId }
    }

    func fetchSales() async throws -> [Sale] {
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        guard let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Sales") else { throw NetworkError.invalidURL }
        Logger.network("SalesService-fetchSales")
        let sheet: GoogleSheetsResponse = try await networkService.fetchAuthorizedData(from: url)
        return sheet.values.dropFirst().compactMap { Sale(from: $0) }
    }

    private func fetchSalesSheet() async throws -> GoogleSheetsResponse {
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        guard let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Sales") else { throw NetworkError.invalidURL }
        Logger.network("SalesService-fetchSalesSheet")
        return try await networkService.fetchAuthorizedData(from: url)
    }

    private func getRowNumber(for itemId: String) async throws -> Int {
        let sheet = try await fetchSalesSheet()
        guard let index = SheetsUtils.rowIndex(for: itemId, in: sheet.values) else {
            throw NSError(domain: "SalesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Row not found for id \(itemId)"])
        }
        return index + 1
    }

    func updateSale(_ sale: Sale) async throws {
        let row = try await getRowNumber(for: sale.itemId)
        let columnCount = sale.toRow().count
        let endCol = SheetsUtils.columnName(for: columnCount)
        let range = "Sales!A\(row):\(endCol)\(row)"
        let sheetId = await MainActor.run { sheetIdProvider() } ?? ""
        guard let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(range)?valueInputOption=USER_ENTERED") else {
            throw NetworkError.invalidURL
        }
        let request = try await networkService.authorizedRequest(
            url: url,
            method: "PUT",
            jsonBody: ["values": [sale.toRow()]]
        )
        Logger.network("SalesService-updateSale")
        try await networkService.sendRequest(request)
    }

    func sendReceipts(to buyerEmail: String?, sellerEmail: String, sale: Sale) async {
        let subject = "Sale Receipt for \(sale.itemId)"
        let body = "Item sold on \(sale.date.toShortString()) for \(sale.price ?? 0)"
#if canImport(AppKit) || canImport(UIKit)
        let pdf = ReceiptPDFGenerator.generate(for: sale)
#else
        let pdf: Data? = nil
#endif
        if let buyerEmail {
            try? await gmailService.sendEmail(to: buyerEmail, subject: subject, body: body, attachment: pdf)
        }
        try? await gmailService.sendEmail(to: sellerEmail, subject: subject, body: body, attachment: pdf)
    }
}
