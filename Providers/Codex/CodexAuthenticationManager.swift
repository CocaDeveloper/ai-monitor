import AppKit
import Foundation

public struct CodexAuthenticationManager: Sendable {
    public init() {}

    public func login(using client: CodexAppServerClient) async throws {
        let result: CodexLoginStartResult = try await client.request(.accountLoginStart, params: CodexLoginStartParams())
        guard result.type == "chatgpt", result.loginId != nil, let url = result.authUrl else {
            throw ProviderError.malformedResponse
        }
        let opened = await MainActor.run { NSWorkspace.shared.open(url) }
        guard opened else { throw ProviderError.loginFailed("Could not open browser") }
        let completed: CodexLoginCompleted = try await client.waitForNotification(.accountLoginCompleted)
        guard completed.success else {
            if completed.error?.localizedCaseInsensitiveContains("cancel") == true { throw ProviderError.loginCancelled }
            throw ProviderError.loginFailed(SanitizedLogger.sanitize(completed.error ?? "Unknown error"))
        }
    }
}

