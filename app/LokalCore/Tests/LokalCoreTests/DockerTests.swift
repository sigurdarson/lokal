import Darwin
import Foundation
import Testing

@testable import LokalCore

@Suite("DockerHTTP")
struct DockerHTTPTests {
    static let containersJSON = """
        [
          {"Id": "abc123def456789", "Names": ["/db"], "Image": "postgres:16",
           "Ports": [{"PrivatePort": 5432, "PublicPort": 5433, "Type": "tcp"}, {"PrivatePort": 5432, "PublicPort": 5433, "Type": "tcp", "IP": "::"}]},
          {"Id": "ffff", "Names": [], "Image": "redis:7", "Ports": [{"PrivatePort": 6379, "Type": "tcp"}]},
          {"Id": "eeee", "Names": ["/udp-only"], "Image": "x", "Ports": [{"PrivatePort": 53, "PublicPort": 5353, "Type": "udp"}]}
        ]
        """

    @Test("Request line")
    func request() {
        let text = String(decoding: DockerHTTP.request(path: "/containers/json"), as: UTF8.self)
        #expect(text.hasPrefix("GET /containers/json HTTP/1.1\r\n"))
        #expect(text.contains("Connection: close"))
        #expect(text.hasSuffix("\r\n\r\n"))
    }

    @Test("Plain response with Content-Length")
    func plain() throws {
        let body = "[]"
        let raw = Data(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\n\r\n\(body)".utf8)
        let response = try DockerHTTP.parseResponse(raw)
        #expect(response.status == 200)
        #expect(String(decoding: response.body, as: UTF8.self) == body)
    }

    @Test("Chunked response")
    func chunked() throws {
        let raw = Data("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\n[{}\r\n1\r\n]\r\n0\r\n\r\n".utf8)
        let response = try DockerHTTP.parseResponse(raw)
        #expect(String(decoding: response.body, as: UTF8.self) == "[{}]")
    }

    @Test("Completeness detection")
    func completeness() {
        #expect(DockerHTTP.isComplete(Data("HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n[]".utf8)))
        #expect(!DockerHTTP.isComplete(Data("HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n[".utf8)))
        #expect(
            DockerHTTP.isComplete(
                Data("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n[]\r\n0\r\n\r\n".utf8)))
        #expect(!DockerHTTP.isComplete(Data("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n[]\r\n".utf8)))
        #expect(!DockerHTTP.isComplete(Data("HTTP/1.1 200 OK\r\n\r\n[]".utf8)), "no framing header means wait for EOF")
        #expect(!DockerHTTP.isComplete(Data("HTTP/1.1 200".utf8)))
    }

    @Test("Malformed responses throw")
    func malformed() {
        #expect(throws: DockerHTTP.Failure.malformedResponse) { try DockerHTTP.parseResponse(Data("garbage".utf8)) }
        #expect(throws: DockerHTTP.Failure.malformedResponse) { try DockerHTTP.dechunk(Data("zz\r\n".utf8)) }
    }

    @Test("Container mapping keeps TCP published ports, strips leading slash, dedupes")
    func containers() throws {
        let containers = try DockerHTTP.containers(from: Data(Self.containersJSON.utf8))
        #expect(containers.count == 3)
        #expect(
            containers[0]
                == ContainerInfo(id: "abc123def456789", name: "db", image: "postgres:16", publishedPorts: [5433]))
        #expect(containers[1].name == "ffff")
        #expect(containers[1].publishedPorts.isEmpty)
        #expect(containers[2].publishedPorts.isEmpty)
    }
}

/// A one-shot HTTP server on a Unix socket, standing in for the Docker daemon.
final class FakeDockerSocket: Sendable {
    let path: String
    private let fd: Int32

    init(response: String) throws {
        path = "/tmp/lokal-test-\(getpid())-\(UInt32.random(in: 0...UInt32.max)).sock"
        unlink(path)
        fd = socket(AF_UNIX, SOCK_STREAM, 0)
        try #require(fd >= 0)
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(path.utf8CString)
        try #require(pathBytes.count <= MemoryLayout.size(ofValue: address.sun_path))
        withUnsafeMutablePointer(to: &address.sun_path) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: pathBytes.count) { destination in
                for (index, byte) in pathBytes.enumerated() { destination[index] = byte }
            }
        }
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        try #require(bound == 0, "bind failed: \(errno)")
        try #require(listen(fd, 1) == 0)

        let serverFD = fd
        let responseData = Array(response.utf8)
        Thread.detachNewThread {
            let client = accept(serverFD, nil, nil)
            guard client >= 0 else { return }
            var request = [UInt8](repeating: 0, count: 4096)
            _ = read(client, &request, request.count)
            responseData.withUnsafeBufferPointer { _ = write(client, $0.baseAddress, $0.count) }
            close(client)
        }
    }

    func stop() {
        close(fd)
        unlink(path)
    }
}

@Suite("DockerInspector", .serialized)
struct DockerInspectorTests {
    @Test("Reads containers over a Unix socket")
    func readsContainers() async throws {
        let body = DockerHTTPTests.containersJSON
        let server = try FakeDockerSocket(
            response:
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
        )
        defer { server.stop() }

        let inspector = DockerInspector(socketPaths: ["/nonexistent.sock", server.path])
        let containers = try await inspector.containers()
        #expect(containers.map(\.name) == ["db", "ffff", "udp-only"])
        #expect(await inspector.container(publishing: 5433)?.name == "db")
        #expect(await inspector.container(publishing: 9999) == nil)
    }

    @Test("Chunked responses over the socket")
    func chunkedOverSocket() async throws {
        let server = try FakeDockerSocket(
            response: "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n[]\r\n0\r\n\r\n"
        )
        defer { server.stop() }
        let containers = try await DockerInspector(socketPaths: [server.path]).containers()
        #expect(containers.isEmpty)
    }

    @Test("Missing socket and error status fail cleanly")
    func failures() async throws {
        await #expect(throws: DockerInspector.Failure.socketNotFound) {
            try await DockerInspector(socketPaths: ["/nonexistent.sock"]).containers()
        }
        let server = try FakeDockerSocket(response: "HTTP/1.1 500 Internal Server Error\r\nContent-Length: 0\r\n\r\n")
        defer { server.stop() }
        await #expect(throws: DockerHTTP.Failure.unexpectedStatus(500)) {
            try await DockerInspector(socketPaths: [server.path]).containers()
        }
    }

    @Test("Backend detection")
    func backend() {
        #expect(DockerInspector.isBackend(processName: "com.docker.backend"))
        #expect(DockerInspector.isBackend(processName: "OrbStack Helper"))
        #expect(!DockerInspector.isBackend(processName: "node"))
    }
}
