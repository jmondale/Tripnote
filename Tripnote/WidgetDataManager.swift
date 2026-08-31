//
//  WidgetDataManager.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/24/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import WidgetKit

/// Writes a compact summary of the most recent trip into the shared App Group container
/// so the home screen widget can read it without accessing the SwiftData store.
enum WidgetDataManager {
    static let appGroupID = "group.com.jmondale.Trailnote"
    static let latestTripKey = "latestTrip"

    struct LatestTripData: Codable {
        let name: String
        let dateRange: String
        let thumbnailData: Data?
    }

    /// Call whenever the trips list changes (onCreate, onDelete, onAppear).
    static func update(with trip: Trip?) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        guard let trip else {
            defaults.removeObject(forKey: latestTripKey)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        let payload = LatestTripData(
            name: trip.name,
            dateRange: trip.formattedDateRange,
            thumbnailData: trip.coverPhoto?.thumbnailData
        )

        if let encoded = try? JSONEncoder().encode(payload) {
            defaults.set(encoded, forKey: latestTripKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
