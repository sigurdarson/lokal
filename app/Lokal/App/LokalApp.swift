import LokalCore
import Sparkle
import SwiftUI

@main
struct LokalApp: App {
    @State private var model = AppModel()
    @State private var updaterModel: UpdaterViewModel
    private let updaterController: SPUStandardUpdaterController

    init() {
        // Sparkle's standard controller drives the whole update UI. Starting it here schedules
        // the periodic check (every 24 h by default, user-controllable in Settings).
        let controller = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        updaterController = controller
        _updaterModel = State(initialValue: UpdaterViewModel(updater: controller.updater))
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView(updaterModel: updaterModel)
                .environment(model)
        } label: {
            MenuBarLabel(count: model.listeningCount, showsBadge: model.preferences.showsBadge)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(updaterModel: updaterModel)
                .environment(model)
        }
    }
}
