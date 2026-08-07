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

    private var sortedNotes: [Note] {
        trip.notes.sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        Group {
            if trip.notes.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "note.text",
                    description: Text("Add photos to start capturing this trip.")
                )
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                PhotoPickerButton(onPick: handlePickedPhotos, label: "Add", systemImage: "photo.badge.plus")
                    .labelStyle(.iconOnly)
            }
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

#Preview {
    NavigationStack {
        TripDetailView(trip: Trip(name: "Grand Canyon River Trip"))
    }
    .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self], inMemory: true)
}
