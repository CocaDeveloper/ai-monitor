import SwiftUI
import WidgetKit

struct AIMonitorTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedWidgetSnapshot
}

struct AIMonitorTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AIMonitorTimelineEntry {
        .init(date: .now, snapshot: Self.previewSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (AIMonitorTimelineEntry) -> Void) {
        completion(.init(date: .now, snapshot: (try? SharedSnapshotStore().load()) ?? Self.previewSnapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AIMonitorTimelineEntry>) -> Void) {
        let snapshot = (try? SharedSnapshotStore().load()) ?? .init()
        let entry = AIMonitorTimelineEntry(date: .now, snapshot: snapshot)
        // The app pushes reloads after refresh; this fallback only updates relative timestamps.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    static let previewSnapshot = SharedWidgetSnapshot(
        accounts: [
            .init(id: UUID(), name: "Codex Personal", providerID: .codex, summary: "38% left", resetSummary: "Reset 11:42 PM", status: .connected),
            .init(id: UUID(), name: "Codex Work", providerID: .codex, summary: "72% left", resetSummary: "Reset Tomorrow", status: .connected),
            .init(id: UUID(), name: "Kling", providerID: .kling, summary: "Usage unavailable", resetSummary: nil, status: .unavailable),
        ],
        updatedAt: .now.addingTimeInterval(-120)
    )
}

struct AIMonitorWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AIMonitorTimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 8) {
            HStack {
                Text("AI MONITOR").font(.system(size: 12, weight: .bold, design: .monospaced))
                Spacer()
                Circle().fill(Color(red: 0.49, green: 0.82, blue: 0.25)).frame(width: 7, height: 7)
            }
            Divider().overlay(Color.white.opacity(0.18))
            if entry.snapshot.accounts.isEmpty {
                Spacer()
                Text("Open AI Monitor\nto connect an account")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.snapshot.accounts.prefix(family == .systemSmall ? 3 : 4)) { account in
                    if family == .systemSmall { compactRow(account) } else { mediumRow(account) }
                }
                Spacer(minLength: 0)
            }
            Text(updateText)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(isStale ? .orange : .secondary)
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.085), Color(red: 0.02, green: 0.025, blue: 0.024)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .accessibilityElement(children: .contain)
    }

    private func compactRow(_ account: SharedAccountSnapshot) -> some View {
        HStack(spacing: 5) {
            Text(shortName(account.name)).lineLimit(1)
            Spacer()
            Text(account.summary.replacingOccurrences(of: " left", with: "")).lineLimit(1)
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
    }

    private func mediumRow(_ account: SharedAccountSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(account.name).fontWeight(.semibold).lineLimit(1)
                Spacer()
                Text(account.summary).foregroundStyle(rowColor(account))
            }
            if let reset = account.resetSummary { Text(reset).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary) }
        }
        .font(.system(size: 11, design: .monospaced))
    }

    private var isStale: Bool {
        guard let updated = entry.snapshot.updatedAt else { return true }
        return entry.date.timeIntervalSince(updated) > 2 * 60 * 60
    }

    private var updateText: String {
        if isStale { return String(localized: "Open AI Monitor to refresh") }
        return UsageFormatters.updated(entry.snapshot.updatedAt, relativeTo: entry.date)
    }

    private func shortName(_ value: String) -> String {
        value.replacingOccurrences(of: "Codex ", with: "")
    }

    private func rowColor(_ account: SharedAccountSnapshot) -> Color {
        account.status == .connected ? Color(red: 0.49, green: 0.82, blue: 0.25) : .secondary
    }
}

struct AIMonitorWidget: Widget {
    let kind = "AIMonitorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIMonitorTimelineProvider()) { entry in
            AIMonitorWidgetView(entry: entry)
        }
        .configurationDisplayName("AI Monitor")
        .description("Your AI limits, resets, and credits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AIMonitorWidgetBundle: WidgetBundle {
    var body: some Widget { AIMonitorWidget() }
}

#Preview(as: .systemSmall) {
    AIMonitorWidget()
} timeline: {
    AIMonitorTimelineEntry(date: .now, snapshot: AIMonitorTimelineProvider.previewSnapshot)
}

#Preview(as: .systemMedium) {
    AIMonitorWidget()
} timeline: {
    AIMonitorTimelineEntry(date: .now, snapshot: AIMonitorTimelineProvider.previewSnapshot)
}
