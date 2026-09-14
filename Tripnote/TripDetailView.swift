//
//  TripDetailView.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData
import UIKit
import CoreLocation

struct TripDetailView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Environment(EntitlementManager.self) private var entitlements

    @State private var isImporting = false
    @State private var importError: String?
    @State private var isPresentingEditTrip = false
    @State private var exportedPDFURL: URL?
    @State private var isPresentingPaywall = false

    private var sortedNotes: [Note] {
        (trip.notes ?? []).sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            Divider()
            if (trip.notes ?? []).isEmpty {
                ContentUnavailableView {
                    Label("No Notes Yet", systemImage: "note.text")
                } description: {
                    Text("Add a note or photos to start capturing this trip.")
                } actions: {
                    Button("Add Note") {
                        addTextNote()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(sortedNotes) { note in
                        NoteCardView(note: note)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteNote(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteNote(note)
                                } label: {
                                    Label("Delete Note", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { locationManager.requestLocation() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if entitlements.isPro {
                        exportedPDFURL = try? TripExporter.exportPDF(for: trip)
                    } else {
                        isPresentingPaywall = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share Trip")
                .disabled((trip.notes ?? []).isEmpty)
            }
        }
        .sheet(isPresented: $isPresentingEditTrip) {
            EditTripSheet(trip: trip)
        }
        .sheet(item: Binding(
            get: { exportedPDFURL.map(ShareableURL.init) },
            set: { exportedPDFURL = $0?.url }
        )) { item in
            ShareView(url: item.url)
                .ignoresSafeArea()
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
        .sheet(isPresented: $isPresentingPaywall) {
            ProPaywallSheet(triggerFeature: "PDF Export")
        }
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
                // Prefer EXIF location; fall back to current device location.
                if let loc = (note.photos ?? []).first?.location ?? locationManager.lastLocation {
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
        if let loc = locationManager.lastLocation {
            note.setLocation(loc)
        }
        modelContext.insert(note)
    }

    /// Every batch of picked photos becomes one new Note, so a single capture moment
    /// (e.g. three shots of the same waterfall) stays grouped together. The user can
    /// edit the note's text afterward from the note card.
    private func handlePickedPhotos(_ pickedPhotos: [PickedPhoto]) {
        guard !pickedPhotos.isEmpty else { return }
        isImporting = true

        Task { @MainActor in
            let note = Note(trip: trip)
            modelContext.insert(note)

            var firstAssetLocation: CLLocation?
            for picked in pickedPhotos {
                do {
                    let photo = try PhotoImportService.importPhoto(from: picked.data, note: note)
                    modelContext.insert(photo)
                    if firstAssetLocation == nil {
                        // Prefer EXIF GPS embedded in the image; then the PHAsset location
                        // recovered from the asset (PHPicker strips EXIF, so this is the
                        // reliable source for library photos).
                        firstAssetLocation = photo.location ?? picked.location
                    }
                } catch {
                    importError = "One or more photos couldn't be imported."
                }
            }

            // Use the photo's own location — not the current device location — so that
            // retroactively imported photos reflect where they were actually taken.
            if let loc = firstAssetLocation {
                note.setLocation(loc)
            }

            isImporting = false
        }
    }

    private func deleteNote(_ note: Note) {
        for photo in note.photos ?? [] {
            PhotoImportService.deleteFile(for: photo)
        }
        modelContext.delete(note)
    }
}

private struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
