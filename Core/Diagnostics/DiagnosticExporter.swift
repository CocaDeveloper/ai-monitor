import Foundation

public struct DiagnosticReport: Codable, Sendable {
    public struct ProviderStatus: Codable, Sendable {
        public let provider: String
        public let connectionStatus: String
        public let lastUpdatedAt: Date?
        public let errorCode: String?
    }

    public let generatedAt: Date
    public let appVersion: String
    public let macOSVersion: String
    public let architecture: String
    public let codexCLI: String
    public let codexAppServerStatus: String
    public let providers: [ProviderStatus]
    public let widgetSnapshotStatus: String
    public let nonSecretConfiguration: [String: String]
}

public enum DiagnosticExporter {
    public static let disclosedFields = [
        "AI Monitor version and build",
        "macOS version and processor architecture",
        "Detected Codex CLI path and version (never its configuration)",
        "Provider types and connection states (no account names, IDs, or email addresses)",
        "Last update times and sanitized error codes",
        "Widget snapshot availability",
        "Non-secret display and refresh preferences",
    ]

    public static func make(state: PersistedState, codexPath: URL?, sharedSnapshot: SharedWidgetSnapshot?) -> DiagnosticReport {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        let statuses = state.accounts.sorted { $0.sortOrder < $1.sortOrder }.map { account in
            let snapshot = state.snapshots[account.id]
            return DiagnosticReport.ProviderStatus(
                provider: account.providerID.rawValue,
                connectionStatus: account.status.rawValue,
                lastUpdatedAt: snapshot?.updatedAt,
                errorCode: snapshot?.lastErrorCode
            )
        }
        return DiagnosticReport(
            generatedAt: .now,
            appVersion: "\(version) (\(build))",
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            architecture: architecture,
            codexCLI: codexPath.map { "Detected at \(SanitizedLogger.sanitize($0.path))" } ?? "Not found",
            codexAppServerStatus: "Started only during login or refresh",
            providers: statuses,
            widgetSnapshotStatus: sharedSnapshot?.updatedAt.map { "Snapshot updated \($0.ISO8601Format())" } ?? "No shared snapshot",
            nonSecretConfiguration: [
                "refreshIntervalMinutes": String(state.preferences.refreshIntervalMinutes),
                "theme": state.preferences.theme.rawValue,
                "compactMode": String(state.preferences.compactMode),
            ]
        )
    }

    public static func encode(_ report: DiagnosticReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(report)
    }

    private static var architecture: String {
        #if arch(arm64)
        "arm64"
        #elseif arch(x86_64)
        "x86_64"
        #else
        "unknown"
        #endif
    }
}
