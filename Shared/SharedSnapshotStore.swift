import Foundation

public struct SharedSnapshotStore: Sendable {
    private let directoryOverride: URL?

    public init(directory: URL? = nil) {
        self.directoryOverride = directory
    }

    public func load() throws -> SharedWidgetSnapshot {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return .init() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SharedWidgetSnapshot.self, from: Data(contentsOf: url))
    }

    public func save(_ snapshot: SharedWidgetSnapshot) throws {
        let url = try fileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    private func fileURL() throws -> URL {
        if let directoryOverride { return directoryOverride.appendingPathComponent("widget-snapshot.json") }
        let group = Bundle.main.object(forInfoDictionaryKey: "AIMonitorAppGroup") as? String
        if let group, !group.isEmpty, let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
            return container.appendingPathComponent("widget-snapshot.json")
        }
        #if TESTING
        return FileManager.default.temporaryDirectory.appendingPathComponent("AI-Monitor-Tests/widget-snapshot.json")
        #else
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AI Monitor", isDirectory: true)
        return fallback.appendingPathComponent("widget-snapshot.json")
        #endif
    }
}

