import WidgetKit
import SwiftUI

// MARK: - Timeline support

struct ActPlaceholderEntry: TimelineEntry {
    let date: Date
}

struct ActPlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> ActPlaceholderEntry {
        ActPlaceholderEntry(date: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (ActPlaceholderEntry) -> Void
    ) {
        completion(ActPlaceholderEntry(date: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<ActPlaceholderEntry>) -> Void
    ) {
        completion(Timeline(entries: [ActPlaceholderEntry(date: Date())], policy: .never))
    }
}

// MARK: - Widget

struct ActPlaceholderWidget: Widget {
    let kind = "ActPlaceholderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActPlaceholderProvider()) { _ in
            Text("Act.")
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Act.")
        .description("Act. progress at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Bundle entry point

@main
struct ActWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ActPlaceholderWidget()
    }
}
