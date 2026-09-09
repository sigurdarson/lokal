/// The kind of file that identified a project directory.
public enum ManifestKind: String, Sendable, Hashable, CaseIterable {
    case packageJSON = "package.json"
    case packageSwift = "Package.swift"
    case cargo = "Cargo.toml"
    case pyproject = "pyproject.toml"
    case goMod = "go.mod"
    case gemspec = "gemspec"
    case gemfile = "Gemfile"
    case composer = "composer.json"
    case mix = "mix.exs"
    case deno = "deno.json"
    case pubspec = "pubspec.yaml"
    case gradle = "settings.gradle"
    case cmake = "CMakeLists.txt"
    case xcodeproj = "xcodeproj"
    case git = ".git"
}

/// A project that a listening process belongs to.
public struct Project: Sendable, Hashable {
    /// Display name, from the nearest manifest or the directory name.
    public let name: String
    /// Directory containing the manifest that named the project.
    public let path: String
    /// Name of the enclosing git repository, when one exists.
    public let repositoryName: String?
    /// Root of the enclosing git repository, when one exists.
    public let repositoryPath: String?
    public let manifest: ManifestKind

    public init(
        name: String, path: String, repositoryName: String? = nil, repositoryPath: String? = nil, manifest: ManifestKind
    ) {
        self.name = name
        self.path = path
        self.repositoryName = repositoryName
        self.repositoryPath = repositoryPath
        self.manifest = manifest
    }

    /// Entries sharing this key are grouped together in the panel.
    public var groupKey: String {
        repositoryPath ?? path
    }

    /// Name of the group this project belongs to (the repository if there is one).
    public var groupName: String {
        repositoryName ?? name
    }

    /// `repo / package` for a package inside a monorepo, otherwise just the name.
    public var displayName: String {
        if let repositoryName, repositoryName != name {
            return "\(repositoryName) / \(name)"
        }
        return name
    }
}
