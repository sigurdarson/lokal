import Darwin
import Testing

@testable import LokalCore

/// Opens a real listener in the test process and checks that the libproc scan finds it.
@Suite("LibprocSocketSource")
struct LibprocSocketSourceTests {
    /// Binds a listening socket on the loopback address of `family` and returns (fd, port).
    private func listen(family: Int32) throws -> (fd: Int32, port: UInt16) {
        let fd = socket(family, SOCK_STREAM, 0)
        try #require(fd >= 0)
        var one: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, socklen_t(MemoryLayout<Int32>.size))

        if family == AF_INET {
            var address = sockaddr_in()
            address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            address.sin_family = sa_family_t(AF_INET)
            address.sin_addr.s_addr = INADDR_LOOPBACK.bigEndian
            let bound = withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            try #require(bound == 0)
        } else {
            var address = sockaddr_in6()
            address.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
            address.sin6_family = sa_family_t(AF_INET6)
            address.sin6_addr = in6addr_loopback
            let bound = withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in6>.size))
                }
            }
            try #require(bound == 0)
        }
        try #require(Darwin.listen(fd, 8) == 0)

        var storage = sockaddr_storage()
        var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let named = withUnsafeMutablePointer(to: &storage) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &length) }
        }
        try #require(named == 0)
        let port: UInt16 = withUnsafePointer(to: &storage) {
            if family == AF_INET {
                $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { UInt16(bigEndian: $0.pointee.sin_port) }
            } else {
                $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { UInt16(bigEndian: $0.pointee.sin6_port) }
            }
        }
        return (fd, port)
    }

    @Test("Finds this process's own IPv4 listener")
    func findsOwnIPv4Listener() throws {
        let (fd, port) = try listen(family: AF_INET)
        defer { close(fd) }

        let sockets = LibprocSocketSource().listeningSockets()
        let mine = sockets.first { $0.pid == getpid() && $0.port == port }
        #expect(mine != nil)
        #expect(mine?.family == .ipv4)
        #expect(mine?.address == .loopback)
    }

    @Test("Finds this process's own IPv6 listener")
    func findsOwnIPv6Listener() throws {
        let (fd, port) = try listen(family: AF_INET6)
        defer { close(fd) }

        let mine = LibprocSocketSource().listeningSockets().first { $0.pid == getpid() && $0.port == port }
        #expect(mine != nil)
        #expect(mine?.family == .ipv6)
        #expect(mine?.address == .loopback)
    }

    @Test("Results are sorted and unique per pid and port")
    func sortedAndUnique() throws {
        let (fd, _) = try listen(family: AF_INET)
        defer { close(fd) }
        let sockets = LibprocSocketSource().listeningSockets()
        let keys = sockets.map { "\($0.pid):\($0.port)" }
        #expect(Set(keys).count == keys.count)
        #expect(sockets.map(\.port) == sockets.map(\.port).sorted())
    }

    @Test("Dual-stack merge prefers IPv4 and non-loopback")
    func merge() {
        var byKey: [String: ListeningSocket] = [:]
        LibprocSocketSource.merge(ListeningSocket(pid: 1, port: 80, family: .ipv6, address: .any), into: &byKey)
        LibprocSocketSource.merge(ListeningSocket(pid: 1, port: 80, family: .ipv4, address: .loopback), into: &byKey)
        #expect(byKey["1:80"]?.family == .ipv4)
        LibprocSocketSource.merge(ListeningSocket(pid: 1, port: 80, family: .ipv4, address: .any), into: &byKey)
        #expect(byKey["1:80"]?.address == .any)
        #expect(byKey.count == 1)
    }
}
