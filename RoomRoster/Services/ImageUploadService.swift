//
//  ImageUploadService.swift
//  RoomRoster
//
//  Created by Terrence Pledger on 4/16/25.
//

import Foundation


enum ImageUploadError: Error {
    case failedToConvertImage
    case uploadFailed(Error)
    case downloadURLNotFound
}

class ImageUploadService {
    private let firebaseService: FirebaseService

    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
    }

    func uploadImageAsync(image: PlatformImage, forItemId itemId: String) async throws -> URL {
        guard let imageData = image.jpegDataCompatible(compressionQuality: 0.8) else {
            throw ImageUploadError.failedToConvertImage
        }
        return try await firebaseService.uploadData(
            imageData,
            to: "images/\(itemId).jpg",
            contentType: "image/jpeg"
        )
    }
}
