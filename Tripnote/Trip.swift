//
//  Trip.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class Trip {
    // Default values are required for CloudKit compatibility.
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date.now
    var endDate: Date?
    var tripDescription: String?

    // A trip contains notes directly, and optionally groups them further into events.
    @Relationship(deleteRule: .cascade, inverse: \Note.trip)
    var notes: [Note]? = nil

    @Relationship(deleteRule: .cascade, inverse: \TripEvent.trip)
    var events: [TripEvent]? = nil

    init(name: String, startDate: Date = .now, endDate: Date? = nil, tripDescription: String? = nil) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.tripDescription = tripDescription
    }

    /// Cover photo defaults to the first photo of the earliest note, if one exists.
    var coverPhoto: Photo? {
        (notes ?? []).sorted { $0.createdDate < $1.createdDate }.first?.photos?.first
    }

    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let endDate, !Calendar.current.isDate(endDate, inSameDayAs: startDate) {
            return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
        }
        return formatter.string(from: startDate)
    }
}
