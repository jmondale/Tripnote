//
//  TripDetailView.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var modelContext

    @State private var isImporting = false
    @State private var importError: String?
    @State private var isPresentingEditTrip = false

    private var sortedNotes: [Note] {
        trip.notes.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            Divider()
            if trip.notes.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "note.text",
                    description: Text("Add a note or photos to start capturing this trip.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(sortedNotes) { note in
                        NoteCardView(note: note)
                    }
                    .onDelete(perform: deleteNotes)
                }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isPresentingEditTrip) {
            EditTripSheet(trip: trip)
        }
        .overlay {
            if isImporting {
                ProgressView("Importing…")
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Import Failed", isPresented: .constant(importError != nil), actions: {
            Button("OK") { importError = nil }
        }, message: {
            Text(importError ?? "")
        })
    }

    private var actionBar: some View {
        HStack(spacing: 24) {
            Spacer()
            Button { isPresentingEditTrip = true } label: {
                Label("Edit Trip", systemImage: "pencil")
            }
            Button { addTextNote() } label: {
                Label("Note", systemImage: "square.and.pencil")
            }
            CameraCaptureButton(onCapture: handleCapturedPhoto, label: "Camera", systemImage: "camera")
            PhotoPickerButton(onPick: handlePickedPhotos, label: "Photos", systemImage: "photo.badge.plus")
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 18))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func handleCapturedPhoto(_ data: Data) {
        isImporting = true
        Task { @MainActor in
            let note = Note(trip: trip)
            modelContext.insert(note)
            do {
                let photo = try PhotoImportService.importPhoto(from: data, note: note)
                modelContext.insert(photo)
                if note.location == nil, let loc = note.photos.first?.location {
                    note.setLocation(loc)
                }
            } catch {
                importError = "Photo couldn't be imported."
            }
            isImporting = false
        }
    }

    private func addTextNote() {
        let note = Note(trip: trip)
        modelContext.insert(note)
    }

    /// Every batch of picked photos becomes one new Note, so a single capture moment
    /// (e.g. three shots of the same waterfall) stays grouped together. The user can
    /// edit the note's text afterward from the note card.
    private func handlePickedPhotos(_ dataItems: [Data]) {
        guard !dataItems.isEmpty else { return }
        isImporting = true

        Task { @MainActor in
            let note = Note(trip: trip)
            modelContext.insert(note)

            for data in dataItems {
                do {
                    let photo = try PhotoImportService.importPhoto(from: data, note: note)
                    modelContext.insert(photo)
                } catch {
                    importError = "One or more photos couldn't be imported."
                }
            }

            // If the note ended up with no location, inherit one from its first photo.
            if note.location == nil, let firstPhotoLocation = note.photos.first?.location {
                note.setLocation(firstPhotoLocation)
            }

            isImporting = false
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let note = sortedNotes[index]
            for photo in note.photos {
                PhotoImportService.deleteFile(for: photo)
            }
            modelContext.delete(note)
        }
    }
}

private struct EditTripSheet: View {
    @Bindable var trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    init(trip: Trip) {
        self.trip = trip
        _name = State(initialValue: trip.name)
        _startDate = State(initialValue: trip.startDate)
        _hasEndDate = State(initialValue: trip.endDate != nil)
        _endDate = State(initialValue: trip.endDate ?? trip.startDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Trip Name", text: $name)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Multi-day trip", isOn: $hasEndDate.animation())
                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        trip.name = name
                        trip.startDate = startDate
                        trip.endDate = hasEndDate ? endDate : nil
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TripDetailView(trip: Trip(name: "Grand Canyon River Trip"))
    }
    .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self], inMemory: true)
}
