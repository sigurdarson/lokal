/// Something that can enumerate listening TCP sockets. Abstracted so the scanner can be tested with fixtures.
public protocol ListeningSocketSource: Sendable {
    func listeningSockets() -> [ListeningSocket]
}
