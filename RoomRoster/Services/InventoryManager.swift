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

    func verifyAccess(sheetId: String, apiKey: String) async -> Bool {
        let url = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Metadata!A1?key=\(apiKey)"
        do {
            let response: GoogleSheetsResponse = try await networkService.fetchData(from: url)
            return response.values.first?.first == inventoryMarker
        } catch {
            return false
        }
    }

    func switchInventory(sheetId: String, apiKey: String) async throws {
        let url = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/Metadata!A1?key=\(apiKey)"
        do {
            let response: GoogleSheetsResponse = try await networkService.fetchData(from: url)
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
