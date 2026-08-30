//
//  PhotoPickerButton.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import PhotosUI
import Photos
import CoreLocation

/// Image data paired with its PHAsset-derived location (which PHPicker strips from the
/// raw data for privacy). Location is nil if the photo has no GPS tag or the asset
/// cannot be fetched.
struct PickedPhoto {
    let data: Data
    let location: CLLocation?
}

/// Wraps the native SwiftUI `PhotosPicker` to select one or more images and hand back
/// each image's data alongside its original GPS location from the PHAsset.
struct PhotoPickerButton: View {
    let onPick: ([PickedPhoto]) -> Void
    var selectionLimit: Int = 0 // 0 = no limit
    var label: String = "Add Photos"
    var systemImage: String = "photo.badge.plus"

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false

    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: selectionLimit == 0 ? nil : selectionLimit,
            matching: .images
        ) {
            Label(label, systemImage: systemImage)
        }
        .disabled(isLoading)
        .onChange(of: selectedItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            loadData(from: newItems)
        }
    }

    private func loadData(from items: [PhotosPickerItem]) {
        isLoading = true
        Task {
            var results: [PickedPhoto] = []
            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                // PHPicker strips GPS from the returned image bytes. Look it up from the
                // PHAsset using the item's stable local identifier instead.
                var location: CLLocation?
                if let identifier = item.itemIdentifier {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                    location = assets.firstObject?.location
                }
                results.append(PickedPhoto(data: data, location: location))
            }
            await MainActor.run {
                onPick(results)
                selectedItems = []
                isLoading = false
            }
        }
    }
}
