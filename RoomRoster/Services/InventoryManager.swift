import Foundation

@MainActor
final class InventoryManager: ObservableObject {
    static let shared = InventoryManager()

    @Published private(set) var sheetId: String
    @Published private(set) var apiKey: String

    private let networkService: NetworkServiceProtocol
    private let inventoryMarker = "ROOM_ROSTER_V1"

    enum InventoryError: Error, LocalizedError {
        case accessDenied
        case invalidInventory

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "You do not have access to this inventory."
            case .invalidInventory:
                return "This sheet is not a valid RoomRoster inventory."
            }
        }
    }

    init(
        sheetId: String = AppConfig.shared.sheetId,
        apiKey: String = AppConfig.shared.apiKey,
        networkService: NetworkServiceProtocol = NetworkService.shared
    ) {
        self.sheetId = sheetId
        self.apiKey = apiKey
        self.networkService = networkService
    }

    private func metadataURL(sheetId: String, apiKey: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "sheets.googleapis.com"
        let range = "'Metadata'!A1"
        components.path = "/v4/spreadsheets/\(sheetId)/values/\(range)"
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components.url
    }

    func verifyAccess(sheetId: String, apiKey: String) async -> Bool {
        guard let url = metadataURL(sheetId: sheetId, apiKey: apiKey) else { return false }
        do {
            let response: GoogleSheetsResponse = try await networkService.fetchData(from: url.absoluteString)
            return response.values.first?.first == inventoryMarker
        } catch {
            return false
        }
    }

    func switchInventory(sheetId: String, apiKey: String) async throws {
        guard let url = metadataURL(sheetId: sheetId, apiKey: apiKey) else { throw InventoryError.invalidInventory }
        do {
            let response: GoogleSheetsResponse = try await networkService.fetchData(from: url.absoluteString)
            guard response.values.first?.first == inventoryMarker else {
                throw InventoryError.invalidInventory
            }
            self.sheetId = sheetId
            self.apiKey = apiKey
        } catch {
            throw InventoryError.accessDenied
        }
    }
}
