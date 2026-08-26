//
//  TripnoteWidgetLiveActivity.swift
//  TripnoteWidget
//
//  Created by Jaye Mondale on 8/25/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TripnoteWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TripnoteWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripnoteWidgetAttributes.self) { context in
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

extension TripnoteWidgetAttributes {
    fileprivate static var preview: TripnoteWidgetAttributes {
        TripnoteWidgetAttributes(name: "World")
    }
}

extension TripnoteWidgetAttributes.ContentState {
    fileprivate static var smiley: TripnoteWidgetAttributes.ContentState {
        TripnoteWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TripnoteWidgetAttributes.ContentState {
         TripnoteWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TripnoteWidgetAttributes.preview) {
   TripnoteWidgetLiveActivity()
} contentStates: {
    TripnoteWidgetAttributes.ContentState.smiley
    TripnoteWidgetAttributes.ContentState.starEyes
}
