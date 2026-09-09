import Darwin

/// Enumerates listening TCP sockets with libproc: every pid, every socket fd, filtered to `TSI_S_LISTEN`.
///
/// This is the same mechanism `lsof` uses on macOS. It cannot see sockets owned by other users
/// (the kernel returns EPERM), which is accepted: Lokal is about the current user's work.
public struct LibprocSocketSource: ListeningSocketSource {
    public init() {}

    public func listeningSockets() -> [ListeningSocket] {
        var byKey: [String: ListeningSocket] = [:]
        for pid in Libproc.allPIDs() {
            for fd in Libproc.fileDescriptors(of: pid) where fd.proc_fdtype == PROX_FDTYPE_SOCKET {
                guard let info = Libproc.socketInfo(pid: pid, fd: fd.proc_fd),
                    let socket = SocketInfoParser.listeningSocket(pid: pid, info: info)
                else { continue }
                Self.merge(socket, into: &byKey)
            }
        }
        return byKey.values.sorted { lhs, rhs in
            lhs.port != rhs.port ? lhs.port < rhs.port : lhs.pid < rhs.pid
        }
    }

    /// Dual-stack servers listen on both families for one port; show that once. IPv4 wins for display.
    static func merge(_ socket: ListeningSocket, into byKey: inout [String: ListeningSocket]) {
        let key = "\(socket.pid):\(socket.port)"
        guard let existing = byKey[key] else {
            byKey[key] = socket
            return
        }
        if existing.family == .ipv6, socket.family == .ipv4 {
            byKey[key] = socket
        } else if existing.address == .loopback, socket.address != .loopback, existing.family == socket.family {
            byKey[key] = socket
        }
    }
}
