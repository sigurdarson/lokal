import Foundation

/// One row in the panel: a listening port with everything Lokal resolved about it.
public struct PortEntry: Sendable, Hashable, Identifiable {
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
