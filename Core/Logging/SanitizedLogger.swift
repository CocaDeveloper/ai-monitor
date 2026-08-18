import Foundation
import OSLog

public struct SanitizedLogger: Sendable {
    private let logger: Logger

    public init(category: String) {
        self.logger = Logger(subsystem: "dev.aimonitor.app", category: category)
    }

    public func info(_ message: String) {
        logger.info("\(Self.sanitize(message), privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(Self.sanitize(message), privacy: .public)")
    }

    public static func sanitize(_ value: String) -> String {
        var result = value.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
        let patterns = [
            #"(?i)(authorization\s*:\s*bearer\s+)[^\s\"]+"#,
            #"(?i)(api[_-]?key\s*[=:]\s*)[^\s,;\"]+"#,
            #"\bsk-[A-Za-z0-9_-]{8,}\b"#,
            #"(?i)(access_token|refresh_token|client_secret)\"?\s*[:=]\s*\"?[^\s,;}\"]+"#,
            #"(?i)([?&](?:code|token|access_token|refresh_token)=)[^&\s\"]+"#,
            #"(?i)(cookie\s*:\s*)[^\r\n]+"#,
            #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "[REDACTED]")
        }
        return result
    }
}
