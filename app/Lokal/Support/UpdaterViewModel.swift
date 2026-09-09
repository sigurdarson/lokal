import Foundation
import Observation
import Sparkle

/// Bridges Sparkle's KVO-based `SPUUpdater` into SwiftUI.
@Observable
final class UpdaterViewModel {
    private(set) var canCheckForUpdates = false

    @ObservationIgnored private let updater: SPUUpdater
    @ObservationIgnored private var observation: NSKeyValueObservation?

    init(updater: SPUUpdater) {
        self.updater = updater
        observation = updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            // Sparkle updates this property on the main thread.
            MainActor.assumeIsolated {
                self?.canCheckForUpdates = updater.canCheckForUpdates
            }
        }
    }

    var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set { updater.automaticallyChecksForUpdates = newValue }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
