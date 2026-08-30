//
//  PhotoViewerView.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import Photos

struct PhotoViewerView: View {
    let photos: [Photo]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var saveStatus: SaveStatus?

    private enum SaveStatus { case success, denied }

    init(photos: [Photo], initialIndex: Int) {
        self.photos = photos
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(dismissOpacity)
                .ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    photoPage(for: photo)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
            .offset(y: dragOffset.height)
            .simultaneousGesture(dismissGesture)

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(12)
                    }
                    .accessibilityLabel("Close")
                    .buttonStyle(.glass)
                    .padding()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        Task { await saveCurrentPhoto() }
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(12)
                    }
                    .accessibilityLabel("Save to Photos")
                    .buttonStyle(.glass)
                    .padding()
                }
            }
            if let status = saveStatus {
                VStack {
                    Spacer()
                    Label(
                        status == .success ? "Saved to Photos" : "Could not save photo",
                        systemImage: status == .success ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 80)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .statusBarHidden()
    }

    @ViewBuilder
    private func photoPage(for photo: Photo) -> some View {
        if let uiImage = fullImage(for: photo) {
            ZoomableImageView(image: uiImage)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                Text("Photo unavailable")
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func fullImage(for photo: Photo) -> UIImage? {
        // Prefer the full-resolution file; fall back to thumbnail if the file was
        // deleted (e.g. after an app reinstall wiped the Documents directory).
        if let image = UIImage(contentsOfFile: photo.fileURL.path) {
            return image
        }
        return photo.thumbnailData.flatMap { UIImage(data: $0) }
    }

    private func saveCurrentPhoto() async {
        guard currentIndex < photos.count,
              let image = fullImage(for: photos[currentIndex]) else { return }

        let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorization == .authorized || authorization == .limited else {
            withAnimation { saveStatus = .denied }
            clearSaveStatus()
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }
            withAnimation { saveStatus = .success }
        } catch {
            withAnimation { saveStatus = .denied }
        }
        clearSaveStatus()
    }

    private func clearSaveStatus() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { saveStatus = nil }
        }
    }

    /// Fades the black backdrop out as the user drags down, so the dismiss gesture feels responsive.
    private var dismissOpacity: Double {
        let progress = min(abs(dragOffset.height) / 300, 1)
        return 1 - (progress * 0.6)
    }

    private var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only track vertical drags so this doesn't fight the TabView's horizontal paging.
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                if abs(value.translation.height) > 120 {
                    dismiss()
                } else {
                    withAnimation(.spring(duration: 0.25)) {
                        dragOffset = .zero
                    }
                }
            }
    }
}

#Preview {
    PhotoViewerView(photos: [], initialIndex: 0)
}
