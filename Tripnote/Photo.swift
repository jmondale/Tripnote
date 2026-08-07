//
//  Photo.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Photo {
    var id: UUID

    /// Filename of the full-resolution image stored in the app's Documents/Photos directory.
    /// We store a reference rather than raw Data in the model to keep the SwiftData store lean.
    var fileName: String

    /// Small JPEG thumbnail kept inline for fast list/grid rendering.
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    // EXIF-derived metadata, captured at import time.
    var capturedDate: Date?
    var latitude: Double?
    var longitude: Double?

    var note: Note?

    init(fileName: String, thumbnailData: Data? = nil, capturedDate: Date? = nil, note: Note? = nil) {
        self.id = UUID()
        self.fileName = fileName
        self.thumbnailData = thumbnailData
        self.capturedDate = capturedDate
        self.note = note
    }

    var location: CLLocation? {
        guard let latitude, let longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    func setLocation(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }

    /// Full-resolution image URL on disk.
    var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}
