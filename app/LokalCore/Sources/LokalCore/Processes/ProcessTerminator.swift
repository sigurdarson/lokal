import Darwin

/// Sends signals to processes. Only processes owned by the current user can be signalled without privileges.
public struct ProcessTerminator: Sendable {
    public enum Failure: Error, Sendable, Equatable {
        case notPermitted
        case noSuchProcess
        case other(Int32)

        init(errno code: Int32) {
            switch code {
            case EPERM: self = .notPermitted
            case ESRCH: self = .noSuchProcess
            default: self = .other(code)
            }
        }
    }

    public init() {}

    /// Polite request to exit.
    public func terminate(_ pid: pid_t) throws(Failure) {
        try signal(pid, SIGTERM)
    }

    /// Immediate, uncatchable kill.
    public func forceKill(_ pid: pid_t) throws(Failure) {
        try signal(pid, SIGKILL)
    }

    /// True while the process exists, even if it belongs to someone else.
    public static func isRunning(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0 || errno == EPERM
    }

    private func signal(_ pid: pid_t, _ signal: Int32) throws(Failure) {
        guard pid > 0 else { throw .noSuchProcess }
        guard kill(pid, signal) == 0 else { throw Failure(errno: errno) }
    }
}
