import SwiftUI

struct PhotoViewerView: View {
    let photos: [Photo]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero

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
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    .padding()
                }
                Spacer()
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
        UIImage(contentsOfFile: photo.fileURL.path)
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
