import SwiftUI

struct NoteCardView: View {
    @Bindable var note: Note

    @State private var viewerIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !note.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(note.photos.enumerated()), id: \.element.id) { index, photo in
                            thumbnail(for: photo)
                                .onTapGesture { viewerIndex = index }
                        }
                    }
                }
            }

            TextField("Add a note…", text: $note.text, axis: .vertical)
                .font(.body)

            Text(note.createdDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .fullScreenCover(isPresented: Binding(
            get: { viewerIndex != nil },
            set: { if !$0 { viewerIndex = nil } }
        )) {
            PhotoViewerView(photos: note.photos, initialIndex: viewerIndex ?? 0)
        }
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
