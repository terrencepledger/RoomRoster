//
//  NetworkService.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 3/22/25.
//

import Foundation

protocol NetworkServiceProtocol {
    func fetchData<T: Codable>(from urlString: String) async throws -> T
    func authorizedRequest(url: URL, method: String, jsonBody: [String: Any]) async throws -> URLRequest
    func sendRequest(_ request: URLRequest) async throws
}

enum NetworkError: Error {
    case invalidURL
}

struct NetworkService {
    static let shared = NetworkService()

    func fetchData<T: Codable>(from urlString: String) async throws -> T {
        Logger.network(urlString)
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            if let dataString = String(data: data, encoding: .utf8) {
                Logger.network(dataString)
            }
            throw error
        }
    }

    func authorizedRequest(
        url: URL,
        method: String,
        jsonBody: [String: Any]
    ) async throws -> URLRequest {
        guard let accessToken = await AuthenticationManager.shared.accessToken else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        return request
    }

    func sendRequest(_ request: URLRequest) async throws {
        Logger.network(request.debugDescription)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Network", code: 500, userInfo: [NSLocalizedDescriptionKey: "Request failed with non-2xx response"])
        }
    }
}

extension NetworkService: NetworkServiceProtocol {}
