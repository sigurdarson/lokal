import Foundation

/// Produces `Snapshot`s: enumerates listening sockets, describes their processes,
/// matches services, resolves projects and (when relevant) container names.
public actor Scanner {
    private let socketSource: any ListeningSocketSource
    private let processInspector: any ProcessInspecting
    private let projectResolver: ProjectResolver
    private let serviceMatcher: ServiceMatcher
    private let dockerInspector: DockerInspector?

    /// Project lookups touch the disk, so they are cached per process identity.
    private var projectCache: [ProcessIdentity: Project?] = [:]

    public init(
        socketSource: any ListeningSocketSource = LibprocSocketSource(),
        processInspector: any ProcessInspecting = LibprocProcessInspector(),
        projectResolver: ProjectResolver = ProjectResolver(),
        serviceMatcher: ServiceMatcher = ServiceMatcher(),
        dockerInspector: DockerInspector? = DockerInspector()
    ) {
        self.socketSource = socketSource
        self.processInspector = processInspector
        self.projectResolver = projectResolver
        self.serviceMatcher = serviceMatcher
        self.dockerInspector = dockerInspector
    }

    public func snapshot() async -> Snapshot {
        let sockets = socketSource.listeningSockets()
        let pids = Set(sockets.map(\.pid))

        var processes: [pid_t: ProcessDetails] = [:]
        for pid in pids {
            if let details = processInspector.details(for: pid) {
                processes[pid] = details
            }
        }
        let identities = Set(processes.values.map(\.identity))
        projectCache = projectCache.filter { identities.contains($0.key) }

        var containers: [ContainerInfo] = []
        if let dockerInspector, processes.values.contains(where: { DockerInspector.isBackend(processName: $0.name) }) {
            containers = (try? await dockerInspector.containers()) ?? []
        }

        var entries: [PortEntry] = []
        for socket in sockets {
            guard let process = processes[socket.pid] else { continue }
            let isBackend = DockerInspector.isBackend(processName: process.name)
            let container = isBackend ? containers.first { $0.publishedPorts.contains(socket.port) } : nil
            let service = serviceMatcher.match(process: process, port: socket.port)
            let project = isBackend ? nil : project(for: process)
            entries.append(
                PortEntry(socket: socket, process: process, service: service, project: project, container: container)
            )
        }
        return Snapshot(entries: entries)
    }

    private func project(for process: ProcessDetails) -> Project? {
        if let cached = projectCache[process.identity] {
            return cached
        }
        let project = projectResolver.resolve(
            ProjectResolver.Input(
                workingDirectory: process.workingDirectory,
                ancestorWorkingDirectories: ancestorWorkingDirectories(of: process),
                arguments: process.arguments
            )
        )
        projectCache[process.identity] = project
        return project
    }

    /// Working directories of up to three ancestors, nearest first. Stops at launchd.
    private func ancestorWorkingDirectories(of process: ProcessDetails) -> [String] {
        var result: [String] = []
        var parent = process.parentPID
        var hops = 0
        while let pid = parent, pid > 1, hops < 3 {
            guard let details = processInspector.details(for: pid) else { break }
            if let cwd = details.workingDirectory {
                result.append(cwd)
            }
            parent = details.parentPID
            hops += 1
        }
        return result
    }
}
