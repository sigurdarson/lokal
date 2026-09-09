import Foundation

/// Works out which directories are worth walking up from to find a project.
enum CandidateDirectories {
    /// Path components that mark tooling inside a project. Everything from here on is stripped.
    static let toolingComponents: Set<String> = [
        "node_modules", ".venv", "venv", ".build", "target", ".next", ".nuxt", "dist", "build", ".cache", "vendor",
    ]

    /// Directories that are never someone's project. `/opt/homebrew` is itself a git checkout,
    /// so anything under it (Postgres data dirs, for example) would otherwise resolve to "homebrew".
    static let systemPrefixes = [
        "/usr/", "/bin/", "/sbin/", "/System/", "/Library/", "/Applications/", "/private/var/db/",
        "/private/etc/", "/etc/", "/opt/homebrew/", "/opt/local/", "/nix/",
    ]

    /// Ordered, de-duplicated candidates: own cwd, ancestors' cwds, then directories implied by script paths in argv.
    static func candidates(
        workingDirectory: String?,
        ancestorWorkingDirectories: [String],
        arguments: [String],
        home: String
    ) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        func add(_ path: String?) {
            guard let path, isUsable(path, home: home), seen.insert(path).inserted else { return }
            result.append(path)
        }
        add(workingDirectory)
        for ancestor in ancestorWorkingDirectories { add(ancestor) }
        for argument in arguments where argument.hasPrefix("/") {
            add(directory(impliedBy: argument))
        }
        return result
    }

    /// `/Users/x/proj/node_modules/.bin/vite` → `/Users/x/proj`; `/Users/x/proj/server.js` → `/Users/x/proj`.
    static func directory(impliedBy path: String) -> String? {
        let components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        guard !components.isEmpty else { return nil }
        if let cut = components.firstIndex(where: { toolingComponents.contains($0) }) {
            guard cut > 0 else { return nil }
            return "/" + components[..<cut].joined(separator: "/")
        }
        // Treat the last component as a file if it has an extension, otherwise as a directory.
        let last = components[components.count - 1]
        if last.contains(".") {
            return "/" + components.dropLast().joined(separator: "/")
        }
        return path
    }

    static func isUsable(_ path: String, home: String) -> Bool {
        guard path != "/", path != home, path != home + "/" else { return false }
        let normalized = path.hasSuffix("/") ? path : path + "/"
        return !systemPrefixes.contains { normalized.hasPrefix($0) }
    }
}
