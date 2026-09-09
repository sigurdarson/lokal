import AppKit

/// An application the user can open a project with.
struct AppChoice: Identifiable, Hashable, Sendable {
    let name: String
    let bundleID: String
    var id: String { bundleID }
}

/// Opens project directories in editors and terminals, with sensible fallbacks.
enum AppLauncher {
    static let knownEditors: [AppChoice] = [
        AppChoice(name: "Visual Studio Code", bundleID: "com.microsoft.VSCode"),
        AppChoice(name: "Cursor", bundleID: "com.todesktop.230313mzl4w4u92"),
        AppChoice(name: "Zed", bundleID: "dev.zed.Zed"),
        AppChoice(name: "Xcode", bundleID: "com.apple.dt.Xcode"),
        AppChoice(name: "IntelliJ IDEA", bundleID: "com.jetbrains.intellij"),
        AppChoice(name: "WebStorm", bundleID: "com.jetbrains.WebStorm"),
        AppChoice(name: "PyCharm", bundleID: "com.jetbrains.pycharm"),
        AppChoice(name: "RubyMine", bundleID: "com.jetbrains.rubymine"),
        AppChoice(name: "GoLand", bundleID: "com.jetbrains.goland"),
        AppChoice(name: "Fleet", bundleID: "com.jetbrains.fleet"),
        AppChoice(name: "Windsurf", bundleID: "com.exafunction.windsurf"),
        AppChoice(name: "Sublime Text", bundleID: "com.sublimetext.4"),
        AppChoice(name: "Nova", bundleID: "com.panic.Nova"),
        AppChoice(name: "Emacs", bundleID: "org.gnu.Emacs"),
    ]

    static let knownTerminals: [AppChoice] = [
        AppChoice(name: "Terminal", bundleID: "com.apple.Terminal"),
        AppChoice(name: "iTerm", bundleID: "com.googlecode.iterm2"),
        AppChoice(name: "Ghostty", bundleID: "com.mitchellh.ghostty"),
        AppChoice(name: "Warp", bundleID: "dev.warp.Warp-Stable"),
        AppChoice(name: "kitty", bundleID: "net.kovidgoyal.kitty"),
        AppChoice(name: "WezTerm", bundleID: "com.github.wez.wezterm"),
        AppChoice(name: "Alacritty", bundleID: "org.alacritty"),
    ]

    static func applicationURL(bundleID: String) -> URL? {
        guard !bundleID.isEmpty else { return nil }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    static func installed(_ choices: [AppChoice]) -> [AppChoice] {
        choices.filter { applicationURL(bundleID: $0.bundleID) != nil }
    }

    /// Opens `path` with the preferred app, else the first installed known app, else whatever macOS picks.
    static func open(_ path: String, preferredBundleID: String, fallbacks: [AppChoice]) {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        let candidates = [preferredBundleID] + fallbacks.map(\.bundleID)
        for bundleID in candidates {
            if let application = applicationURL(bundleID: bundleID) {
                NSWorkspace.shared.open(
                    [url], withApplicationAt: application, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        NSWorkspace.shared.open(url)
    }
}
