import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TripListView()
                .tabItem {
                    Label("Trips", systemImage: "map")
                }

            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "camera")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self], inMemory: true)
}
