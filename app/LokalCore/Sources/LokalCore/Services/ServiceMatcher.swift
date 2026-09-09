import Foundation

/// Matches a process and port against the catalog. Process name and command line beat ports.
public struct ServiceMatcher: Sendable {
    private struct Compiled: Sendable {
        let service: ServiceDefinition
        let processNames: Set<String>
        let patterns: [NSRegularExpression]
    }

    private let compiled: [Compiled]
    private let byPort: [UInt16: [Int]]

    /// Patterns that failed to compile, as (service id, pattern). Empty for the bundled catalog; a test enforces it.
    public let invalidPatterns: [(serviceID: String, pattern: String)]

    public init(catalog: ServiceCatalog = .bundled) {
        var compiled: [Compiled] = []
        var invalid: [(String, String)] = []
        var byPort: [UInt16: [Int]] = [:]
        for service in catalog.services {
            var patterns: [NSRegularExpression] = []
            for pattern in service.commandPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    patterns.append(regex)
                } else {
                    invalid.append((service.id, pattern))
                }
            }
            let index = compiled.count
            compiled.append(
                Compiled(
                    service: service,
                    processNames: Set(service.processNames.map { $0.lowercased() }),
                    patterns: patterns
                )
            )
            for port in service.ports {
                byPort[port, default: []].append(index)
            }
        }
        self.compiled = compiled
        self.byPort = byPort
        self.invalidPatterns = invalid.map { (serviceID: $0.0, pattern: $0.1) }
    }

    public func match(process: ProcessDetails, port: UInt16) -> ServiceMatch? {
        let names = Set([process.name.lowercased(), process.executableName.lowercased()])
        let commandLine = process.commandLine
        let commandRange = NSRange(commandLine.startIndex..., in: commandLine)

        var best: ServiceMatch?
        func consider(_ service: ServiceDefinition, _ confidence: ServiceMatch.Confidence) {
            if let current = best, current.confidence >= confidence { return }
            best = ServiceMatch(service: service, confidence: confidence)
        }

        for entry in compiled {
            if !entry.processNames.isDisjoint(with: names) {
                consider(entry.service, .high)
                continue
            }
            if !commandLine.isEmpty,
                entry.patterns.contains(where: { $0.firstMatch(in: commandLine, range: commandRange) != nil })
            {
                consider(entry.service, .high)
            }
        }
        if best?.confidence == .high { return best }

        if let indices = byPort[port] {
            let confidence: ServiceMatch.Confidence = CommandLabeler.isGenericRuntime(process) ? .medium : .low
            for index in indices {
                consider(compiled[index].service, confidence)
                if best?.confidence == confidence { break }
            }
        }
        return best
    }
}
