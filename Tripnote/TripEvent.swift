//
//  TripEvent.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import SwiftData

/// Named `TripEvent` rather than `Event` to avoid colliding with EventKit's `EKEvent`
/// and Swift/Combine's `Event`-adjacent types.
@Model
final class TripEvent {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date.now
    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \Note.event)
    var notes: [Note]? = nil

    init(name: String, date: Date = .now, trip: Trip? = nil) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.trip = trip
    }
}
