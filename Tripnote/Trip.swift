import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var tripDescription: String?

    // A trip contains notes directly, and optionally groups them further into events.
    @Relationship(deleteRule: .cascade, inverse: \Note.trip)
    var notes: [Note] = []

    @Relationship(deleteRule: .cascade, inverse: \TripEvent.trip)
    var events: [TripEvent] = []

    init(name: String, startDate: Date = .now, endDate: Date? = nil, tripDescription: String? = nil) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.tripDescription = tripDescription
    }

    /// Cover photo defaults to the first photo of the earliest note, if one exists.
    var coverPhoto: Photo? {
        notes.sorted { $0.createdDate < $1.createdDate }.first?.photos.first
    }
}
