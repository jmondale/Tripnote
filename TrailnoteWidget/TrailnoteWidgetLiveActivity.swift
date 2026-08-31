//
//  TrailnoteWidgetLiveActivity.swift
//  TrailnoteWidget
//
//  Created by Jaye Mondale on 8/25/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TrailnoteWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TrailnoteWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrailnoteWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TrailnoteWidgetAttributes {
    fileprivate static var preview: TrailnoteWidgetAttributes {
        TrailnoteWidgetAttributes(name: "World")
    }
}

extension TrailnoteWidgetAttributes.ContentState {
    fileprivate static var smiley: TrailnoteWidgetAttributes.ContentState {
        TrailnoteWidgetAttributes.ContentState(emoji: "😀")
     }

     fileprivate static var starEyes: TrailnoteWidgetAttributes.ContentState {
         TrailnoteWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TrailnoteWidgetAttributes.preview) {
   TrailnoteWidgetLiveActivity()
} contentStates: {
    TrailnoteWidgetAttributes.ContentState.smiley
    TrailnoteWidgetAttributes.ContentState.starEyes
}
