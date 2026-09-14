//
//  CaptureView.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData

/// The global capture flow: not tied to whichever trip you happen to have open.
/// Photos captured here get a suggested trip (via TripSuggestionService) before saving.
struct CaptureView: View {
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @Environment(EntitlementManager.self) private var entitlements

    @State private var pendingPhotos: [Photo] = []
    @State private var isImporting = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)

                Text("Capture a moment, and Journey Images will suggest which trip it belongs to.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    CameraCaptureButton(onCapture: { handlePicked([PickedPhoto(data: $0, location: nil)]) })
                        .buttonStyle(.borderedProminent)

                    PhotoPickerButton(onPick: handlePicked, label: "Choose from Library", systemImage: "photo.on.rectangle")
                        .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Capture")
            .overlay {
                if isImporting {
                    ProgressView("Importing…")
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: .constant(!pendingPhotos.isEmpty)) {
                CaptureReviewSheet(
                    photos: pendingPhotos,
                    suggestedTrip: entitlements.isPro
                        ? pendingPhotos.first.flatMap { TripSuggestionService.suggestedTrip(for: $0, from: trips) }
                        : nil,
                    allTrips: trips,
                    onFinished: { pendingPhotos = [] }
                )
            }
            .alert("Import Failed", isPresented: .constant(importError != nil), actions: {
                Button("OK") { importError = nil }
            }, message: {
                Text(importError ?? "")
            })
        }
    }

    private func handlePicked(_ pickedPhotos: [PickedPhoto]) {
        guard !pickedPhotos.isEmpty else { return }
        isImporting = true

        Task { @MainActor in
            var imported: [Photo] = []
            for picked in pickedPhotos {
                do {
                    // note: nil for now — assigned once the user confirms a trip in the review sheet.
                    let photo = try PhotoImportService.importPhoto(from: picked.data, note: nil)
                    // PHPicker strips GPS from image bytes; use the PHAsset location if available.
                    if let location = picked.location {
                        photo.setLocation(location)
                    }
                    imported.append(photo)
                } catch {
                    importError = "One or more photos couldn't be imported."
                }
            }
            pendingPhotos = imported
            isImporting = false
        }
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self], inMemory: true)
}
