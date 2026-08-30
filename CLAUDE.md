# Tripnote — Development Guidelines

## TDD Workflow

Follow red → green → refactor for every non-trivial change:

1. **Write the test first.** Define what the new behavior should be before touching the implementation.
2. **Confirm the test fails.** A test that passes before the code exists is testing nothing.
3. **Write the minimum code to make it pass.** Don't add what isn't tested yet.
4. **Refactor.** Clean up with the safety net of passing tests.

For bug fixes, start with a test that reproduces the bug. The fix is done when the test passes.

## SOLID Principles in This Codebase

### Single Responsibility
Each type has one job. Don't let it drift.

| Type | Its one job |
|---|---|
| `PhotoImportService` | Write photo to disk, generate thumbnail, extract EXIF |
| `PhotoMetadataExtractor` | Parse EXIF/GPS from raw image bytes |
| `TripSuggestionService` | Score photos against existing trips |
| `TripExporter` | Render a trip to PDF |
| `WidgetDataManager` | Serialize the latest trip snapshot for the widget |
| `LocationManager` | Hold the most recent device fix |

Adding a second concern to any of these means splitting it into two types, not growing the existing one.

### Open/Closed
Prefer protocols when a service might need a different backend in tests or in the future. Example: if `PhotoImportService` needs to be stubbed in a test, extract a `PhotoImporting` protocol rather than modifying the existing type.

### Liskov Substitution
Subtypes must honor the contract of their parent. Avoid overriding behavior in ways that surprise callers. For SwiftData `@Model` subclassing: don't subclass models — compose instead.

### Interface Segregation
Keep protocols small and focused. A view that only needs to read trips should not receive a full mutable context. Prefer passing only what a type actually uses.

### Dependency Inversion
Depend on abstractions, not concretions. `LocationManager` is injected via SwiftUI's `.environment()` — never accessed as a singleton. New dependencies should follow the same pattern.

## Testing

### Framework
Use **Swift Testing** (`import Testing`, `@Test`, `@Suite`, `#expect`). Do not use XCTest for new tests.

### SwiftData
Always use an in-memory container. Reuse the shared helper:

```swift
private func makeTestContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Trip.self, TripEvent.self, Note.self, Photo.self,
        configurations: config
    )
    return ModelContext(container)
}
```

### What to test
- **Pure logic first**: `TripSuggestionService`, `PhotoMetadataExtractor`, model computed properties (`location`, `formattedDateRange`, `coverPhoto`, `fileURL`).
- **Boundary conditions**: exact buffer edges (24 h, 50 km), nil vs non-nil inputs, empty collections.
- **Codable round-trips**: any struct that is encoded/decoded for persistence (e.g., `WidgetDataManager.LatestTripData`).
- **Negative cases**: confirm that inputs outside a condition do not produce a match.

### What not to unit-test
- SwiftUI view layout and rendering — use previews and manual verification.
- `UIImagePickerController` / `PHPickerViewController` delegate behavior — these require the full simulator.
- `TripExporter.exportPDF` rendering — visual; verify manually or with snapshot tests.
- `WidgetCenter.shared.reloadAllTimelines()` — side-effectful platform call; not worth mocking.

### Organizing tests
Group tests into `@Suite` structs. Name the suite after the type or behavior under test. Name each `@Test` as a plain English sentence that reads like a specification: *"Returns nil when no trips exist"*, *"Matches photo within 24-hour buffer before trip start"*.

One assertion concept per test. It is fine to have multiple `#expect` calls in one test if they together assert a single behavior (e.g., both `latitude` and `longitude` for a location round-trip).

### Test naming quick rules
- Positive case: *"Matches photo whose date falls inside the trip range"*
- Negative case: *"Does not match photo more than 24 hours before trip start"*
- Edge/boundary: *"Matches photo exactly 24 hours before trip start (inclusive boundary)"*

## Architecture Rules

### Data model
- All `@Model` properties must have default values — required for CloudKit compatibility.
- Do not store raw image `Data` in the SwiftData store. Store the filename; write bytes to `Documents/Photos/`.
- `Photo.setLocation(_:)` and `Note.setLocation(_:)` are the only write paths for coordinates. Do not write `latitude`/`longitude` directly from call sites.

### Photo import pipeline
Every import path — camera, library picker, global capture — must go through `PhotoImportService.importPhoto(from:note:)`. Location from PHAsset (stripped by PHPicker from image bytes) is applied afterward via `photo.setLocation(picked.location)` at the call site.

### Naming
- Models: singular nouns (`Trip`, `Note`, `Photo`, `TripEvent`)
- Services: verb-noun enums (`PhotoImportService`, `TripSuggestionService`, `TripExporter`)
- Views: noun + `View` or `Sheet` suffix (`TripDetailView`, `CaptureReviewSheet`)
- Managers: noun + `Manager` for stateful singletons (`LocationManager`, `WidgetDataManager`)

### No Combine
Use Swift's `async`/`await` and `@Observable`. Do not introduce Combine publishers.

### Relationship rules
- `Trip` owns `Note`s and `TripEvent`s (cascade delete both).
- `Note` owns `Photo`s (cascade delete).
- Setting `photo.note = note` is sufficient — SwiftData populates the inverse. Do not also set `note.photos`.

## Checklist before committing

- [ ] New behavior has a test written before or alongside the code.
- [ ] All existing tests still pass.
- [ ] No new `@Model` property is missing a default value.
- [ ] No raw photo `Data` stored in SwiftData.
- [ ] New dependencies are injected, not accessed as singletons.
