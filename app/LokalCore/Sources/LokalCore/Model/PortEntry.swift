import Foundation

/// One row in the panel: a listening port with everything Lokal resolved about it.
public struct PortEntry: Sendable, Hashable, Identifiable {
    /// Whether a port is part of someone's development work, or noise around it.
    public enum Role: Sendable, Hashable {
        /// A dev server, database, tool or container port. Shown by default.
        case primary
        /// Debug inspectors, ephemeral internal sockets, GUI apps and system daemons. Folded away by default.
        case auxiliary
    }

    /// First port of the IANA/macOS dynamic range. Servers people run on purpose almost never live here.
    public static let ephemeralPortStart: UInt16 = 49152

    public let socket: ListeningSocket
    public let process: ProcessDetails
    public let service: ServiceMatch?
    public let project: Project?
    public let container: ContainerInfo?

    public init(
        socket: ListeningSocket,
        process: ProcessDetails,
        service: ServiceMatch? = nil,
        project: Project? = nil,
        container: ContainerInfo? = nil
    ) {
        self.socket = socket
        self.process = process
        self.service = service
        self.project = project
        self.container = container
    }

    /// Stable across refreshes while the same process keeps the same port.
    public var id: String { "\(socket.pid):\(socket.port)" }

    public var port: UInt16 { socket.port }
    public var pid: pid_t { socket.pid }

    /// Decided top down:
    /// 1. Containers are primary.
    /// 2. Ports of auxiliary services (inspectors) are auxiliary; a service that lists this exact port is primary.
    /// 3. Ephemeral-range ports are auxiliary. A dev server's process match says nothing about its extra sockets.
    /// 4. Anything that resolved to a project, or to a confident service, is primary.
    /// 5. GUI applications and system daemons (Spotify, Raycast, launchd helpers) are auxiliary.
    /// 6. Everything else, such as a hand-built binary run from a shell, is primary.
    public var role: Role {
        if container != nil { return .primary }
        if let service, service.confidence >= .medium {
            if service.service.auxiliary { return .auxiliary }
            if service.service.ports.contains(port) { return .primary }
        }
        if port >= Self.ephemeralPortStart { return .auxiliary }
        if project != nil || confidentService != nil { return .primary }
        if process.isBundledApplication || process.isSystemProcess { return .auxiliary }
        return .primary
    }

    /// Service match that is confident enough to name the row.
    public var confidentService: ServiceDefinition? {
        guard let service, service.confidence >= .medium else { return nil }
        return service.service
    }

    /// Primary text for the row.
    public var label: String {
        if let container { return container.name }
        if let confidentService { return confidentService.name }
        if let command = CommandLabeler.label(for: process) { return command }
        return process.name
    }

    /// Secondary text for the row.
    public var detail: String {
        var parts = [process.name, "PID \(process.pid)"]
        if let container { parts.append(container.image) }
        return parts.joined(separator: " · ")
    }

    /// SF Symbol for the row.
    public var icon: String {
        if container != nil { return "shippingbox" }
        if let service { return service.service.icon }
        return "circle.dotted"
    }

    public var url: URL {
        let string = service?.service.url(forPort: port) ?? "http://localhost:\(port)"
        return URL(string: string) ?? URL(string: "http://localhost:\(port)")!
    }

    public var opensInBrowser: Bool {
        service?.service.openInBrowser ?? true
    }
}
