import Foundation
import FirebaseStorage

struct FirebaseService {
    static let shared = FirebaseService()
    private let storage = Storage.storage()

    func uploadData(_ data: Data, to path: String, contentType: String) async throws -> URL {
        Logger.network("FirebaseService-uploadData-\(path)")
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        try await withCheckedThrowingContinuation { cont in
            ref.putData(data, metadata: metadata) { _, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
        return try await downloadURL(for: path)
    }

    func downloadURL(for path: String) async throws -> URL {
        Logger.network("FirebaseService-downloadURL-\(path)")
        let ref = storage.reference().child(path)
        return try await withCheckedThrowingContinuation { cont in
            ref.downloadURL { url, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let url = url {
                    cont.resume(returning: url)
                } else {
                    cont.resume(throwing: NSError(domain: "FirebaseService", code: -1, userInfo: nil))
                }
            }
        }
    }

    func downloadData(at path: String) async throws -> Data {
        Logger.network("FirebaseService-downloadData-\(path)")
        let url = try await downloadURL(for: path)
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
