//
//  PhotoImportService.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import UIKit

enum PhotoImportError: Error {
    case thumbnailGenerationFailed
    case writeFailed(Error)
}

/// Takes raw image data (from PHPicker, camera capture, etc.), persists the full-res
/// file to disk, generates a compressed thumbnail, and returns a ready-to-insert Photo.
enum PhotoImportService {

    private static var photosDirectory: URL {
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Max dimension for the inline thumbnail kept in the SwiftData store.
    private static let thumbnailMaxDimension: CGFloat = 300

    @MainActor
    static func importPhoto(from data: Data, note: Note?) throws -> Photo {
        let metadata = PhotoMetadataExtractor.extract(from: data)

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
        } catch {
            throw PhotoImportError.writeFailed(error)
        }

        guard let image = UIImage(data: data),
              let thumbnailData = makeThumbnail(from: image)
        else {
            throw PhotoImportError.thumbnailGenerationFailed
        }

        let photo = Photo(
            fileName: fileName,
            thumbnailData: thumbnailData,
            capturedDate: metadata.capturedDate,
            note: note
        )

        if let location = metadata.location {
            photo.setLocation(location)
        }

        return photo
    }

    private static func makeThumbnail(from image: UIImage) -> Data? {
        let size = image.size
        let scale = thumbnailMaxDimension / max(size.width, size.height)
        // Don't upscale small images.
        guard scale < 1 else { return image.jpegData(compressionQuality: 0.8) }

        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.8)
    }

    static func deleteFile(for photo: Photo) {
        try? FileManager.default.removeItem(at: photo.fileURL)
    }
}
