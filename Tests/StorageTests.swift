import Foundation
import XCTest

final class StorageTests: XCTestCase {
    func testPersistsAccountsAndSnapshots() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AccountStore(directory: directory)
        let account = ProviderAccount(providerID: .codex, displayName: "Work", sortOrder: 1, createdAt: Date(timeIntervalSince1970: 1_700_000_000))
        let metric = UsageMetric(id: "codex", label: "Codex", kind: .percentage, remainingPercent: 82)
        let snapshot = UsageSnapshot(accountID: account.id, providerID: .codex, metrics: [metric], updatedAt: Date(timeIntervalSince1970: 1_700_000_100))
        let expected = PersistedState(accounts: [account], snapshots: [account.id: snapshot])
        try await store.save(expected)
        let loaded = try await store.load()
        XCTAssertEqual(loaded, expected)
    }

    func testCodexHomesAreIsolatedByAccount() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = AccountStore(directory: directory)
        let first = try await store.codexHome(for: UUID())
        let second = try await store.codexHome(for: UUID())
        XCTAssertNotEqual(first, second)
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
    }

    func testSharedWidgetSnapshotRoundTrip() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SharedSnapshotStore(directory: directory)
        let snapshot = SharedWidgetSnapshot(accounts: [.init(id: UUID(), name: "Codex", providerID: .codex, summary: "82% left", resetSummary: nil, status: .connected)], updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
        try store.save(snapshot)
        XCTAssertEqual(try store.load(), snapshot)
    }

    func testAccountOrderingUsesSortOrder() {
        let accounts = [
            ProviderAccount(providerID: .codex, displayName: "Second", sortOrder: 1),
            ProviderAccount(providerID: .codex, displayName: "First", sortOrder: 0),
        ]
        XCTAssertEqual(accounts.sorted { $0.sortOrder < $1.sortOrder }.map(\.displayName), ["First", "Second"])
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
