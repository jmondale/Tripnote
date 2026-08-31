//
//  CaptureReviewSheet.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData

struct CaptureReviewSheet: View {
    let photos: [Photo]
    let suggestedTrip: Trip?
    let allTrips: [Trip]
    let onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppNavigationModel.self) private var navigationModel

    // UUID-based selection avoids SwiftData model identity issues with Picker tags.
    // The Picker tags UUID values (reliable Equatable), and selectedTrip resolves it to a Trip.
    @State private var selectedTripID: UUID?
    @State private var isCreatingNewTrip = false
    @State private var newTripName = ""
    @State private var noteText = ""
    @State private var isSaving = false

    private var selectedTrip: Trip? {
        guard let id = selectedTripID else { return nil }
        return allTrips.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(photos) { photo in
                                if let data = photo.thumbnailData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(8)
                }

                Section("Note") {
                    TextField("Add a note…", text: $noteText, axis: .vertical)
                }

                Section("Trip") {
                    if let suggestedTrip, selectedTripID == suggestedTrip.id {
                        Label("Suggested: \(suggestedTrip.name)", systemImage: "wand.and.stars")
                            .foregroundStyle(.tint)
                    }

                    Picker("Trip", selection: $selectedTripID) {
                        Text("None").tag(nil as UUID?)
                        ForEach(allTrips) { trip in
                            Text(trip.name).tag(trip.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Create New Trip", isOn: $isCreatingNewTrip.animation())
                    if isCreatingNewTrip {
                        TextField("Trip Name", text: $newTripName)
                    }
                }
            }
            .navigationTitle("Review Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        for photo in photos {
                            PhotoImportService.deleteFile(for: photo)
                        }
                        onFinished()
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Saving…")
                            .padding(20)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .onAppear {
                selectedTripID = suggestedTrip?.id
            }
        }
    }

    private var canSave: Bool {
        isCreatingNewTrip ? !newTripName.trimmingCharacters(in: .whitespaces).isEmpty : selectedTripID != nil
    }

    @MainActor
    private func save() async {
        isSaving = true

        let trip: Trip
        if isCreatingNewTrip {
            let earliestCapture = photos.compactMap(\.capturedDate).min() ?? .now
            trip = Trip(name: newTripName, startDate: earliestCapture)
            modelContext.insert(trip)
        } else if let selectedTrip {
            trip = selectedTrip
        } else {
            isSaving = false
            return // canSave guards this, but stay defensive.
        }

        let note = Note(text: noteText, trip: trip)
        modelContext.insert(note)

        for photo in photos {
            photo.note = note
            modelContext.insert(photo)
        }

        // Use the local photos array for location since the relationship
        // may not be populated yet by SwiftData at this point.
        if note.location == nil, let firstPhotoLocation = photos.first?.location {
            note.setLocation(firstPhotoLocation)
        }

        // Brief pause so SwiftData can write through before the destination view loads.
        try? await Task.sleep(for: .milliseconds(300))

        // Switch to Trips tab and push into the trip's detail view.
        navigationModel.tripsPath = [trip]
        navigationModel.selectedTab = 0

        onFinished()
        dismiss()
    }
}
