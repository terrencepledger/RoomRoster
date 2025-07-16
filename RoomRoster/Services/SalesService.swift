import Foundation

actor SalesService {
    private let sheetId: String
    private let apiKey: String
    private let networkService: NetworkServiceProtocol
    private let gmailService: GmailService

    init(
        sheetId: String = AppConfig.shared.sheetId,
        apiKey: String = AppConfig.shared.apiKey,
        networkService: NetworkServiceProtocol = NetworkService.shared,
        gmailService: GmailService = GmailService()
    ) {
        self.sheetId = sheetId
        self.apiKey = apiKey
        self.networkService = networkService
        self.gmailService = gmailService
    }

    func recordSale(_ sale: Sale) async throws {
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

    func fetchSales() async throws -> [Sale] {
        let url = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Sales?key=\(apiKey)"
        Logger.network("SalesService-fetchSales")
        let sheet: GoogleSheetsResponse = try await networkService.fetchData(from: url)
        return sheet.values.dropFirst().compactMap { Sale(from: $0) }
    }

    func sendReceipts(to buyerEmail: String, sellerEmail: String, sale: Sale) async {
        let subject = "Sale Receipt for \(sale.itemId)"
        let body = "Item sold on \(sale.date.toShortString()) for \(sale.price ?? 0)"
        let pdf = ReceiptPDFGenerator.generate(for: sale)
        try? await gmailService.sendEmail(to: buyerEmail, subject: subject, body: body, attachment: pdf)
        try? await gmailService.sendEmail(to: sellerEmail, subject: subject, body: body, attachment: pdf)
    }
}
