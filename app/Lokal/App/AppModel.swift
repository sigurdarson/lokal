import AppKit
import Foundation
import LokalCore
import Observation

/// Per-row kill progress. Absent means idle.
enum KillState: Equatable {
    case confirming
    case killing
    case failed(String)
}

/// Countdown for an inline kill confirmation. `deadline` is nil while the pointer hovers the control.
struct KillConfirmation: Equatable {
    static let duration: TimeInterval = 4

    var deadline: Date?
    var remaining: TimeInterval

    func fractionRemaining(at now: Date) -> Double {
        let seconds = deadline.map { max(0, $0.timeIntervalSince(now)) } ?? remaining
        return min(1, max(0, seconds / Self.duration))
    }
}

/// Owns the current snapshot, the polling lifecycle, kill confirmations and all row actions.
@Observable
final class AppModel {
    private(set) var snapshot: Snapshot = .empty
    private(set) var hasScannedOnce = false
    private(set) var isRefreshing = false
    private(set) var isPanelVisible = false
    private(set) var killStates: [String: KillState] = [:]
    private(set) var confirmations: [String: KillConfirmation] = [:]

    let preferences = Preferences()

    @ObservationIgnored private let scanner = PortScanner()
    @ObservationIgnored private let terminator = ProcessTerminator()
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var badgeTask: Task<Void, Never>?
    @ObservationIgnored private var confirmationTimers: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var failureTimers: [String: Task<Void, Never>] = [:]

    static let panelPollingInterval: Duration = .seconds(2)
    static let badgePollingInterval: Duration = .seconds(30)

    init() {
        updateBadgePolling()
    }

    /// What the header and badge count: everything, or only primary ports when auxiliary ones are folded.
    var listeningCount: Int {
        preferences.showsAuxiliaryPorts ? snapshot.entries.count : snapshot.primaryCount
    }

    var hiddenCount: Int {
        preferences.showsAuxiliaryPorts ? 0 : snapshot.auxiliaryCount
    }

    // MARK: - Group folding

    func isCollapsed(_ groupID: String) -> Bool {
        preferences.collapsedGroups.contains(groupID)
    }

    func toggleCollapsed(_ groupID: String) {
        if preferences.collapsedGroups.contains(groupID) {
            preferences.collapsedGroups.remove(groupID)
        } else {
            preferences.collapsedGroups.insert(groupID)
        }
    }

    // MARK: - Lifecycle

    func panelDidAppear() {
        isPanelVisible = true
        badgeTask?.cancel()
        badgeTask = nil
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: Self.panelPollingInterval)
            }
        }
    }

    func panelDidDisappear() {
        isPanelVisible = false
        pollingTask?.cancel()
        pollingTask = nil
        for id in Array(confirmations.keys) { cancelConfirmation(id) }
        updateBadgePolling()
    }

    /// Background polling exists only to keep the badge count honest, and only when the user asked for it.
    func updateBadgePolling() {
        badgeTask?.cancel()
        badgeTask = nil
        guard preferences.showsBadge, !isPanelVisible else { return }
        badgeTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: Self.badgePollingInterval)
            }
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        let next = await scanner.snapshot()
        snapshot = next
        hasScannedOnce = true
        let ids = Set(next.entries.map(\.id))
        for id in killStates.keys where !ids.contains(id) {
            clearKillState(id)
        }
    }

    // MARK: - Kill

    func requestKill(_ entry: PortEntry, skipConfirmation: Bool = false) {
        if skipConfirmation {
            Task { await kill(entry) }
        } else {
            beginConfirmation(entry.id)
        }
    }

    func beginConfirmation(_ id: String) {
        for other in Array(confirmations.keys) where other != id { cancelConfirmation(other) }
        setKillState(id, .confirming)
        confirmations[id] = KillConfirmation(
            deadline: Date().addingTimeInterval(KillConfirmation.duration), remaining: KillConfirmation.duration)
        scheduleRevert(id, after: KillConfirmation.duration)
    }

    /// Hovering the control pauses the countdown; leaving resumes it from where it was.
    func setConfirmationPaused(_ id: String, _ paused: Bool) {
        guard var confirmation = confirmations[id], killStates[id] == .confirming else { return }
        if paused, let deadline = confirmation.deadline {
            confirmation.remaining = max(0.5, deadline.timeIntervalSinceNow)
            confirmation.deadline = nil
            confirmationTimers[id]?.cancel()
        } else if !paused, confirmation.deadline == nil {
            confirmation.deadline = Date().addingTimeInterval(confirmation.remaining)
            scheduleRevert(id, after: confirmation.remaining)
        }
        confirmations[id] = confirmation
    }

    func cancelConfirmation(_ id: String) {
        guard killStates[id] == .confirming else { return }
        clearKillState(id)
    }

    func confirmKill(_ entry: PortEntry) {
        guard killStates[entry.id] == .confirming else { return }
        Task { await kill(entry) }
    }

    private func kill(_ entry: PortEntry) async {
        confirmationTimers[entry.id]?.cancel()
        confirmations[entry.id] = nil
        setKillState(entry.id, .killing)

        do {
            try terminator.terminate(entry.pid)
        } catch {
            fail(entry.id, message(for: error))
            return
        }

        try? await Task.sleep(for: .milliseconds(800))
        await refresh()

        if isStillListening(entry), preferences.forceKill {
            try? await Task.sleep(for: .milliseconds(1200))
            if isStillListening(entry) {
                try? terminator.forceKill(entry.pid)
                try? await Task.sleep(for: .milliseconds(400))
                await refresh()
            }
        }

        if isStillListening(entry) {
            fail(entry.id, "Still running")
        } else {
            clearKillState(entry.id)
        }
    }

    private func isStillListening(_ entry: PortEntry) -> Bool {
        snapshot.entries.contains { $0.id == entry.id && $0.process.identity == entry.process.identity }
    }

    private func fail(_ id: String, _ message: String) {
        setKillState(id, .failed(message))
        failureTimers[id]?.cancel()
        failureTimers[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            if case .failed = self?.killStates[id] { self?.clearKillState(id) }
        }
    }

    private func scheduleRevert(_ id: String, after seconds: TimeInterval) {
        confirmationTimers[id]?.cancel()
        confirmationTimers[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.cancelConfirmation(id)
        }
    }

    private func clearKillState(_ id: String) {
        confirmationTimers[id]?.cancel()
        confirmationTimers[id] = nil
        failureTimers[id]?.cancel()
        failureTimers[id] = nil
        confirmations[id] = nil
        setKillState(id, nil)
    }

    /// Mutations of kill state are wrapped in an animation so views morph rather than snap.
    private func setKillState(_ id: String, _ state: KillState?) {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .spring(duration: 0.26, bounce: 0.35)) {
            killStates[id] = state
        }
    }

    private func message(for error: any Error) -> String {
        switch error as? ProcessTerminator.Failure {
        case .notPermitted: "Not permitted"
        case .noSuchProcess: "Already gone"
        default: "Failed"
        }
    }

    // MARK: - Row actions

    func open(_ entry: PortEntry) {
        NSWorkspace.shared.open(entry.url)
    }

    func copyURL(_ entry: PortEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.url.absoluteString, forType: .string)
    }

    func revealInFinder(_ entry: PortEntry) {
        guard let path = entry.project?.path ?? entry.process.workingDirectory else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }

    func openInEditor(_ entry: PortEntry) {
        guard let path = editorPath(for: entry) else { return }
        AppLauncher.open(path, preferredBundleID: preferences.editorBundleID, fallbacks: AppLauncher.knownEditors)
    }

    func openInTerminal(_ entry: PortEntry) {
        guard let path = entry.project?.path ?? entry.process.workingDirectory else { return }
        AppLauncher.open(path, preferredBundleID: preferences.terminalBundleID, fallbacks: AppLauncher.knownTerminals)
    }

    /// Editors want the repository root; a monorepo package on its own loses context.
    private func editorPath(for entry: PortEntry) -> String? {
        entry.project?.repositoryPath ?? entry.project?.path ?? entry.process.workingDirectory
    }

    func hasProjectActions(_ entry: PortEntry) -> Bool {
        entry.project != nil || entry.process.workingDirectory.map { $0 != "/" } == true
    }
}
