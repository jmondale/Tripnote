//
//  TripMapView.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/24/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import MapKit
import SwiftData

struct TripMapView: View {
    @Environment(LocationManager.self) private var locationManager
    @Query private var allNotes: [Note]
    @State private var selectedNote: Note?

    private var geoNotes: [Note] {
        allNotes.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if geoNotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Locations Yet", systemImage: "map.fill")
                    } description: {
                        Text("Notes and photos will appear as pins once location access is granted.")
                    }
                } else {
                    Map {
                        ForEach(geoNotes) { note in
                            Annotation(
                                note.trip?.name ?? "",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: note.latitude!,
                                    longitude: note.longitude!
                                ),
                                anchor: .bottom
                            ) {
                                notePin(note)
                                    .onTapGesture {
                                        if !(note.photos ?? []).isEmpty {
                                            selectedNote = note
                                        }
                                    }
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                }
            }
            .navigationTitle("Map")
            .onAppear { locationManager.requestLocation() }
            .fullScreenCover(item: $selectedNote) { note in
                PhotoViewerView(photos: note.photos ?? [], initialIndex: 0)
            }
        }
    }

    @ViewBuilder
    private func notePin(_ note: Note) -> some View {
        if let data = (note.photos ?? []).first?.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(radius: 3)
        } else {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.red, .white)
                .symbolRenderingMode(.palette)
        }
    }
}

#Preview {
    TripMapView()
        .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self], inMemory: true)
}
