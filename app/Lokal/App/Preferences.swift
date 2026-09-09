import Foundation
import Observation

/// User settings, backed by `UserDefaults`. Observable so views update immediately.
@Observable
final class Preferences {
    private enum Key {
        static let showsBadge = "showsBadge"
        static let forceKill = "forceKill"
        static let editorBundleID = "editorBundleID"
        static let terminalBundleID = "terminalBundleID"
        static let showsAuxiliaryPorts = "showsAuxiliaryPorts"
    }

    private let defaults: UserDefaults

    /// Show the number of listening ports next to the menu bar icon. Enables background polling.
    var showsBadge: Bool {
        didSet { defaults.set(showsBadge, forKey: Key.showsBadge) }
    }

    /// Escalate to SIGKILL when a process ignores SIGTERM.
    var forceKill: Bool {
        didSet { defaults.set(forceKill, forKey: Key.forceKill) }
    }

    /// Empty string means "first installed editor from the known list, else the system default".
    var editorBundleID: String {
        didSet { defaults.set(editorBundleID, forKey: Key.editorBundleID) }
    }

    var terminalBundleID: String {
        didSet { defaults.set(terminalBundleID, forKey: Key.terminalBundleID) }
    }

    /// Always list auxiliary ports (inspectors, ephemeral sockets, apps, system daemons) instead of folding them per group.
    var showsAuxiliaryPorts: Bool {
        didSet { defaults.set(showsAuxiliaryPorts, forKey: Key.showsAuxiliaryPorts) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsBadge = defaults.bool(forKey: Key.showsBadge)
        forceKill = defaults.object(forKey: Key.forceKill) as? Bool ?? true
        editorBundleID = defaults.string(forKey: Key.editorBundleID) ?? ""
        terminalBundleID = defaults.string(forKey: Key.terminalBundleID) ?? ""
        showsAuxiliaryPorts = defaults.bool(forKey: Key.showsAuxiliaryPorts)
    }
}
