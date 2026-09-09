import AppKit
import Foundation
import Testing

@testable import LokalCore

@Suite("ServiceCatalog")
struct ServiceCatalogTests {
    @Test("Bundled catalog loads and is well formed")
    func bundled() {
        let catalog = ServiceCatalog.bundled
        #expect(catalog.services.count >= 20)

        let ids = catalog.services.map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate service ids")

        for service in catalog.services {
            #expect(service.id == service.id.lowercased(), "\(service.id) must be lowercase")
            #expect(!service.name.isEmpty)
            #expect(
                !service.ports.isEmpty || !service.processNames.isEmpty || !service.commandPatterns.isEmpty,
                "\(service.id) needs ports, processNames or commandPatterns"
            )
            #expect(
                NSImage(systemSymbolName: service.icon, accessibilityDescription: nil) != nil,
                "\(service.id): icon \(service.icon) is not an SF Symbol"
            )
            if let template = service.urlTemplate {
                #expect(template.contains("{port}"), "\(service.id): urlTemplate must contain {port}")
            }
        }
        #expect(ServiceMatcher(catalog: catalog).invalidPatterns.isEmpty)
    }

    @Test("Defaults are applied when keys are omitted")
    func defaults() throws {
        let json = #"{"services":[{"id":"x","name":"X","kind":"tool","icon":"globe","ports":[1]}]}"#
        let catalog = try ServiceCatalog(data: Data(json.utf8))
        let service = try #require(catalog.service(id: "x"))
        #expect(service.openInBrowser)
        #expect(!service.auxiliary)
        #expect(service.processNames.isEmpty)
        #expect(service.url(forPort: 1) == "http://localhost:1")
    }
}

@Suite("ServiceMatcher")
struct ServiceMatcherTests {
    let matcher = ServiceMatcher()

    private func process(_ name: String, _ arguments: [String] = [], path: String? = nil) -> ProcessDetails {
        ProcessDetails(pid: 1, name: name, executablePath: path ?? "/opt/\(name)", arguments: arguments)
    }

    @Test("Process name beats everything")
    func processName() {
        let match = matcher.match(process: process("postgres"), port: 1234)
        #expect(match?.service.id == "postgres")
        #expect(match?.confidence == .high)
        #expect(match?.service.url(forPort: 1234) == "postgres://localhost:1234")
    }

    @Test("Command line patterns")
    func commandLine() {
        let vite = matcher.match(process: process("node", ["node", "/p/node_modules/.bin/vite"]), port: 5173)
        #expect(vite?.service.id == "vite")
        #expect(vite?.confidence == .high)

        let next = matcher.match(process: process("node", ["next-server (v15.5.0)"]), port: 3000)
        #expect(next?.service.id == "next")

        let django = matcher.match(process: process("python3", ["python3", "manage.py", "runserver"]), port: 8000)
        #expect(django?.service.id == "django")
    }

    @Test("Port-only match is medium for runtimes and low otherwise")
    func portOnly() {
        let node = matcher.match(process: process("node", ["node", "server.js"]), port: 3000)
        #expect(node?.confidence == .medium)

        let rust = matcher.match(process: process("my-rust-server"), port: 3000)
        #expect(rust?.confidence == .low)

        #expect(matcher.match(process: process("whatever"), port: 61234) == nil)
    }

    @Test("Auxiliary service ports win over the process match")
    func auxiliaryPort() {
        let vite = process("node", ["node", "/p/node_modules/vite/bin/vite.js", "dev"])
        #expect(matcher.match(process: vite, port: 3001)?.service.id == "vite")
        let inspector = matcher.match(process: vite, port: 9230)
        #expect(inspector?.service.id == "node-inspector")
        #expect(inspector?.service.auxiliary == true)
        #expect(inspector?.confidence == .medium)
    }

    @Test("Executable name is considered as well as kernel name")
    func executableName() {
        let redis = matcher.match(process: process("redis-serv", path: "/opt/homebrew/bin/redis-server"), port: 6379)
        #expect(redis?.service.id == "redis")
    }
}
