//
//  Note.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Note {
    // Default values are required for CloudKit compatibility.
    var id: UUID = UUID()
    var text: String = ""
    var createdDate: Date = Date.now

    // Optional location for the note itself (may be inferred from its first photo's EXIF data).
    var latitude: Double?
    var longitude: Double?

    var trip: Trip?
    var event: TripEvent?

    @Relationship(deleteRule: .cascade, inverse: \Photo.note)
    var photos: [Photo]? = nil

    init(text: String = "", createdDate: Date = .now, trip: Trip? = nil, event: TripEvent? = nil) {
        self.id = UUID()
        self.text = text
        self.createdDate = createdDate
        self.trip = trip
        self.event = event
    }

    var location: CLLocation? {
        guard let latitude, let longitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    /// Convenience for setting location from a CLLocation (e.g. pulled from photo EXIF).
    func setLocation(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
}
