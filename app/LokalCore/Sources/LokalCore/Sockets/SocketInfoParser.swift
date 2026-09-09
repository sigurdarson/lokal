import Darwin

/// Turns a `socket_fdinfo` from `PROC_PIDFDSOCKETINFO` into a `ListeningSocket`, or nil if it is not a listening TCP socket.
/// Pure, so it can be unit tested by constructing the C struct by hand.
enum SocketInfoParser {
    static func listeningSocket(pid: pid_t, info: socket_fdinfo) -> ListeningSocket? {
        let socket = info.psi
        guard socket.soi_kind == SOCKINFO_TCP else { return nil }
        let tcp = socket.soi_proto.pri_tcp
        guard tcp.tcpsi_state == TSI_S_LISTEN else { return nil }

        let inet = tcp.tcpsi_ini
        let port = UInt16(bigEndian: UInt16(truncatingIfNeeded: inet.insi_lport))
        guard port != 0 else { return nil }

        let usesIPv6 = socket.soi_family == AF_INET6 || (Int32(inet.insi_vflag) & INI_IPV6) != 0
        guard usesIPv6 else {
            let raw = inet.insi_laddr.ina_46.i46a_addr4.s_addr
            return ListeningSocket(pid: pid, port: port, family: .ipv4, address: classify4(raw))
        }
        var address6 = inet.insi_laddr.ina_6
        let bytes = withUnsafeBytes(of: &address6) { Array($0) }
        return ListeningSocket(pid: pid, port: port, family: .ipv6, address: classify6(bytes))
    }

    static func classify4(_ networkOrder: in_addr_t) -> ListeningSocket.BoundAddress {
        let host = UInt32(bigEndian: networkOrder)
        if host == INADDR_ANY { return .any }
        if host >> 24 == 127 { return .loopback }
        let octets = [host >> 24, (host >> 16) & 0xff, (host >> 8) & 0xff, host & 0xff]
        return .specific(octets.map(String.init).joined(separator: "."))
    }

    static func classify6(_ bytes: [UInt8]) -> ListeningSocket.BoundAddress {
        guard bytes.count == 16 else { return .any }
        if bytes.allSatisfy({ $0 == 0 }) { return .any }
        if bytes.prefix(15).allSatisfy({ $0 == 0 }) && bytes[15] == 1 { return .loopback }
        // IPv4-mapped ::ffff:a.b.c.d
        if bytes.prefix(10).allSatisfy({ $0 == 0 }), bytes[10] == 0xff, bytes[11] == 0xff {
            let v4 = bytes[12...15]
            if v4.allSatisfy({ $0 == 0 }) { return .any }
            if v4.first == 127 { return .loopback }
            return .specific(v4.map(String.init).joined(separator: "."))
        }
        var groups: [String] = []
        for index in stride(from: 0, to: 16, by: 2) {
            groups.append(String(UInt16(bytes[index]) << 8 | UInt16(bytes[index + 1]), radix: 16))
        }
        return .specific(groups.joined(separator: ":"))
    }
}
