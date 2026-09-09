import Darwin

/// Identifies a process across pid reuse: the pid plus its start time.
public struct ProcessIdentity: Sendable, Hashable {
    public let pid: pid_t
    public let startTime: UInt64

    public init(pid: pid_t, startTime: UInt64) {
        self.pid = pid
        self.startTime = startTime
    }
}

/// Everything Lokal knows about a process, gathered from libproc and sysctl.
public struct ProcessDetails: Sendable, Hashable {
    public let pid: pid_t
    /// The kernel's short name for the process (`p_comm`), e.g. `node`, `postgres`.
    public let name: String
    public let executablePath: String?
    public let workingDirectory: String?
    public let parentPID: pid_t?
    /// Full argument vector, including argv[0]. Empty when unavailable.
    public let arguments: [String]
    /// Process start time in seconds since the epoch. Zero when unknown.
    public let startTime: UInt64
    public let userID: uid_t?

    public init(
        pid: pid_t,
        name: String,
        executablePath: String? = nil,
        workingDirectory: String? = nil,
        parentPID: pid_t? = nil,
        arguments: [String] = [],
        startTime: UInt64 = 0,
        userID: uid_t? = nil
    ) {
        self.pid = pid
        self.name = name
        self.executablePath = executablePath
        self.workingDirectory = workingDirectory
        self.parentPID = parentPID
        self.arguments = arguments
        self.startTime = startTime
        self.userID = userID
    }

    public var identity: ProcessIdentity {
        ProcessIdentity(pid: pid, startTime: startTime)
    }

    /// Last path component of the executable, falling back to the kernel name.
    public var executableName: String {
        guard let executablePath, let last = executablePath.split(separator: "/").last else { return name }
        return String(last)
    }

    public var commandLine: String {
        arguments.joined(separator: " ")
    }
}
