import Foundation

public struct CodexProcessManager: Sendable {
    public var manuallyConfiguredPath: String?

    public init(manuallyConfiguredPath: String? = nil) {
        self.manuallyConfiguredPath = manuallyConfiguredPath
    }

    public func executableURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        var candidates: [String] = []
        if let manual = manuallyConfiguredPath, !manual.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            candidates.append((manual as NSString).expandingTildeInPath)
        }
        candidates += (environment["PATH"] ?? "").split(separator: ":").map { "\($0)/codex" }
        candidates += [
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "~/.local/bin/codex",
            "/Applications/ChatGPT.app/Contents/Resources/codex",
        ].map { ($0 as NSString).expandingTildeInPath }

        let nvmRoot = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".nvm/versions/node")
        if let versions = try? FileManager.default.contentsOfDirectory(at: nvmRoot, includingPropertiesForKeys: nil) {
            candidates += versions.map { $0.appendingPathComponent("bin/codex").path }
        }

        var seen = Set<String>()
        return candidates.first { path in
            guard seen.insert(path).inserted else { return false }
            return FileManager.default.isExecutableFile(atPath: path)
        }.map(URL.init(fileURLWithPath:))
    }

    public func prepareHome(_ home: URL) throws {
        try FileManager.default.createDirectory(
            at: home,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let config = home.appendingPathComponent("config.toml")
        if !FileManager.default.fileExists(atPath: config.path) {
            let contents = "# Managed by the official Codex CLI for this AI Monitor account.\ncli_auth_credentials_store = \"file\"\n"
            try contents.write(to: config, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: config.path)
        }
    }

    public func versionString() async -> String? {
        guard let executable = executableURL() else { return nil }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                let output = Pipe()
                process.executableURL = executable
                process.arguments = ["--version"]
                process.standardOutput = output
                process.standardError = output
                do { try process.run() } catch {
                    continuation.resume(returning: nil)
                    return
                }

                let deadline = Date().addingTimeInterval(2)
                while process.isRunning, Date() < deadline { Thread.sleep(forTimeInterval: 0.02) }
                if process.isRunning { process.terminate() }
                process.waitUntilExit()
                guard process.terminationStatus == 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                let data = output.fileHandleForReading.readDataToEndOfFile()
                guard let text = String(data: data, encoding: .utf8)?.split(whereSeparator: \.isNewline).first else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: String(SanitizedLogger.sanitize(String(text)).prefix(120)))
            }
        }
    }
}
