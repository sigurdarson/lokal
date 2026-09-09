import Darwin
import Testing

@testable import LokalCore

@Suite("SocketInfoParser")
struct SocketInfoParserTests {
    private func tcpInfo(family: Int32, state: Int32 = TSI_S_LISTEN, port: UInt16) -> socket_fdinfo {
        var info = socket_fdinfo()
        info.psi.soi_kind = Int32(SOCKINFO_TCP)
        info.psi.soi_family = family
        info.psi.soi_proto.pri_tcp.tcpsi_state = state
        info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport = Int32(port.bigEndian)
        return info
    }

    @Test("IPv4 loopback listener")
    func ipv4Loopback() {
        var info = tcpInfo(family: AF_INET, port: 3000)
        info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_46.i46a_addr4.s_addr = INADDR_LOOPBACK.bigEndian
        let socket = SocketInfoParser.listeningSocket(pid: 42, info: info)
        #expect(socket == ListeningSocket(pid: 42, port: 3000, family: .ipv4, address: .loopback))
        #expect(socket?.isExposedToNetwork == false)
    }

    @Test("IPv4 any-address listener is exposed")
    func ipv4Any() {
        let info = tcpInfo(family: AF_INET, port: 8080)
        let socket = SocketInfoParser.listeningSocket(pid: 7, info: info)
        #expect(socket?.address == .any)
        #expect(socket?.isExposedToNetwork == true)
    }

    @Test("IPv4 specific interface")
    func ipv4Specific() {
        var info = tcpInfo(family: AF_INET, port: 80)
        info.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_46.i46a_addr4.s_addr = UInt32(0xC0A8_0105).bigEndian
        #expect(SocketInfoParser.listeningSocket(pid: 1, info: info)?.address == .specific("192.168.1.5"))
    }

    @Test("IPv6 loopback and any")
    func ipv6() {
        var loopback = tcpInfo(family: AF_INET6, port: 5432)
        loopback.psi.soi_proto.pri_tcp.tcpsi_ini.insi_laddr.ina_6 = in6addr_loopback
        #expect(SocketInfoParser.listeningSocket(pid: 1, info: loopback)?.address == .loopback)

        let any = tcpInfo(family: AF_INET6, port: 5432)
        let socket = SocketInfoParser.listeningSocket(pid: 1, info: any)
        #expect(socket?.address == .any)
        #expect(socket?.family == .ipv6)
    }

    @Test("IPv4-mapped IPv6 loopback")
    func ipv4Mapped() {
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[10] = 0xff
        bytes[11] = 0xff
        bytes[12] = 127
        bytes[15] = 1
        #expect(SocketInfoParser.classify6(bytes) == .loopback)
    }

    @Test("Non-listening and non-TCP sockets are ignored")
    func ignored() {
        let established = tcpInfo(family: AF_INET, state: TSI_S_ESTABLISHED, port: 3000)
        #expect(SocketInfoParser.listeningSocket(pid: 1, info: established) == nil)

        var udp = tcpInfo(family: AF_INET, port: 5353)
        udp.psi.soi_kind = Int32(SOCKINFO_IN)
        #expect(SocketInfoParser.listeningSocket(pid: 1, info: udp) == nil)

        let unbound = tcpInfo(family: AF_INET, port: 0)
        #expect(SocketInfoParser.listeningSocket(pid: 1, info: unbound) == nil)
    }
}
