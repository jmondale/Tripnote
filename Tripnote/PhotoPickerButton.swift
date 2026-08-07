//
//  PhotoPickerButton.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import PhotosUI

/// Wraps the native SwiftUI `PhotosPicker` (PhotosUI) to select one or more images
/// and hand back raw Data for each, ready for PhotoImportService.
struct PhotoPickerButton: View {
    let onPick: ([Data]) -> Void
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
            var results: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    results.append(data)
                }
            }
            await MainActor.run {
                onPick(results)
                selectedItems = []
                isLoading = false
            }
        }
    }
}
