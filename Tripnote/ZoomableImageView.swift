import SwiftUI

/// A single zoomable/pannable image. Pinch to zoom, double-tap to toggle zoom,
/// drag to pan while zoomed in.
struct ZoomableImageView: View {
    let image: UIImage

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnifyGesture)
                .simultaneousGesture(dragGesture, including: scale > minScale ? .all : .subviews)
                .onTapGesture(count: 2) { toggleZoom() }
        }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
                if scale == minScale {
                    withAnimation(.spring(duration: 0.25)) {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > minScale else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func toggleZoom() {
        withAnimation(.spring(duration: 0.25)) {
            if scale > minScale {
                scale = minScale
                offset = .zero
            } else {
                scale = 2.5
            }
            lastScale = scale
            lastOffset = offset
        }
    }
}
