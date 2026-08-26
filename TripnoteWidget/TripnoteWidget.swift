//
//  TripnoteWidget.swift
//  TripnoteWidget
//
//  Created by Jaye Mondale on 8/25/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import WidgetKit
import SwiftUI

// Mirrors WidgetDataManager.LatestTripData in the main app target.
private struct LatestTripData: Codable {
    let name: String
    let dateRange: String
    let thumbnailData: Data?
}

struct TripnoteEntry: TimelineEntry {
    let date: Date
    let name: String
    let dateRange: String
    let thumbnail: UIImage?
}

struct TripnoteProvider: TimelineProvider {
    private let appGroupID = "group.com.jmondale.Tripnote"
    private let latestTripKey = "latestTrip"

    func placeholder(in context: Context) -> TripnoteEntry {
        TripnoteEntry(date: .now, name: "Summer Road Trip", dateRange: "Aug 1–7, 2026", thumbnail: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TripnoteEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TripnoteEntry>) -> Void) {
        // Reloads are driven by the main app calling WidgetCenter.reloadAllTimelines().
        completion(Timeline(entries: [makeEntry()], policy: .never))
    }

    private func makeEntry() -> TripnoteEntry {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: latestTripKey),
            let tripData = try? JSONDecoder().decode(LatestTripData.self, from: data)
        else {
            return TripnoteEntry(date: .now, name: "No trips yet", dateRange: "", thumbnail: nil)
        }
        let thumbnail = tripData.thumbnailData.flatMap { UIImage(data: $0) }
        return TripnoteEntry(date: .now, name: tripData.name, dateRange: tripData.dateRange, thumbnail: thumbnail)
    }
}

struct TripnoteWidgetEntryView: View {
    let entry: TripnoteEntry

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient scrim rendered over the containerBackground photo.
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !entry.dateRange.isEmpty {
                    Text(entry.dateRange)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(12)
        }
        .containerBackground(for: .widget) {
            if let thumbnail = entry.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.blue
                    .overlay {
                        Image(systemName: "map.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.25))
                    }
            }
        }
    }
}

struct TripnoteWidget: Widget {
    let kind = "TripnoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripnoteProvider()) { entry in
            TripnoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Latest Trip")
        .description("Shows your most recent trip at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TripnoteWidget()
} timeline: {
    TripnoteEntry(date: .now, name: "Grand Canyon", dateRange: "Aug 10–14, 2026", thumbnail: nil)
}
