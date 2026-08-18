import Foundation
import XCTest

final class CodexAppServerClientTests: XCTestCase {
    private struct NamedResult: Codable { let name: String }

    func testMatchesOutOfOrderResponsesByID() async throws {
        let script = try makeFakeServer(mode: "out-of-order")
        defer { try? FileManager.default.removeItem(at: script.deletingLastPathComponent()) }
        let client = CodexAppServerClient(executableURL: script, codexHome: script.deletingLastPathComponent(), timeout: 2)
        try await client.start()
        async let first: NamedResult = client.request(.accountRead, params: EmptyParams())
        async let second: NamedResult = client.request(.accountRateLimitsRead, params: EmptyParams())
        let values = try await [first, second]
        XCTAssertEqual(values.map(\.name), ["first", "second"])
        await client.stop()
    }

    func testRequestTimeout() async throws {
        let script = try makeFakeServer(mode: "timeout")
        defer { try? FileManager.default.removeItem(at: script.deletingLastPathComponent()) }
        let client = CodexAppServerClient(executableURL: script, codexHome: script.deletingLastPathComponent(), timeout: 2)
        try await client.start()
        do {
            let _: NamedResult = try await client.request(.accountRead, params: EmptyParams())
            XCTFail("Expected timeout")
        } catch {
            XCTAssertEqual(error as? ProviderError, .timeout)
        }
        await client.stop()
    }

    func testProcessCrashFailsPendingRequest() async throws {
        let script = try makeFakeServer(mode: "crash")
        defer { try? FileManager.default.removeItem(at: script.deletingLastPathComponent()) }
        let client = CodexAppServerClient(executableURL: script, codexHome: script.deletingLastPathComponent(), timeout: 2)
        try await client.start()
        do {
            let _: NamedResult = try await client.request(.accountRead, params: EmptyParams())
            XCTFail("Expected process crash")
        } catch {
            guard case .processCrashed = error as? ProviderError else { return XCTFail("Unexpected error: \(error)") }
        }
    }

    func testProcessCrashFailsNotificationWaiter() async throws {
        let script = try makeFakeServer(mode: "crash")
        defer { try? FileManager.default.removeItem(at: script.deletingLastPathComponent()) }
        let client = CodexAppServerClient(executableURL: script, codexHome: script.deletingLastPathComponent(), timeout: 5)
        try await client.start()
        let waiter = Task { () -> Result<NamedResult, Error> in
            do { return .success(try await client.waitForNotification(.accountUpdated)) }
            catch { return .failure(error) }
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        do {
            let _: NamedResult = try await client.request(.accountRead, params: EmptyParams())
            XCTFail("Expected request to fail after crash")
        } catch {}
        switch await waiter.value {
        case .success: XCTFail("Expected notification waiter to fail after crash")
        case .failure(let error):
            guard case .processCrashed = error as? ProviderError else { return XCTFail("Unexpected error: \(error)") }
        }
    }

    private func makeFakeServer(mode: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("fake-codex")
        let python = """
        #!/usr/bin/env python3
        import json, sys, threading, time, os
        mode = \(String(reflecting: mode))
        lock = threading.Lock()
        def send(obj, delay=0):
            def work():
                time.sleep(delay)
                with lock:
                    print(json.dumps(obj), flush=True)
            threading.Thread(target=work, daemon=True).start()
        for line in sys.stdin:
            msg = json.loads(line)
            if msg.get('method') == 'initialize':
                send({'id': msg['id'], 'result': {}})
            elif msg.get('method') == 'initialized':
                pass
            elif mode == 'crash':
                os._exit(7)
            elif mode == 'timeout':
                pass
            elif msg.get('method') == 'account/read':
                send({'id': msg['id'], 'result': {'name': 'first'}}, .2)
            else:
                send({'id': msg['id'], 'result': {'name': 'second'}}, .01)
        """
        try python.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
        return url
    }
}
