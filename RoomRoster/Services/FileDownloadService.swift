import Foundation

final class FileDownloadService {
    func download(from url: URL, fileName: String? = nil) async throws -> URL {
        Logger.network("FileDownloadService-download-\(url.absoluteString)")
        let (data, _) = try await URLSession.shared.data(from: url)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName ?? url.lastPathComponent)
        try data.write(to: fileURL)
        return fileURL
    }
}
