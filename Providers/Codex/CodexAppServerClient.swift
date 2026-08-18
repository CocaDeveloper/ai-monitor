import Foundation

public actor CodexAppServerClient {
    private struct PendingRequest {
        let continuation: CheckedContinuation<Data, Error>
    }

    private let executableURL: URL
    private let codexHome: URL
    private let timeout: TimeInterval
    private let logger = SanitizedLogger(category: "codex-app-server")
    private var process: Process?
    private var input: FileHandle?
    private var output: FileHandle?
    private var errorOutput: FileHandle?
    private var buffer = Data()
    private var nextRequestID = 1
    private var pending: [Int: PendingRequest] = [:]
    private var notificationWaiters: [String: [UUID: CheckedContinuation<Data, Error>]] = [:]
    private var bufferedNotifications: [String: [Data]] = [:]

    public init(executableURL: URL, codexHome: URL, timeout: TimeInterval = 15) {
        self.executableURL = executableURL
        self.codexHome = codexHome
        self.timeout = timeout
    }

    public func start(version: String = "0.1.0") async throws {
        guard process == nil else { throw CodexClientError.alreadyStarted }
        let process = Process()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = ["app-server", "--listen", "stdio://"]
        var environment = ProcessInfo.processInfo.environment
        environment["CODEX_HOME"] = codexHome.path
        process.environment = environment
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        self.process = process
        self.input = stdinPipe.fileHandleForWriting
        self.output = stdoutPipe.fileHandleForReading
        self.errorOutput = stderrPipe.fileHandleForReading

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            Task { await self?.receive(data) }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { await self?.logStderr(text) }
        }
        process.terminationHandler = { [weak self] process in
            Task { await self?.processDidTerminate(process.terminationStatus) }
        }

        do {
            try process.run()
            let _: EmptyResult = try await request(.initialize, params: CodexInitializeParams(version: version))
            try sendNotification(.initialized, params: EmptyParams())
        } catch {
            stop()
            throw error
        }
    }

    public func stop() {
        output?.readabilityHandler = nil
        errorOutput?.readabilityHandler = nil
        try? input?.close()
        if let process, process.isRunning { process.terminate() }
        self.process = nil
        self.input = nil
        self.output = nil
        self.errorOutput = nil
        let current = pending
        pending.removeAll()
        current.values.forEach { $0.continuation.resume(throwing: ProviderError.transport("Codex App Server stopped")) }
        for waiters in notificationWaiters.values {
            waiters.values.forEach { $0.resume(throwing: ProviderError.transport("Codex App Server stopped")) }
        }
        notificationWaiters.removeAll()
    }

    public func request<Params: Encodable, Result: Decodable>(_ method: CodexRPCMethod, params: Params) async throws -> Result {
        guard process?.isRunning == true else { throw CodexClientError.notStarted }
        let id = nextRequestID
        nextRequestID += 1
        let requestData = try makeRequest(method: method.rawValue, id: id, params: params)
        let response: Data = try await withCheckedThrowingContinuation { continuation in
            pending[id] = PendingRequest(continuation: continuation)
            do {
                try write(requestData)
            } catch {
                pending.removeValue(forKey: id)
                continuation.resume(throwing: error)
                return
            }
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64((self?.timeout ?? 15) * 1_000_000_000))
                await self?.timeoutRequest(id)
            }
        }
        do {
            return try JSONDecoder().decode(Result.self, from: response)
        } catch {
            throw CodexClientError.invalidResponse
        }
    }

    public func waitForNotification<Result: Decodable>(_ method: CodexRPCMethod) async throws -> Result {
        let name = method.rawValue
        if var buffered = bufferedNotifications[name], !buffered.isEmpty {
            let data = buffered.removeFirst()
            bufferedNotifications[name] = buffered
            return try JSONDecoder().decode(Result.self, from: data)
        }
        let token = UUID()
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            notificationWaiters[name, default: [:]][token] = continuation
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64((self?.timeout ?? 15) * 1_000_000_000))
                await self?.timeoutNotification(name: name, token: token)
            }
        }
        return try JSONDecoder().decode(Result.self, from: data)
    }

    private func sendNotification<Params: Encodable>(_ method: CodexRPCMethod, params: Params) throws {
        let paramsData = try JSONEncoder().encode(params)
        let paramsObject = try JSONSerialization.jsonObject(with: paramsData)
        let object: [String: Any] = ["method": method.rawValue, "params": paramsObject]
        try write(JSONSerialization.data(withJSONObject: object))
    }

    private func makeRequest<Params: Encodable>(method: String, id: Int, params: Params) throws -> Data {
        let encoded = try JSONEncoder().encode(params)
        let paramsObject = try JSONSerialization.jsonObject(with: encoded)
        return try JSONSerialization.data(withJSONObject: ["method": method, "id": id, "params": paramsObject])
    }

    private func write(_ data: Data) throws {
        guard let input else { throw CodexClientError.notStarted }
        var line = data
        line.append(0x0A)
        do { try input.write(contentsOf: line) }
        catch { throw CodexClientError.writeFailed }
    }

    private func receive(_ data: Data) {
        if data.isEmpty { return }
        buffer.append(data)
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer.prefix(upTo: newline)
            buffer.removeSubrange(...newline)
            guard !line.isEmpty else { continue }
            handleLine(Data(line))
        }
    }

    private func handleLine(_ data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Discarded malformed JSON-RPC message")
            return
        }
        if let id = (object["id"] as? NSNumber)?.intValue, let request = pending.removeValue(forKey: id) {
            if let error = object["error"] as? [String: Any] {
                request.continuation.resume(throwing: CodexClientError.remote(code: error["code"] as? Int, message: error["message"] as? String ?? "Unknown Codex error"))
                return
            }
            let result = object["result"] ?? [:]
            guard JSONSerialization.isValidJSONObject(result), let encoded = try? JSONSerialization.data(withJSONObject: result) else {
                request.continuation.resume(throwing: CodexClientError.invalidResponse)
                return
            }
            request.continuation.resume(returning: encoded)
            return
        }
        guard let method = object["method"] as? String else { return }
        let params = object["params"] ?? [:]
        guard JSONSerialization.isValidJSONObject(params), let encoded = try? JSONSerialization.data(withJSONObject: params) else { return }
        if let token = notificationWaiters[method]?.keys.first,
           let waiter = notificationWaiters[method]?.removeValue(forKey: token) {
            waiter.resume(returning: encoded)
        } else {
            bufferedNotifications[method, default: []].append(encoded)
        }
    }

    private func timeoutRequest(_ id: Int) {
        pending.removeValue(forKey: id)?.continuation.resume(throwing: ProviderError.timeout)
    }

    private func timeoutNotification(name: String, token: UUID) {
        notificationWaiters[name]?.removeValue(forKey: token)?.resume(throwing: ProviderError.timeout)
    }

    private func processDidTerminate(_ status: Int32) {
        guard process != nil else { return }
        self.process = nil
        self.input = nil
        self.output?.readabilityHandler = nil
        self.errorOutput?.readabilityHandler = nil
        self.output = nil
        self.errorOutput = nil
        let current = pending
        pending.removeAll()
        current.values.forEach { $0.continuation.resume(throwing: ProviderError.processCrashed(status)) }
        let waiters = notificationWaiters
        notificationWaiters.removeAll()
        waiters.values.forEach { group in
            group.values.forEach { $0.resume(throwing: ProviderError.processCrashed(status)) }
        }
    }

    private func logStderr(_ text: String) {
        logger.error(text)
    }
}
