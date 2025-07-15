import Foundation
@testable import RoomRoster

enum MockError: Error { case noResponse }

final class MockNetworkService: NetworkServiceProtocol {
    var fetchDataInputs: [String] = []
    var fetchDataResults: [Any] = []
    func fetchData<T: Codable>(from urlString: String) async throws -> T {
        fetchDataInputs.append(urlString)
        guard !fetchDataResults.isEmpty else { throw MockError.noResponse }
        let value = fetchDataResults.removeFirst()
        return value as! T
    }

    var authorizedRequests: [(URL,String,[String:Any])] = []
    var requestToReturn = URLRequest(url: URL(string: "https://example.com")!)
    func authorizedRequest(url: URL, method: String, jsonBody: [String : Any]) async throws -> URLRequest {
        authorizedRequests.append((url, method, jsonBody))
        return requestToReturn
    }

    var sentRequests: [URLRequest] = []
    func sendRequest(_ request: URLRequest) async throws {
        sentRequests.append(request)
    }
}
