//
//  ContentView.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(AppNavigationModel.self) private var navigationModel

    var body: some View {
        @Bindable var nav = navigationModel
        TabView(selection: $nav.selectedTab) {
            TripListView()
                .tabItem { Label("Trips", systemImage: "map") }
                .tag(0)

            CaptureView()
                .tabItem { Label("Capture", systemImage: "camera") }
                .tag(1)

            TripMapView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(2)
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { hasSeenOnboarding = !$0 }
        )) {
            OnboardingView { hasSeenOnboarding = true }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self], inMemory: true)
}
