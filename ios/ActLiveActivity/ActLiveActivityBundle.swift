import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity attributes

/// Placeholder attribute/state types. The real shape — current phase label,
/// macro progress, hydration level — will be defined in the `live-activity` todo.
struct ActLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
    }
}

// MARK: - Widget

struct ActLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ActLiveActivityAttributes.self) { context in
            HStack {
                Text("Act.")
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
                Spacer()
                Text(context.state.phase)
                    .foregroundStyle(.white)
            }
            .padding()
            .containerBackground(.black, for: .widget)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Act.")
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.phase)
                        .foregroundStyle(.white)
                }
            } compactLeading: {
                Text("A.")
                    .foregroundStyle(.white)
            } compactTrailing: {
                Text(context.state.phase)
                    .foregroundStyle(.white)
            } minimal: {
                Text("A.")
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Bundle entry point

@main
struct ActLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        ActLiveActivityWidget()
    }
}
