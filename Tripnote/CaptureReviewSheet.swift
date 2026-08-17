//
//  CaptureReviewSheet.swift
//  Tripnote
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

    @State private var selectedTrip: Trip?
    @State private var isCreatingNewTrip = false
    @State private var newTripName = ""
    @State private var noteText = ""

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
                    if let suggestedTrip, selectedTrip?.id == suggestedTrip.id {
                        Label("Suggested: \(suggestedTrip.name)", systemImage: "wand.and.stars")
                            .foregroundStyle(.tint)
                    }

                    Picker("Trip", selection: $selectedTrip) {
                        Text("None").tag(nil as Trip?)
                        ForEach(allTrips) { trip in
                            Text(trip.name).tag(trip as Trip?)
                        }
                    }
                    .pickerStyle(.navigationLink)

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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                selectedTrip = suggestedTrip
            }
        }
    }

    private var canSave: Bool {
        isCreatingNewTrip ? !newTripName.trimmingCharacters(in: .whitespaces).isEmpty : selectedTrip != nil
    }

    private func save() {
        let trip: Trip
        if isCreatingNewTrip {
            let earliestCapture = photos.compactMap(\.capturedDate).min() ?? .now
            trip = Trip(name: newTripName, startDate: earliestCapture)
            modelContext.insert(trip)
        } else if let selectedTrip {
            trip = selectedTrip
        } else {
            return // canSave guards this, but stay defensive.
        }

        let note = Note(text: noteText, trip: trip)
        modelContext.insert(note)

        for photo in photos {
            photo.note = note
            modelContext.insert(photo)
        }

        if note.location == nil, let firstPhotoLocation = note.photos?.first?.location {
            note.setLocation(firstPhotoLocation)
        }

        onFinished()
        dismiss()
    }
}
