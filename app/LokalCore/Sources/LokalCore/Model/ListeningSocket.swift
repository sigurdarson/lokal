import Darwin

/// A TCP socket in the LISTEN state, owned by a local process.
public struct ListeningSocket: Sendable, Hashable {
    public enum Family: Sendable, Hashable {
        case ipv4
        case ipv6
    }

    /// The local address the socket is bound to, reduced to what matters for display.
    public enum BoundAddress: Sendable, Hashable {
        /// Bound to 127.0.0.1 or ::1. Only reachable from this machine.
        case loopback
        /// Bound to 0.0.0.0 or ::. Reachable from other hosts on the network.
        case any
        /// Bound to a specific interface address.
        case specific(String)
    }

    public let pid: pid_t
    public let port: UInt16
    public let family: Family
    public let address: BoundAddress

    public init(pid: pid_t, port: UInt16, family: Family, address: BoundAddress) {
        self.pid = pid
        self.port = port
        self.family = family
        self.address = address
    }

    /// True when the socket accepts connections from other hosts, not just localhost.
    public var isExposedToNetwork: Bool {
        switch address {
        case .loopback: false
        case .any, .specific: true
        }
    }
}
