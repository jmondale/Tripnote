//
//  TripnoteApp.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct TripnoteApp: App {
    // Tries CloudKit-backed storage first; falls back to local-only if iCloud
    // capability is not yet configured in the project entitlements.
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([Trip.self, TripEvent.self, Note.self, Photo.self])
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]
        ) {
            return container
        }
        return try! ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema)]
        )
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
