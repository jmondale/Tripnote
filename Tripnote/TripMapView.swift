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
    @Query private var allPhotos: [Photo]
    @State private var selectedPhoto: Photo?

    private var geoPhotos: [Photo] {
        allPhotos.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if geoPhotos.isEmpty {
                    ContentUnavailableView {
                        Label("No Locations Yet", systemImage: "map.fill")
                    } description: {
                        Text("Photos with GPS data will appear as pins on the map.")
                    }
                } else {
                    Map {
                        ForEach(geoPhotos) { photo in
                            Annotation(
                                photo.note?.trip?.name ?? "",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: photo.latitude!,
                                    longitude: photo.longitude!
                                ),
                                anchor: .bottom
                            ) {
                                photoPin(photo)
                                    .onTapGesture { selectedPhoto = photo }
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                }
            }
            .navigationTitle("Map")
            .fullScreenCover(item: $selectedPhoto) { photo in
                let photos = photo.note?.photos ?? [photo]
                let index = photos.firstIndex(where: { $0.id == photo.id }) ?? 0
                PhotoViewerView(photos: photos, initialIndex: index)
            }
        }
    }

    @ViewBuilder
    private func photoPin(_ photo: Photo) -> some View {
        if let data = photo.thumbnailData, let uiImage = UIImage(data: data) {
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
