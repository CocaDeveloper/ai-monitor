import Foundation

public struct AvailableRelease: Decodable, Sendable {
    public struct Asset: Decodable, Sendable {
        public let name: String
        public let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    public let tagName: String
    public let htmlURL: URL
    public let prerelease: Bool
    public let draft: Bool
    public let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case prerelease, draft, assets
    }

    public var dmgURL: URL? { assets.first(where: { $0.name == "AI-Monitor.dmg" })?.browserDownloadURL }
}

public struct UpdateChecker: Sendable {
    public let owner: String
    public let repository: String

    public init(owner: String, repository: String) {
        self.owner = owner
        self.repository = repository
    }

    public func latestStableRelease() async throws -> AvailableRelease {
        guard owner != "OWNER", !owner.isEmpty, !repository.isEmpty,
              let url = URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases/latest")
        else { throw UpdateError.repositoryNotConfigured }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AI-Monitor", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw UpdateError.requestFailed }
        let release = try JSONDecoder().decode(AvailableRelease.self, from: data)
        guard !release.draft, !release.prerelease else { throw UpdateError.noStableRelease }
        return release
    }
}

public enum UpdateError: Error, LocalizedError {
    case repositoryNotConfigured
    case requestFailed
    case noStableRelease

    public var errorDescription: String? {
        switch self {
        case .repositoryNotConfigured: "GitHub repository is not configured yet"
        case .requestFailed: "Could not check GitHub Releases"
        case .noStableRelease: "No stable release is available"
        }
    }
}

