import Foundation
import Testing

@testable import LokalCore

@Suite("Snapshot grouping")
struct SnapshotTests {
    private func entry(
        pid: pid_t, port: UInt16, name: String = "node", project: Project? = nil,
        service: ServiceMatch? = nil, container: ContainerInfo? = nil
    ) -> PortEntry {
        PortEntry(
            socket: ListeningSocket(pid: pid, port: port, family: .ipv4, address: .loopback),
            process: ProcessDetails(pid: pid, name: name),
            service: service, project: project, container: container
        )
    }

    @Test("Projects first (alphabetical), then containers, services, other")
    func grouping() throws {
        let web = Project(
            name: "web", path: "/r/lokal/apps/web", repositoryName: "lokal", repositoryPath: "/r/lokal",
            manifest: .packageJSON)
        let api = Project(
            name: "api", path: "/r/lokal/apps/api", repositoryName: "lokal", repositoryPath: "/r/lokal",
            manifest: .packageJSON)
        let blog = Project(name: "blog", path: "/r/blog", manifest: .git)
        let postgres = ServiceMatch(service: ServiceCatalog.bundled.service(id: "postgres")!, confidence: .high)
        let hint = ServiceMatch(service: ServiceCatalog.bundled.service(id: "http-generic")!, confidence: .low)
        let container = ContainerInfo(id: "abc", name: "db", image: "postgres:16", publishedPorts: [5433])

        let snapshot = Snapshot(entries: [
            entry(pid: 10, port: 5173, project: web),
            entry(pid: 11, port: 4000, project: api),
            entry(pid: 12, port: 8080, name: "custom", service: hint),
            entry(pid: 13, port: 5432, name: "postgres", service: postgres),
            entry(pid: 14, port: 5433, name: "com.docker.backend", container: container),
            entry(pid: 15, port: 3000, project: blog),
        ])

        #expect(snapshot.groups.map(\.title) == ["blog", "lokal", "Containers", "Services", "Other"])
        let lokal = try #require(snapshot.groups.first { $0.title == "lokal" })
        #expect(lokal.entries.map(\.port) == [4000, 5173])
        #expect(lokal.kind == .project)
        #expect(snapshot.groups.last?.entries.first?.label == "custom")
    }

    @Test("Roles: ephemeral and auxiliary-service ports fold, containers never do")
    func roles() throws {
        let vite = ServiceMatch(service: ServiceCatalog.bundled.service(id: "vite")!, confidence: .high)
        let inspector = ServiceMatch(
            service: ServiceCatalog.bundled.service(id: "node-inspector")!, confidence: .medium)
        let container = ContainerInfo(id: "c", name: "db", image: "postgres:16", publishedPorts: [55432])

        #expect(entry(pid: 1, port: 3001, service: vite).role == .primary)
        #expect(entry(pid: 1, port: 62389, service: vite).role == .auxiliary, "ephemeral port of a known server")
        #expect(entry(pid: 1, port: 9230, service: inspector).role == .auxiliary)
        #expect(entry(pid: 2, port: 54708, name: "workerd").role == .auxiliary)
        #expect(entry(pid: 2, port: 8787, name: "workerd").role == .primary)
        #expect(entry(pid: 3, port: 55432, name: "com.docker.backend", container: container).role == .primary)
        #expect(entry(pid: 4, port: 49151).role == .primary)
        #expect(entry(pid: 4, port: 49152).role == .auxiliary)

        let project = Project(name: "site", path: "/r/site", manifest: .packageJSON)
        let snapshot = Snapshot(entries: [
            entry(pid: 1, port: 3001, project: project, service: vite),
            entry(pid: 1, port: 9230, project: project, service: inspector),
            entry(pid: 1, port: 62389, project: project, service: vite),
        ])
        let group = try #require(snapshot.groups.first)
        #expect(group.primaryEntries.map(\.port) == [3001])
        #expect(group.auxiliaryEntries.map(\.port) == [9230, 62389])
        #expect(snapshot.primaryCount == 1)
        #expect(snapshot.auxiliaryCount == 2)
    }

    @Test("Entry label and URL precedence")
    func labels() throws {
        let container = ContainerInfo(id: "abc", name: "db", image: "postgres:16", publishedPorts: [5433])
        #expect(entry(pid: 1, port: 5433, name: "com.docker.backend", container: container).label == "db")

        let postgres = ServiceMatch(service: ServiceCatalog.bundled.service(id: "postgres")!, confidence: .high)
        let pg = entry(pid: 2, port: 5432, name: "postgres", service: postgres)
        #expect(pg.label == "Postgres")
        #expect(pg.url.absoluteString == "postgres://localhost:5432")
        #expect(!pg.opensInBrowser)

        let node = PortEntry(
            socket: ListeningSocket(pid: 3, port: 3000, family: .ipv4, address: .loopback),
            process: ProcessDetails(
                pid: 3, name: "node", executablePath: "/usr/bin/node", arguments: ["node", "server.js"]),
            service: ServiceMatch(service: ServiceCatalog.bundled.service(id: "next")!, confidence: .low)
        )
        #expect(node.label == "server", "low-confidence service must not name the row")
        #expect(node.url.absoluteString == "http://localhost:3000")
        #expect(node.id == "3:3000")
    }
}
