/// Produces a short human label from a command line, e.g. `next dev` or `server.js`,
/// for processes whose executable name says nothing (`node`, `python`, ...).
public enum CommandLabeler {
    /// Executables that are runtimes rather than programs. Their first script argument is the real name.
    public static let genericRuntimes: Set<String> = [
        "node", "nodejs", "bun", "deno", "tsx", "ts-node",
        "python", "python3", "python3.12", "python3.13", "python3.14",
        "ruby", "java", "php", "dotnet", "perl", "lua", "erl", "beam.smp",
    ]

    public static func isGenericRuntime(_ process: ProcessDetails) -> Bool {
        genericRuntimes.contains(process.name.lowercased())
            || genericRuntimes.contains(process.executableName.lowercased())
    }

    /// Returns a label derived from the arguments, or nil when the executable name is already descriptive.
    public static func label(for process: ProcessDetails) -> String? {
        guard isGenericRuntime(process), process.arguments.count > 1 else { return nil }
        let args = Array(process.arguments.dropFirst())

        // Skip runtime flags such as `--inspect`, `-m module`, `--loader x`.
        var index = 0
        while index < args.count, args[index].hasPrefix("-") {
            if ["-m", "-r", "--require", "--loader", "--import"].contains(args[index]), index + 1 < args.count {
                if args[index] == "-m" {
                    // `python -m http.server 8000` → `http.server`
                    return trailing(args[index + 1], from: args, after: index + 1)
                }
                index += 1
            }
            index += 1
        }
        guard index < args.count else { return nil }

        let script = args[index]
        let base = script.split(separator: "/").last.map(String.init) ?? script
        var name = base
        for suffix in [".js", ".mjs", ".cjs", ".ts", ".mts", ".py", ".rb", ".jar", ".php"] where name.hasSuffix(suffix)
        {
            name = String(name.dropLast(suffix.count))
            break
        }
        guard !name.isEmpty else { return nil }
        return trailing(name, from: args, after: index)
    }

    /// Appends the first non-flag argument after the script, if it is short and word-like (`dev`, `start`, `serve`).
    private static func trailing(_ name: String, from args: [String], after index: Int) -> String {
        guard index + 1 < args.count else { return name }
        let next = args[index + 1]
        let isWord = !next.hasPrefix("-") && next.count <= 12 && !next.contains("/") && !next.contains(".")
        return isWord ? "\(name) \(next)" : name
    }
}
