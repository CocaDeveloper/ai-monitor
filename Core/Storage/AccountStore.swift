import Foundation

public actor AccountStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AI Monitor", isDirectory: true)
        self.fileURL = base.appendingPathComponent("state.json")
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> PersistedState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .init() }
        return try decoder.decode(PersistedState.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ state: PersistedState) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    public func codexHome(for accountID: UUID) throws -> URL {
        let root = fileURL.deletingLastPathComponent()
            .appendingPathComponent("CodexAccounts", isDirectory: true)
            .appendingPathComponent(accountID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    public func removeCodexHome(for accountID: UUID) throws {
        let root = fileURL.deletingLastPathComponent()
            .appendingPathComponent("CodexAccounts", isDirectory: true)
            .appendingPathComponent(accountID.uuidString, isDirectory: true)
        guard FileManager.default.fileExists(atPath: root.path) else { return }
        try FileManager.default.removeItem(at: root)
    }
}
