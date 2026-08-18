import Foundation
import XCTest

final class CodexProcessManagerTests: XCTestCase {
    func testReadsSanitizedCLIversionWithoutShell() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = directory.appendingPathComponent("codex")
        try "#!/bin/sh\nprintf 'codex-cli 1.2.3\\n'\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)

        let manager = CodexProcessManager(manuallyConfiguredPath: executable.path)
        let version = await manager.versionString()
        XCTAssertEqual(version, "codex-cli 1.2.3")
    }
}
