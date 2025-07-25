import Foundation

actor SalesService {
    private let sheetIdProvider: @MainActor () -> String?
    private let networkService: NetworkServiceProtocol
    private let gmailService: GmailService

    init(
        sheetIdProvider: @escaping @MainActor () -> String? = { SpreadsheetManager.shared.currentSheet?.id },
        networkService: NetworkServiceProtocol = NetworkService.shared,
        gmailService: GmailService = GmailService()
    ) {
        self.sheetIdProvider = sheetIdProvider
        self.networkService = networkService
        self.gmailService = gmailService
    }

    init(
        sheetId: String,
        networkService: NetworkServiceProtocol = NetworkService.shared,
        gmailService: GmailService = GmailService()
    ) {
        self.sheetIdProvider = { sheetId }
        self.networkService = networkService
        self.gmailService = gmailService
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

    func sendReceipts(to buyerEmail: String?, sellerEmail: String, sale: Sale) async {
        let subject = "Sale Receipt for \(sale.itemId)"
        let body = "Item sold on \(sale.date.toShortString()) for \(sale.price ?? 0)"
        #if canImport(UIKit)
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
