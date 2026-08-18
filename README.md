# Tripnote

A personal travel journal for iOS. Capture notes and photos on the go, organize them into trips, and share your adventures as a PDF.

## Features

- **Trips** — Create trips with a name and date range. All notes and photos are organized under trips.
- **Notes** — Add freeform text notes to any trip. Notes can stand alone or include photos.
- **Camera capture** — Shoot photos directly from the trip detail screen and attach them instantly.
- **Photo import** — Pick existing photos from your library and add them to a trip note.
- **Photo viewer** — Full-screen swipeable photo viewer with pinch-to-zoom and save-to-Photos support.
- **Smart trip suggestions** — When you capture a photo, the app uses EXIF date and GPS location to suggest the most likely trip it belongs to.
- **PDF export** — Export any trip as a formatted PDF and share it via the system share sheet.
- **iCloud sync** — Data syncs across your devices automatically via CloudKit.
- **Onboarding** — A brief 3-screen intro is shown on first launch so new users know how to get started.

## Requirements

- iOS 17+
- Xcode 16+
- Swift 5.10+
- An Apple Developer account with iCloud / CloudKit capability enabled for sync

## Architecture

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Persistence | SwiftData |
| Cloud sync | CloudKit (via `ModelConfiguration(cloudKitDatabase: .automatic)`) |
| Photo storage | On-device file system; thumbnails stored as `@Attribute(.externalStorage)` |
| PDF generation | `UIGraphicsPDFRenderer` |
| Photo metadata | `CoreLocation`, `ImageIO` (EXIF extraction) |

### Key files

| File | Purpose |
|---|---|
| `TripnoteApp.swift` | App entry point; sets up the shared `ModelContainer` with CloudKit fallback |
| `ContentView.swift` | Root `TabView`; presents onboarding on first launch |
| `TripListView.swift` | Trip list with swipe-to-delete and new trip creation |
| `TripDetailView.swift` | Notes list for a trip; action bar for edit, note, camera, and photo import |
| `NoteCardView.swift` | Editable note card with inline photo thumbnails and keyboard management |
| `PhotoViewerView.swift` | Full-screen photo viewer with zoom and save-to-Photos |
| `TripExporter.swift` | Generates a PDF from a trip's notes and photos |
| `TripSuggestionService.swift` | Suggests a trip for a newly captured photo using date + location heuristics |
| `CaptureView.swift` | Quick-capture tab for photos that aren't yet tied to a trip |
| `OnboardingView.swift` | 3-page first-launch onboarding flow |

## Getting Started

1. Clone the repository.
2. Open `Tripnote.xcodeproj` in Xcode.
3. Set your development team under **Signing & Capabilities**.
4. Add an iCloud container under **Signing & Capabilities → iCloud → CloudKit** and ensure it matches the identifier in `Tripnote.entitlements`.
5. Build and run on a device or simulator (iOS 17+).

## Privacy

Tripnote requests the following permissions:

| Permission | Reason |
|---|---|
| Camera | Capture photos directly from a trip |
| Photo Library | Import existing photos into a trip note |
| Photo Library (add-only) | Save trip photos back to the Photos app |

No data is sent to any third-party server. Trip data syncs only through your personal iCloud account.

## License

Copyright © 2026 Jaye Mondale. All rights reserved.
