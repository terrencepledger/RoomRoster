import Foundation

struct GmailService {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func sendEmail(to recipient: String, subject: String, body: String, attachment: Data? = nil, filename: String = "receipt.pdf") async throws {
        var mime = "From: me\r\nTo: \(recipient)\r\nSubject: \(subject)\r\n"
        if let data = attachment {
            let boundary = "boundary42"
            mime += "Content-Type: multipart/mixed; boundary=\(boundary)\r\n\r\n"
            mime += "--\(boundary)\r\n"
            mime += "Content-Type: text/plain; charset=utf-8\r\n\r\n"
            mime += "\(body)\r\n"
            mime += "--\(boundary)\r\n"
            mime += "Content-Type: application/pdf; name=\(filename)\r\n"
            mime += "Content-Disposition: attachment; filename=\(filename)\r\n"
            mime += "Content-Transfer-Encoding: base64\r\n\r\n"
            mime += data.base64EncodedString() + "\r\n"
            mime += "--\(boundary)--"
        } else {
            mime += "\r\n\(body)"
        }

        guard let encoded = mime.data(using: .utf8)?.base64EncodedString() else {
            throw NSError(domain: "Gmail", code: -1, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
        }

        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/send")!
        let request = try await networkService.authorizedRequest(
            url: url,
            method: "POST",
            jsonBody: ["raw": encoded]
        )
        try await networkService.sendRequest(request)
    }
}
