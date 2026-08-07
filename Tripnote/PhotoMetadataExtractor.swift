//
//  PhotoMetadataExtractor.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import ImageIO
import CoreLocation

/// Reads EXIF/GPS metadata directly from image bytes — no UIImage decode required,
/// which keeps this fast even for large photos.
enum PhotoMetadataExtractor {

    struct Metadata {
        let capturedDate: Date?
        let location: CLLocation?
    }

    static func extract(from data: Data) -> Metadata {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return Metadata(capturedDate: nil, location: nil)
        }

        return Metadata(capturedDate: capturedDate(from: properties), location: location(from: properties))
    }

    private static func capturedDate(from properties: [CFString: Any]) -> Date? {
        // Prefer the EXIF original capture date; fall back to TIFF's modify date.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let raw = exif[kCGImagePropertyExifDateTimeOriginal] as? String,
           let date = formatter.date(from: raw) {
            return date
        }

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let raw = tiff[kCGImagePropertyTIFFDateTime] as? String,
           let date = formatter.date(from: raw) {
            return date
        }

        return nil
    }

    private static func location(from properties: [CFString: Any]) -> CLLocation? {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              var latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              var longitude = gps[kCGImagePropertyGPSLongitude] as? Double
        else {
            return nil
        }

        if (gps[kCGImagePropertyGPSLatitudeRef] as? String) == "S" {
            latitude = -latitude
        }
        if (gps[kCGImagePropertyGPSLongitudeRef] as? String) == "W" {
            longitude = -longitude
        }

        return CLLocation(latitude: latitude, longitude: longitude)
    }
}
