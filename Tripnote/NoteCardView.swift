//
//  NoteCardView.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData
import PhotosUI
import Photos
import CoreLocation

struct NoteCardView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager

    @FocusState private var isTextFocused: Bool
    @State private var activeSheet: ActiveSheet?
    @State private var selectedPickerItems: [PhotosPickerItem] = []

    private enum ActiveSheet: Identifiable {
        case camera
        case viewer(index: Int)

        var id: String {
            switch self {
            case .camera: return "camera"
            case .viewer(let i): return "viewer-\(i)"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array((note.photos ?? []).enumerated()), id: \.element.id) { index, photo in
                        thumbnail(for: photo)
                            .onTapGesture { activeSheet = .viewer(index: index) }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deletePhoto(photo)
                                } label: {
                                    Label("Delete Photo", systemImage: "trash")
                                }
                            }
                    }

                    // Camera add button
                    Button { activeSheet = .camera } label: {
                        addTile(systemImage: "camera.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    // Photo library picker
                    PhotosPicker(selection: $selectedPickerItems, matching: .images) {
                        addTile(systemImage: "photo.badge.plus")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }

            TextField("Add a note…", text: $note.text, axis: .vertical)
                .font(.body)
                .focused($isTextFocused)

            Text(note.createdDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isTextFocused = false }
            }
        }
        .onChange(of: isTextFocused) { _, focused in
            guard !focused,
                  note.text.trimmingCharacters(in: .whitespaces).isEmpty,
                  (note.photos ?? []).isEmpty
            else { return }
            modelContext.delete(note)
        }
        .onChange(of: selectedPickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await addPickedPhotos(from: newItems)
                await MainActor.run { selectedPickerItems = [] }
            }
        }
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .camera:
                CameraPicker(onCapture: addCapturedPhoto)
                    .ignoresSafeArea()
            case .viewer(let index):
                PhotoViewerView(photos: note.photos ?? [], initialIndex: index)
            }
        }
    }

    // MARK: - Photo management

    private func deletePhoto(_ photo: Photo) {
        PhotoImportService.deleteFile(for: photo)
        modelContext.delete(photo)
    }

    private func addCapturedPhoto(_ data: Data) {
        Task { @MainActor in
            guard let photo = try? PhotoImportService.importPhoto(from: data, note: note) else { return }
            modelContext.insert(photo)
            if note.location == nil, let loc = locationManager.lastLocation {
                note.setLocation(loc)
            }
        }
    }

    private func addPickedPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }

            // PHPicker strips EXIF GPS — recover location from the PHAsset instead.
            var assetLocation: CLLocation?
            if let identifier = item.itemIdentifier {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                assetLocation = assets.firstObject?.location
            }

            await MainActor.run {
                guard let photo = try? PhotoImportService.importPhoto(from: data, note: note) else { return }
                modelContext.insert(photo)
                if note.location == nil, let loc = assetLocation ?? photo.location {
                    note.setLocation(loc)
                }
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func thumbnail(for photo: Photo) -> some View {
        if let data = photo.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary)
                .frame(width: 90, height: 90)
        }
    }

    private func addTile(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.quaternary)
            .frame(width: 90, height: 90)
            .overlay {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}
