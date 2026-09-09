import Foundation
import Testing

@testable import LokalCore

struct FixtureSockets: ListeningSocketSource {
    let sockets: [ListeningSocket]
    func listeningSockets() -> [ListeningSocket] { sockets }
}

struct FixtureProcesses: ProcessInspecting {
    let processes: [pid_t: ProcessDetails]
    func details(for pid: pid_t) -> ProcessDetails? { processes[pid] }
}

@Suite("Scanner")
struct ScannerTests {
    @Test("Builds entries with services and projects; skips vanished processes; uses ancestor cwd")
    func snapshot() async throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.directory("code/shop/.git")
        try tree.file("code/shop/package.json", #"{"name": "shop"}"#)

        let sockets = FixtureSockets(sockets: [
            ListeningSocket(pid: 100, port: 5173, family: .ipv4, address: .loopback),
            ListeningSocket(pid: 200, port: 5432, family: .ipv6, address: .loopback),
            ListeningSocket(pid: 300, port: 9999, family: .ipv4, address: .any),
        ])
        let processes = FixtureProcesses(processes: [
            100: ProcessDetails(
                pid: 100, name: "node", executablePath: "/usr/local/bin/node", workingDirectory: "/",
                parentPID: 50, arguments: ["node", "/x/node_modules/.bin/vite"], startTime: 1
            ),
            50: ProcessDetails(
                pid: 50, name: "pnpm", workingDirectory: tree.path("code/shop"), parentPID: 1, startTime: 1),
            200: ProcessDetails(
                pid: 200, name: "postgres", workingDirectory: "/opt/homebrew/var/pg", parentPID: 1, startTime: 1),
        ])
        let scanner = Scanner(
            socketSource: sockets,
            processInspector: processes,
            projectResolver: ProjectResolver(homeDirectory: tree.home.path),
            serviceMatcher: ServiceMatcher(),
            dockerInspector: nil
        )

        let snapshot = await scanner.snapshot()
        #expect(snapshot.entries.count == 2, "pid 300 has no process details and must be skipped")

        let vite = try #require(snapshot.entries.first { $0.pid == 100 })
        #expect(vite.service?.service.id == "vite")
        #expect(vite.project?.name == "shop")
        #expect(vite.label == "Vite")

        let postgres = try #require(snapshot.entries.first { $0.pid == 200 })
        #expect(postgres.project == nil)
        #expect(postgres.service?.service.id == "postgres")

        #expect(snapshot.groups.map(\.title) == ["shop", "Services"])

        // Second scan hits the project cache and yields the same result.
        let again = await scanner.snapshot()
        #expect(again.entries.map(\.id) == snapshot.entries.map(\.id))
        #expect(again.entries.first { $0.pid == 100 }?.project == vite.project)
    }

    @Test("Real scan on this machine does not crash and returns sorted entries")
    func realScan() async {
        let snapshot = await Scanner(dockerInspector: nil).snapshot()
        #expect(snapshot.entries.map(\.port) == snapshot.entries.map(\.port).sorted())
        for entry in snapshot.entries {
            #expect(!entry.label.isEmpty)
            #expect(!entry.detail.isEmpty)
        }
    }
}
