//
//  BirthdayPalWidget_swiftLiveActivity.swift
//  BirthdayPalWidget.swift
//
//  Created by Archit Lakhani on 11/12/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BirthdayPalWidget_swiftAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BirthdayPalWidget_swiftLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BirthdayPalWidget_swiftAttributes.self) { context in
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

extension BirthdayPalWidget_swiftAttributes {
    fileprivate static var preview: BirthdayPalWidget_swiftAttributes {
        BirthdayPalWidget_swiftAttributes(name: "World")
    }
}

extension BirthdayPalWidget_swiftAttributes.ContentState {
    fileprivate static var smiley: BirthdayPalWidget_swiftAttributes.ContentState {
        BirthdayPalWidget_swiftAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BirthdayPalWidget_swiftAttributes.ContentState {
         BirthdayPalWidget_swiftAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BirthdayPalWidget_swiftAttributes.preview) {
   BirthdayPalWidget_swiftLiveActivity()
} contentStates: {
    BirthdayPalWidget_swiftAttributes.ContentState.smiley
    BirthdayPalWidget_swiftAttributes.ContentState.starEyes
}
