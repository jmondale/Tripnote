//
//  AppNavigationModel.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/30/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation

/// Shared navigation state injected via environment so any view can switch tabs
/// or push onto the Trips NavigationStack programmatically.
@Observable
final class AppNavigationModel {
    /// The currently selected tab. 0 = Trips, 1 = Capture, 2 = Map.
    var selectedTab: Int = 0

    /// The navigation path for TripListView's NavigationStack.
    /// Append a Trip to navigate directly to its detail view.
    var tripsPath: [Trip] = []
}
