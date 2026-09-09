import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let updaterModel: UpdaterViewModel

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginItemError: String?
    @State private var automaticUpdates = false

    var body: some View {
        @Bindable var preferences = model.preferences

        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            try LoginItem.setEnabled(enabled)
                            loginItemError = nil
                        } catch {
                            loginItemError = error.localizedDescription
                            launchAtLogin = LoginItem.isEnabled
                        }
                    }
                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Toggle("Show port count in the menu bar", isOn: $preferences.showsBadge)
                    .onChange(of: preferences.showsBadge) { _, _ in model.updateBadgePolling() }
                Text(
                    "Showing the count polls every 30 seconds while the panel is closed. Otherwise Lokal only scans while the panel is open."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Killing") {
                Toggle("Force kill if a process ignores the request", isOn: $preferences.forceKill)
                Text("Lokal sends SIGTERM first and waits about a second. With this on, it follows up with SIGKILL.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Open with") {
                Picker("Editor", selection: $preferences.editorBundleID) {
                    Text("First installed").tag("")
                    ForEach(AppLauncher.installed(AppLauncher.knownEditors)) { choice in
                        Text(choice.name).tag(choice.bundleID)
                    }
                }
                Picker("Terminal", selection: $preferences.terminalBundleID) {
                    Text("First installed").tag("")
                    ForEach(AppLauncher.installed(AppLauncher.knownTerminals)) { choice in
                        Text(choice.name).tag(choice.bundleID)
                    }
                }
            }

            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $automaticUpdates)
                    .onChange(of: automaticUpdates) { _, enabled in updaterModel.automaticallyChecksForUpdates = enabled
                    }
                HStack {
                    Text("Updates are fetched from lokal.sigurdarson.is. This is the only network request Lokal makes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check Now") { updaterModel.checkForUpdates() }
                        .disabled(!updaterModel.canCheckForUpdates)
                }
            }

            Section("About") {
                LabeledContent("Version", value: Self.versionString)
                Link("lokal.sigurdarson.is", destination: URL(string: "https://lokal.sigurdarson.is")!)
                Link("Source on GitHub", destination: URL(string: "https://github.com/sigurdarson/lokal")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            automaticUpdates = updaterModel.automaticallyChecksForUpdates
            launchAtLogin = LoginItem.isEnabled
            NSApplication.shared.activate()
        }
    }

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}
