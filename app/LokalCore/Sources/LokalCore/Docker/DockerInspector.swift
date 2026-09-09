import Foundation
import Network
import Synchronization

/// Reads running containers from the Docker Engine API over its local Unix socket.
/// Works with Docker Desktop and OrbStack. This is a local socket, not a network connection.
public actor DockerInspector {
    public enum Failure: Error, Equatable {
        case socketNotFound
        case timedOut
        case connectionFailed(String)
    }

    /// Process names that own the host side of published container ports.
    public static let backendProcessNames: Set<String> = [
        "com.docker.backend", "com.docker.vpnkit", "vpnkit", "OrbStack Helper", "orbstack", "OrbStack",
    ]

    public static var defaultSocketPaths: [String] {
        let home = NSHomeDirectory()
        return [
            home + "/.orbstack/run/docker.sock",
            home + "/.docker/run/docker.sock",
            "/var/run/docker.sock",
        ]
    }

    public static func isBackend(processName: String) -> Bool {
        backendProcessNames.contains(processName)
    }

    private let socketPaths: [String]
    private let timeout: TimeInterval
    private var cached: (at: Date, containers: [ContainerInfo])?

    public init(socketPaths: [String] = DockerInspector.defaultSocketPaths, timeout: TimeInterval = 2) {
        self.socketPaths = socketPaths
        self.timeout = timeout
    }

    /// Running containers, cached for `maxAge` seconds.
    public func containers(maxAge: TimeInterval = 5) async throws -> [ContainerInfo] {
        if let cached, Date().timeIntervalSince(cached.at) < maxAge {
            return cached.containers
        }
        guard let socketPath = socketPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw Failure.socketNotFound
        }
        let raw = try await fetch(path: "/containers/json", socketPath: socketPath)
        let response = try DockerHTTP.parseResponse(raw)
        guard response.status == 200 else { throw DockerHTTP.Failure.unexpectedStatus(response.status) }
        let containers = try DockerHTTP.containers(from: response.body)
        cached = (Date(), containers)
        return containers
    }

    /// Container publishing `port`, if any.
    public func container(publishing port: UInt16, maxAge: TimeInterval = 5) async -> ContainerInfo? {
        guard let containers = try? await containers(maxAge: maxAge) else { return nil }
        return containers.first { $0.publishedPorts.contains(port) }
    }

    private func fetch(path: String, socketPath: String) async throws -> Data {
        let connection = NWConnection(to: .unix(path: socketPath), using: .tcp)
        let queue = DispatchQueue(label: "is.sigurdarson.lokal.docker")
        let state = Mutex<(buffer: Data, finished: Bool)>((Data(), false))
        let timeout = self.timeout

        return try await withCheckedThrowingContinuation { continuation in
            @Sendable func finish(_ result: Result<Data, any Error>) {
                let shouldResume = state.withLock { state in
                    if state.finished { return false }
                    state.finished = true
                    return true
                }
                guard shouldResume else { return }
                connection.cancel()
                continuation.resume(with: result)
            }

            /// Unix sockets report the peer closing as a failure rather than `isComplete`,
            /// so a failure after data has arrived is treated as end of response.
            @Sendable func finishWithBufferOrError(_ error: any Error) {
                let buffered = state.withLock { $0.buffer }
                if buffered.isEmpty {
                    finish(.failure(error))
                } else {
                    finish(.success(buffered))
                }
            }

            @Sendable func receive() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { data, _, isComplete, error in
                    let buffered = state.withLock { state in
                        if let data { state.buffer.append(data) }
                        return state.buffer
                    }
                    if DockerHTTP.isComplete(buffered) {
                        finish(.success(buffered))
                        return
                    }
                    if let error {
                        finishWithBufferOrError(Failure.connectionFailed(error.localizedDescription))
                        return
                    }
                    if isComplete {
                        finish(.success(buffered))
                    } else {
                        receive()
                    }
                }
            }

            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    connection.send(
                        content: DockerHTTP.request(path: path),
                        completion: .contentProcessed { error in
                            if let error {
                                finish(.failure(Failure.connectionFailed(error.localizedDescription)))
                            }
                        })
                    receive()
                case .failed(let error):
                    finishWithBufferOrError(Failure.connectionFailed(error.localizedDescription))
                case .waiting(let error):
                    finishWithBufferOrError(Failure.connectionFailed(error.localizedDescription))
                default:
                    break
                }
            }
            queue.asyncAfter(deadline: .now() + timeout) {
                finish(.failure(Failure.timedOut))
            }
            connection.start(queue: queue)
        }
    }
}
