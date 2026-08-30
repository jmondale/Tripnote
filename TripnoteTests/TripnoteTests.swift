//
//  TripnoteTests.swift
//  TripnoteTests
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Testing
import SwiftData
import CoreLocation
@testable import Tripnote

// MARK: - Shared helpers

private func makeTestContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Trip.self, TripEvent.self, Note.self, Photo.self,
        configurations: config
    )
    return ModelContext(container)
}

private func date(daysFromNow days: Double) -> Date {
    Date.now.addingTimeInterval(days * 86_400)
}

// MARK: - TripSuggestionService: date matching

@Suite("TripSuggestionService — date matching")
struct TripSuggestionDateTests {
    let context: ModelContext

    init() throws { context = try makeTestContext() }

    @Test("Returns nil when no trips exist")
    func noTrips() throws {
        let photo = Photo(fileName: "a.jpg", capturedDate: .now)
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: []) == nil)
    }

    @Test("Matches photo whose date falls inside the trip range")
    func dateInsideRange() throws {
        let trip = Trip(name: "T", startDate: date(daysFromNow: -5), endDate: date(daysFromNow: 5))
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg", capturedDate: date(daysFromNow: 0))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) === trip)
    }

    @Test("Matches photo within 24-hour buffer before trip start")
    func dateJustBeforeStart() throws {
        let start = date(daysFromNow: 0)
        let trip = Trip(name: "T", startDate: start)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg", capturedDate: start.addingTimeInterval(-12 * 3600))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) === trip)
    }

    @Test("Matches photo exactly at the 24-hour buffer boundary before trip start (inclusive)")
    func dateExactlyAtBufferBoundary() throws {
        let start = date(daysFromNow: 0)
        let trip = Trip(name: "T", startDate: start)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg", capturedDate: start.addingTimeInterval(-24 * 3600))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) === trip)
    }

    @Test("Does not match photo one second past the 24-hour buffer before start")
    func dateOneSecondPastBuffer() throws {
        let start = date(daysFromNow: 0)
        let trip = Trip(name: "T", startDate: start)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg", capturedDate: start.addingTimeInterval(-24 * 3600 - 1))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) == nil)
    }

    @Test("Does not match photo more than 24 hours before trip start")
    func dateTooEarly() throws {
        let start = date(daysFromNow: 0)
        let trip = Trip(name: "T", startDate: start)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg", capturedDate: start.addingTimeInterval(-48 * 3600))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) == nil)
    }

    @Test("Matches photo within 24-hour buffer after trip end")
    func dateJustAfterEnd() throws {
        let end = date(daysFromNow: 0)
        let trip = Trip(name: "T", startDate: date(daysFromNow: -3), endDate: end)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg", capturedDate: end.addingTimeInterval(12 * 3600))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) === trip)
    }

    @Test("Does not match photo more than 24 hours after trip end")
    func dateTooLate() throws {
        let end = date(daysFromNow: 0)
        let trip = Trip(name: "T", startDate: date(daysFromNow: -3), endDate: end)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg", capturedDate: end.addingTimeInterval(48 * 3600))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) == nil)
    }

    @Test("Single-day trip (no endDate) treats startDate as both start and end of range")
    func singleDayTripNoEndDate() throws {
        let start = date(daysFromNow: 0)
        let trip = Trip(name: "T", startDate: start)
        context.insert(trip)
        // 6 hours after start is within the 24-hour post-start buffer
        let photo = Photo(fileName: "a.jpg", capturedDate: start.addingTimeInterval(6 * 3600))
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) === trip)
    }

    @Test("Returns a result when photo date matches multiple trips and no location is available")
    func multipleDateMatchesNoLocation() throws {
        let tripA = Trip(name: "A", startDate: date(daysFromNow: -2), endDate: date(daysFromNow: 2))
        let tripB = Trip(name: "B", startDate: date(daysFromNow: -2), endDate: date(daysFromNow: 2))
        context.insert(tripA)
        context.insert(tripB)
        let photo = Photo(fileName: "a.jpg", capturedDate: date(daysFromNow: 0))
        context.insert(photo)
        let suggestion = TripSuggestionService.suggestedTrip(for: photo, from: [tripA, tripB])
        #expect(suggestion == tripA || suggestion == tripB)
    }

    @Test("Returns nil when photo has no date and no location")
    func noDateNoLocation() throws {
        let trip = Trip(name: "T", startDate: .now)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg")
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) == nil)
    }

    @Test("Falls back to location match when photo has a date that matches no trip's range")
    func dateWithNoMatchFallsBackToLocation() throws {
        // Trip ended 30 days ago
        let trip = Trip(name: "Paris Trip", startDate: date(daysFromNow: -35), endDate: date(daysFromNow: -30))
        context.insert(trip)
        let note = Note()
        context.insert(note)
        note.trip = trip
        let existingPhoto = Photo(fileName: "existing.jpg")
        context.insert(existingPhoto)
        existingPhoto.note = note
        existingPhoto.setLocation(CLLocation(latitude: 48.8566, longitude: 2.3522))

        // New photo taken today (outside the trip's date range) but geographically near the trip
        let newPhoto = Photo(fileName: "new.jpg", capturedDate: date(daysFromNow: 0))
        context.insert(newPhoto)
        newPhoto.setLocation(CLLocation(latitude: 48.8600, longitude: 2.3500))

        // Date matching fails; service should fall back to location
        #expect(TripSuggestionService.suggestedTrip(for: newPhoto, from: [trip]) === trip)
    }
}

// MARK: - TripSuggestionService: location matching

@Suite("TripSuggestionService — location matching")
struct TripSuggestionLocationTests {
    let context: ModelContext

    init() throws { context = try makeTestContext() }

    @Test("Falls back to location when photo has no date and is near a trip photo")
    func locationMatchNoDate() throws {
        let trip = Trip(name: "Paris Trip", startDate: .now)
        context.insert(trip)
        let note = Note()
        context.insert(note)
        note.trip = trip
        let existing = Photo(fileName: "existing.jpg")
        context.insert(existing)
        existing.note = note
        existing.setLocation(CLLocation(latitude: 48.8566, longitude: 2.3522)) // Paris

        let newPhoto = Photo(fileName: "new.jpg") // ~400 m away, no date
        context.insert(newPhoto)
        newPhoto.setLocation(CLLocation(latitude: 48.8600, longitude: 2.3500))

        #expect(TripSuggestionService.suggestedTrip(for: newPhoto, from: [trip]) === trip)
    }

    @Test("Does not match photo that is far from all trip photos")
    func locationTooFar() throws {
        let trip = Trip(name: "Paris Trip", startDate: .now)
        context.insert(trip)
        let note = Note()
        context.insert(note)
        note.trip = trip
        let existing = Photo(fileName: "existing.jpg")
        context.insert(existing)
        existing.note = note
        existing.setLocation(CLLocation(latitude: 48.8566, longitude: 2.3522)) // Paris

        let newPhoto = Photo(fileName: "new.jpg") // Tokyo, no date
        context.insert(newPhoto)
        newPhoto.setLocation(CLLocation(latitude: 35.6762, longitude: 139.6503))

        #expect(TripSuggestionService.suggestedTrip(for: newPhoto, from: [trip]) == nil)
    }

    @Test("Uses location to pick the right trip when date matches multiple")
    func locationBreaksTie() throws {
        let parisTrip = Trip(name: "Paris", startDate: date(daysFromNow: -2), endDate: date(daysFromNow: 2))
        let tokyoTrip = Trip(name: "Tokyo", startDate: date(daysFromNow: -2), endDate: date(daysFromNow: 2))
        context.insert(parisTrip)
        context.insert(tokyoTrip)

        let parisNote = Note()
        context.insert(parisNote)
        parisNote.trip = parisTrip
        let parisPhoto = Photo(fileName: "paris.jpg")
        context.insert(parisPhoto)
        parisPhoto.note = parisNote
        parisPhoto.setLocation(CLLocation(latitude: 48.8566, longitude: 2.3522))

        let tokyoNote = Note()
        context.insert(tokyoNote)
        tokyoNote.trip = tokyoTrip
        let tokyoPhoto = Photo(fileName: "tokyo.jpg")
        context.insert(tokyoPhoto)
        tokyoPhoto.note = tokyoNote
        tokyoPhoto.setLocation(CLLocation(latitude: 35.6762, longitude: 139.6503))

        let newPhoto = Photo(fileName: "new.jpg", capturedDate: date(daysFromNow: 0))
        context.insert(newPhoto)
        newPhoto.setLocation(CLLocation(latitude: 48.8600, longitude: 2.3500)) // near Paris

        #expect(TripSuggestionService.suggestedTrip(for: newPhoto, from: [parisTrip, tokyoTrip]) === parisTrip)
    }

    @Test("Returns nil when photo has no location and trip has no photos to compare against")
    func noPhotoLocationNoTripPhotos() throws {
        let trip = Trip(name: "T", startDate: .now)
        context.insert(trip)
        let photo = Photo(fileName: "a.jpg") // no date, no location
        context.insert(photo)
        #expect(TripSuggestionService.suggestedTrip(for: photo, from: [trip]) == nil)
    }
}

// MARK: - PhotoMetadataExtractor

@Suite("PhotoMetadataExtractor")
struct PhotoMetadataExtractorTests {

    @Test("Returns nil metadata for empty data")
    func emptyData() {
        let result = PhotoMetadataExtractor.extract(from: Data())
        #expect(result.capturedDate == nil)
        #expect(result.location == nil)
    }

    @Test("Returns nil metadata for non-image bytes")
    func invalidData() {
        let result = PhotoMetadataExtractor.extract(from: Data([0xFF, 0x00, 0xAB]))
        #expect(result.capturedDate == nil)
        #expect(result.location == nil)
    }

    @Test("Returns nil metadata for valid PNG with no EXIF")
    func pngWithNoExif() {
        // Minimal 1×1 white PNG (no EXIF block)
        let pngBytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // width=1, height=1
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // bit depth, color type, ...
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
            0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81,
            0x84, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND
            0x44, 0xAE, 0x42, 0x60, 0x82
        ]
        let result = PhotoMetadataExtractor.extract(from: Data(pngBytes))
        #expect(result.capturedDate == nil)
        #expect(result.location == nil)
    }
}

// MARK: - Photo model

@Suite("Photo")
struct PhotoTests {

    @Test("location is nil when coordinates are not set")
    func noLocation() {
        let photo = Photo(fileName: "a.jpg")
        #expect(photo.location == nil)
    }

    @Test("location returns correct coordinates after setLocation")
    func locationRoundTrip() {
        let photo = Photo(fileName: "a.jpg")
        photo.setLocation(CLLocation(latitude: 51.5074, longitude: -0.1278)) // London
        #expect(abs((photo.location?.coordinate.latitude  ?? 0) - 51.5074)   < 0.0001)
        #expect(abs((photo.location?.coordinate.longitude ?? 0) - (-0.1278)) < 0.0001)
    }

    @Test("setLocation overwrites a previously set location")
    func locationOverwrite() {
        let photo = Photo(fileName: "a.jpg")
        photo.setLocation(CLLocation(latitude: 48.8566, longitude: 2.3522)) // Paris
        photo.setLocation(CLLocation(latitude: 35.6762, longitude: 139.6503)) // Tokyo
        #expect(abs((photo.location?.coordinate.latitude  ?? 0) - 35.6762)   < 0.0001)
        #expect(abs((photo.location?.coordinate.longitude ?? 0) - 139.6503)  < 0.0001)
    }

    @Test("fileURL is inside the Documents/Photos directory")
    func fileURL() {
        let photo = Photo(fileName: "abc123.jpg")
        #expect(photo.fileURL.lastPathComponent == "abc123.jpg")
        #expect(photo.fileURL.path.contains("/Photos/"))
    }

    @Test("fileURL last component matches the fileName exactly")
    func fileURLMatchesFileName() {
        let name = "unique-\(UUID().uuidString).jpg"
        let photo = Photo(fileName: name)
        #expect(photo.fileURL.lastPathComponent == name)
    }

    @Test("capturedDate is stored and retrievable from init")
    func capturedDateInit() {
        let now = Date.now
        let photo = Photo(fileName: "a.jpg", capturedDate: now)
        #expect(photo.capturedDate == now)
    }
}

// MARK: - Note model

@Suite("Note")
struct NoteTests {

    @Test("location is nil when coordinates are not set")
    func noLocation() {
        let note = Note()
        #expect(note.location == nil)
    }

    @Test("location returns correct coordinates after setLocation")
    func locationRoundTrip() {
        let note = Note()
        note.setLocation(CLLocation(latitude: 37.7749, longitude: -122.4194)) // San Francisco
        #expect(abs((note.location?.coordinate.latitude  ?? 0) - 37.7749)     < 0.0001)
        #expect(abs((note.location?.coordinate.longitude ?? 0) - (-122.4194)) < 0.0001)
    }

    @Test("setLocation overwrites a previously set location")
    func locationOverwrite() {
        let note = Note()
        note.setLocation(CLLocation(latitude: 37.7749, longitude: -122.4194))
        note.setLocation(CLLocation(latitude: 51.5074, longitude: -0.1278)) // London
        #expect(abs((note.location?.coordinate.latitude  ?? 0) - 51.5074)   < 0.0001)
        #expect(abs((note.location?.coordinate.longitude ?? 0) - (-0.1278)) < 0.0001)
    }

    @Test("Default init produces empty text")
    func defaultText() {
        let note = Note()
        #expect(note.text == "")
    }

    @Test("Text is stored correctly from init")
    func textInit() {
        let note = Note(text: "Beautiful sunset.")
        #expect(note.text == "Beautiful sunset.")
    }
}

// MARK: - Trip model

@Suite("Trip")
struct TripTests {
    let context: ModelContext

    init() throws { context = try makeTestContext() }

    @Test("coverPhoto is nil when trip has no notes")
    func coverPhotoNoNotes() throws {
        let trip = Trip(name: "Empty Trip", startDate: .now)
        context.insert(trip)
        #expect(trip.coverPhoto == nil)
    }

    @Test("coverPhoto is nil when notes have no photos")
    func coverPhotoNoPhotos() throws {
        let trip = Trip(name: "T", startDate: .now)
        context.insert(trip)
        let note = Note()
        context.insert(note)
        note.trip = trip
        #expect(trip.coverPhoto == nil)
    }

    @Test("coverPhoto returns the first photo of the earliest note")
    func coverPhotoReturnsEarliestNoteFirstPhoto() throws {
        let trip = Trip(name: "T", startDate: .now)
        context.insert(trip)

        let earlierNote = Note(createdDate: date(daysFromNow: -2))
        context.insert(earlierNote)
        earlierNote.trip = trip

        let laterNote = Note(createdDate: date(daysFromNow: -1))
        context.insert(laterNote)
        laterNote.trip = trip

        let firstPhoto = Photo(fileName: "first.jpg")
        context.insert(firstPhoto)
        firstPhoto.note = earlierNote
        firstPhoto.thumbnailData = Data([0x01])

        let secondPhoto = Photo(fileName: "second.jpg")
        context.insert(secondPhoto)
        secondPhoto.note = laterNote
        secondPhoto.thumbnailData = Data([0x02])

        #expect(trip.coverPhoto === firstPhoto)
    }

    @Test("formattedDateRange shows a single date for a trip with no endDate")
    func formattedDateRangeSingleDay() throws {
        let trip = Trip(name: "T", startDate: .now)
        context.insert(trip)
        let result = trip.formattedDateRange
        #expect(!result.isEmpty)
        #expect(!result.contains("–"))
    }

    @Test("formattedDateRange contains an en-dash for a multi-day trip")
    func formattedDateRangeMultiDay() throws {
        let start = Date.now
        let end = Calendar.current.date(byAdding: .day, value: 5, to: start)!
        let trip = Trip(name: "T", startDate: start, endDate: end)
        context.insert(trip)
        #expect(trip.formattedDateRange.contains("–"))
    }

    @Test("formattedDateRange shows a single date when endDate is the same calendar day as startDate")
    func formattedDateRangeSameCalendarDay() throws {
        let start = Calendar.current.startOfDay(for: .now)
        let end = start.addingTimeInterval(3 * 3600) // 3 hours later, same day
        let trip = Trip(name: "T", startDate: start, endDate: end)
        context.insert(trip)
        #expect(!trip.formattedDateRange.contains("–"))
    }
}

// MARK: - TripEvent model

@Suite("TripEvent")
struct TripEventTests {

    @Test("Init stores name and date correctly")
    func initSetsFields() {
        let now = Date.now
        let event = TripEvent(name: "Sunset Hike", date: now)
        #expect(event.name == "Sunset Hike")
        #expect(event.date == now)
        #expect(event.trip == nil)
        #expect(event.notes == nil)
    }

    @Test("Default date is approximately now")
    func defaultDateIsNow() {
        let before = Date.now
        let event = TripEvent(name: "E")
        let after = Date.now
        #expect(event.date >= before)
        #expect(event.date <= after)
    }
}

// MARK: - WidgetDataManager.LatestTripData

@Suite("WidgetDataManager.LatestTripData")
struct WidgetDataManagerTests {

    @Test("Codable round-trip preserves all fields including thumbnail data")
    func codableRoundTrip() throws {
        let original = WidgetDataManager.LatestTripData(
            name: "Grand Canyon",
            dateRange: "Aug 1 – Aug 5, 2026",
            thumbnailData: Data([0x01, 0x02, 0x03])
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetDataManager.LatestTripData.self, from: encoded)
        #expect(decoded.name == original.name)
        #expect(decoded.dateRange == original.dateRange)
        #expect(decoded.thumbnailData == original.thumbnailData)
    }

    @Test("Codable round-trip preserves nil thumbnailData")
    func codableRoundTripNilThumbnail() throws {
        let original = WidgetDataManager.LatestTripData(
            name: "Solo Trek",
            dateRange: "Sep 10, 2026",
            thumbnailData: nil
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetDataManager.LatestTripData.self, from: encoded)
        #expect(decoded.name == original.name)
        #expect(decoded.dateRange == original.dateRange)
        #expect(decoded.thumbnailData == nil)
    }

    @Test("Encoded JSON contains expected keys")
    func encodedJSONKeys() throws {
        let payload = WidgetDataManager.LatestTripData(name: "T", dateRange: "Jan 1", thumbnailData: nil)
        let encoded = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        #expect(json?["name"] as? String == "T")
        #expect(json?["dateRange"] as? String == "Jan 1")
    }
}
