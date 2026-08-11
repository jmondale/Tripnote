//
//  NoteCardView.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData

struct NoteCardView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext

    @State private var viewerIndex: Int?
    @FocusState private var isTextFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !note.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(note.photos.enumerated()), id: \.element.id) { index, photo in
                            thumbnail(for: photo)
                                .onTapGesture { viewerIndex = index }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deletePhoto(photo)
                                    } label: {
                                        Label("Delete Photo", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
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
                  note.photos.isEmpty
            else { return }
            modelContext.delete(note)
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewerIndex != nil },
            set: { if !$0 { viewerIndex = nil } }
        )) {
            PhotoViewerView(photos: note.photos, initialIndex: viewerIndex ?? 0)
        }
    }

    private func deletePhoto(_ photo: Photo) {
        PhotoImportService.deleteFile(for: photo)
        modelContext.delete(photo)
    }

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
}
