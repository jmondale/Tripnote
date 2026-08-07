//
//  TripnoteApp.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//

import SwiftUI
import SwiftData

@main
struct TripnoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self])
    }
}
