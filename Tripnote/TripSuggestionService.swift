//
//  TripSuggestionService.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import CoreLocation

/// Given a photo's EXIF-derived date and location, suggests the most likely existing
/// Trip it belongs to — so the user isn't manually filing every capture.
enum TripSuggestionService {

    /// Photos within this many hours of a trip's date range still count as a match
    /// (covers travel days that fall just outside the "official" trip dates).
    private static let dateBufferHours: TimeInterval = 24

    /// Photos within this radius of another photo already in the trip count as a location match.
    private static let locationMatchRadiusMeters: CLLocationDistance = 50_000 // ~30 miles

    static func suggestedTrip(for photo: Photo, from trips: [Trip]) -> Trip? {
        guard let capturedDate = photo.capturedDate else {
            return locationMatch(for: photo, from: trips)
        }

        let dateMatches = trips.filter { trip in
            isDate(capturedDate, within: dateBufferHours, ofRangeStart: trip.startDate, end: trip.endDate)
        }

        // If exactly one trip's date range fits, that's a confident match.
        if dateMatches.count == 1 {
            return dateMatches.first
        }

        // Multiple or zero date matches — narrow down with location if we have it.
        if dateMatches.count > 1, let byLocation = locationMatch(for: photo, from: dateMatches) {
            return byLocation
        }

        return dateMatches.first ?? locationMatch(for: photo, from: trips)
    }

    private static func isDate(_ date: Date, within bufferHours: TimeInterval, ofRangeStart start: Date, end: Date?) -> Bool {
        let buffer = bufferHours * 3600
        let rangeEnd = end ?? start
        return date >= start.addingTimeInterval(-buffer) && date <= rangeEnd.addingTimeInterval(buffer)
    }

    private static func locationMatch(for photo: Photo, from trips: [Trip]) -> Trip? {
        guard let photoLocation = photo.location else { return nil }

        for trip in trips {
            let tripPhotoLocations = (trip.notes ?? []).flatMap { $0.photos ?? [] }.compactMap(\.location)
            if tripPhotoLocations.contains(where: { $0.distance(from: photoLocation) <= locationMatchRadiusMeters }) {
                return trip
            }
        }
        return nil
    }
}
