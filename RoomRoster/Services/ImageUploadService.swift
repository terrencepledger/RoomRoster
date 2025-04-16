//
//  ImageUploadError.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/16/25.
//

import UIKit
import FirebaseStorage

enum ImageUploadError: Error {
    case failedToConvertImage
    case uploadFailed(Error)
    case downloadURLNotFound
}

class ImageUploadService {
    private let storage = Storage.storage()

    func uploadImageAsync(image: UIImage, forItemId itemId: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageUploadError.failedToConvertImage
        }
        let imageRef = storage.reference().child("images/\(itemId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            imageRef.putData(imageData, metadata: metadata) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        let downloadURL: URL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            imageRef.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ImageUploadError.downloadURLNotFound)
                }
            }
        }
        
        return downloadURL
    }
}
