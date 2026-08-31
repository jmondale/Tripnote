# Journey Images — App Store Submission Checklist

## 1. Xcode / Build

- [ ] Bump version number: target → General → Version (e.g. `1.0`)
- [ ] Bump build number: target → General → Build (must be unique per upload, e.g. `1`)
- [ ] Scheme set to **Release** before archiving (`Product → Scheme → Edit Scheme → Run → Release`)
- [ ] Archive: `Product → Archive`
- [ ] Validate the archive in Organizer (catches signing / entitlement issues before upload)
- [ ] Upload to App Store Connect via Organizer → Distribute App → App Store Connect

---

## 2. Signing & Capabilities

- [ ] Automatic signing enabled, team set to your Apple Developer account
- [ ] Main app bundle ID: `jem.Trailnote`
- [ ] Widget extension bundle ID: `jem.Trailnote.TrailnoteWidgetExtension` (must be prefixed by main app ID)
- [ ] iCloud container `iCloud.jem.Trailnote` registered in developer portal and checked in Signing & Capabilities
- [ ] App Group `group.com.jmondale.Trailnote` registered in developer portal (shared with widget)
- [ ] Push Notifications entitlement present (required for CloudKit sync)

---

## 3. App Store Connect — App Information

- [ ] **App Name**: Journey Images
- [ ] **Subtitle** (30 chars max): e.g. "Travel journal with photos"
- [ ] **Description** (4000 chars max): explain trips, notes, photo capture, map, widget, iCloud sync
- [ ] **Keywords** (100 chars max): choose terms users will search (travel, journal, photos, trips, map…)
- [ ] **Support URL**: a reachable URL (personal site, GitHub page, or simple hosted page)
- [ ] **Privacy Policy URL**: required — see section 5 below
- [ ] **Copyright**: © 2026 Jaye Mondale
- [ ] **Category**: Primary → Travel; Secondary → Lifestyle (or Photography)
- [ ] **Age Rating**: complete the questionnaire (no objectionable content → 4+)
- [ ] **Pricing**: set price tier (Free, or paid)

---

## 4. Screenshots

Required device sizes (portrait):

| Device | Resolution |
|---|---|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320 × 2868 px |
| iPhone 6.5" (iPhone 14 Plus / 15 Plus) | 1284 × 2778 px |

Recommended screens to capture:
1. Trip list (populated with a few trips)
2. Trip detail view with notes and photos
3. Map view with pins
4. Capture / review sheet
5. Home screen widget

**App icon**: 1024 × 1024 px PNG, no transparency, no rounded corners (App Store adds them). Upload in App Store Connect under App Information.

---

## 5. Privacy Policy

Required because the app accesses camera, photos, and location. The policy must cover:

- **Photos**: stored on-device and optionally synced to the user's private iCloud container — not shared with anyone
- **Location**: used to geo-tag notes and display them on the map — not transmitted off-device beyond the user's own iCloud
- **Camera**: used only to capture photos for notes
- **No third-party analytics or advertising SDKs**

A single hosted page (GitHub Pages, Notion, or any public URL) is sufficient.

---

## 6. App Privacy Nutrition Labels (App Store Connect → App Privacy)

| Data type | Collected? | Linked to user? | Used for tracking? |
|---|---|---|---|
| Photos or Videos | Yes | No (stored in user's own iCloud) | No |
| Location | Yes (EXIF / device GPS) | No | No |
| Identifiers | No | — | — |
| Usage Data | No | — | — |

---

## 7. Final Device Testing

- [ ] Test on a physical device (not just Simulator) — camera and location require real hardware
- [ ] Grant then revoke camera permission → app handles denial gracefully
- [ ] Grant then revoke location permission → no crash, map still loads
- [ ] Add a trip, add notes with photos, verify CloudKit sync appears on a second device / iCloud.com
- [ ] Verify widget updates after adding a trip
- [ ] Test on the oldest supported iOS version (check deployment target in Build Settings)
- [ ] Test with a fresh install (no existing data) — onboarding appears correctly
- [ ] Test dark mode and Dynamic Type (large accessibility sizes)

---

## 8. Common Rejection Reasons to Check

- [ ] All permission usage descriptions are present and descriptive (camera, photos, location) ✅ done
- [ ] App does not crash on launch with a fresh install
- [ ] App does not reference other platforms (Android, etc.) in any UI text
- [ ] All external URLs in the app are reachable
- [ ] If the app requires an account to function, a demo account is provided in the Review Notes field
- [ ] No placeholder text or unfinished screens visible to users
