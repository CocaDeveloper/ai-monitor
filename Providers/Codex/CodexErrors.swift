import Foundation

public enum CodexClientError: Error, LocalizedError, Equatable, Sendable {
    case notStarted
    case alreadyStarted
    case writeFailed
    case invalidResponse
    case remote(code: Int?, message: String)

    public var errorDescription: String? {
        switch self {
        case .notStarted: "Codex App Server is not running"
        case .alreadyStarted: "Codex App Server is already running"
        case .writeFailed: "Could not write to Codex App Server"
        case .invalidResponse: "Codex App Server returned an invalid response"
        case let .remote(_, message): SanitizedLogger.sanitize(message)
        }
    }
}

