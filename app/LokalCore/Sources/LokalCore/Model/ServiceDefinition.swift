/// A well-known service that Lokal can recognise, loaded from `services.json`.
public struct ServiceDefinition: Codable, Sendable, Hashable, Identifiable {
    public enum Kind: String, Codable, Sendable, Hashable, CaseIterable {
        case database
        case cache
        case queue
        case search
        case storage
        case devServer = "dev-server"
        case web
        case tool
        case container
        case ai
        case other
    }

    public let id: String
    public let name: String
    public let kind: Kind
    /// SF Symbol name.
    public let icon: String
    public let ports: [UInt16]
    public let processNames: [String]
    /// Regular expressions matched against the full command line.
    public let commandPatterns: [String]
    /// URL template used by "Copy URL". `{port}` is replaced. Defaults to `http://localhost:{port}`.
    public let urlTemplate: String?
    /// Whether "Open in browser" makes sense for this service. Defaults to true.
    public let openInBrowser: Bool
    /// Supporting infrastructure (debug inspectors, internal RPC ports) that is hidden by default. Defaults to false.
    public let auxiliary: Bool

    public init(
        id: String,
        name: String,
        kind: Kind,
        icon: String,
        ports: [UInt16] = [],
        processNames: [String] = [],
        commandPatterns: [String] = [],
        urlTemplate: String? = nil,
        openInBrowser: Bool = true,
        auxiliary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.icon = icon
        self.ports = ports
        self.processNames = processNames
        self.commandPatterns = commandPatterns
        self.urlTemplate = urlTemplate
        self.openInBrowser = openInBrowser
        self.auxiliary = auxiliary
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, kind, icon, ports, processNames, commandPatterns, urlTemplate, openInBrowser, auxiliary
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decode(Kind.self, forKey: .kind)
        icon = try container.decode(String.self, forKey: .icon)
        ports = try container.decodeIfPresent([UInt16].self, forKey: .ports) ?? []
        processNames = try container.decodeIfPresent([String].self, forKey: .processNames) ?? []
        commandPatterns = try container.decodeIfPresent([String].self, forKey: .commandPatterns) ?? []
        urlTemplate = try container.decodeIfPresent(String.self, forKey: .urlTemplate)
        openInBrowser = try container.decodeIfPresent(Bool.self, forKey: .openInBrowser) ?? true
        auxiliary = try container.decodeIfPresent(Bool.self, forKey: .auxiliary) ?? false
    }

    /// Resolves the URL template for a port.
    public func url(forPort port: UInt16) -> String {
        (urlTemplate ?? "http://localhost:{port}").replacingOccurrences(of: "{port}", with: String(port))
    }
}

/// The result of matching a process and port against the catalog.
public struct ServiceMatch: Sendable, Hashable {
    public enum Confidence: Int, Sendable, Hashable, Comparable {
        /// Only the port matched, and the process is not a generic runtime. Treated as a hint.
        case low
        /// Only the port matched, but the process is a generic runtime (node, python, ...).
        case medium
        /// The process name or command line matched.
        case high

        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public let service: ServiceDefinition
    public let confidence: Confidence

    public init(service: ServiceDefinition, confidence: Confidence) {
        self.service = service
        self.confidence = confidence
    }
}
