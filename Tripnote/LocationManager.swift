//
//  LocationManager.swift
//  Trailnote
//
//  Created by Jaye Mondale on 8/27/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import CoreLocation
import Observation

/// Holds the most recent device location so note-creation paths can tag
/// notes with coordinates even when photos don't carry EXIF GPS data.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    /// The most recently received location. Updated after every successful fix.
    private(set) var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Asks for permission the first time; requests a one-shot fix on subsequent calls.
    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location is supplementary — fail silently.
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
