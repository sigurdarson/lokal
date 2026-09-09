import Foundation

/// Small, dependency-free extractors of a project name from manifest contents.
/// Each returns nil when the file has no usable name; the caller then falls back to the directory name.
enum ManifestParsers {
    static func packageJSON(_ data: Data) -> String? {
        jsonName(data).map(stripScope)
    }

    static func packageSwift(_ text: String) -> String? {
        firstCapture(#/name:\s*"([^"]+)"/#, in: text)
    }

    static func cargo(_ text: String) -> String? {
        tomlValue(section: "package", key: "name", in: text)
    }

    static func pyproject(_ text: String) -> String? {
        tomlValue(section: "project", key: "name", in: text)
            ?? tomlValue(section: "tool.poetry", key: "name", in: text)
    }

    static func goMod(_ text: String) -> String? {
        guard let module = firstCapture(#/(?m)^module\s+(\S+)/#, in: text) else { return nil }
        var parts = module.split(separator: "/").map(String.init)
        if parts.count > 1, let last = parts.last, last.wholeMatch(of: #/v\d+/#) != nil {
            parts.removeLast()
        }
        return parts.last
    }

    static func gemspec(_ text: String) -> String? {
        firstCapture(#/\.name\s*=\s*['"]([^'"]+)['"]/#, in: text)
    }

    static func composer(_ data: Data) -> String? {
        jsonName(data).map { name in
            name.split(separator: "/").last.map(String.init) ?? name
        }
    }

    static func mix(_ text: String) -> String? {
        firstCapture(#/app:\s*:([A-Za-z0-9_]+)/#, in: text)
    }

    static func deno(_ data: Data) -> String? {
        jsonName(data).map(stripScope)
    }

    static func pubspec(_ text: String) -> String? {
        firstCapture(#/(?m)^name:\s*([^\s#]+)/#, in: text)
    }

    static func gradle(_ text: String) -> String? {
        firstCapture(#/rootProject\.name\s*=\s*['"]([^'"]+)['"]/#, in: text)
    }

    static func cmake(_ text: String) -> String? {
        firstCapture(#/(?i)project\s*\(\s*([A-Za-z0-9_.\-]+)/#, in: text)
    }

    // MARK: - Helpers

    /// `@scope/name` → `name`.
    static func stripScope(_ name: String) -> String {
        guard name.hasPrefix("@"), let slash = name.firstIndex(of: "/") else { return name }
        return String(name[name.index(after: slash)...])
    }

    private static func jsonName(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let name = object["name"] as? String
        else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func firstCapture(_ regex: Regex<(Substring, Substring)>, in text: String) -> String? {
        guard let match = text.firstMatch(of: regex) else { return nil }
        let value = String(match.output.1).trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    /// Finds `key = "value"` inside `[section]`, ignoring other sections. Enough TOML for manifests.
    static func tomlValue(section: String, key: String, in text: String) -> String? {
        var inSection = false
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                inSection = line == "[\(section)]"
                continue
            }
            guard inSection, !line.hasPrefix("#") else { continue }
            guard let equals = line.firstIndex(of: "=") else { continue }
            let lhs = line[..<equals].trimmingCharacters(in: .whitespaces)
            guard lhs == key else { continue }
            let rhs = line[line.index(after: equals)...].trimmingCharacters(in: .whitespaces)
            let value: String
            if let quote = rhs.first, quote == "\"" || quote == "'" {
                let inner = rhs.dropFirst()
                value = String(inner.prefix { $0 != quote })
            } else {
                value = rhs.prefix { $0 != "#" }.trimmingCharacters(in: .whitespaces)
            }
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
