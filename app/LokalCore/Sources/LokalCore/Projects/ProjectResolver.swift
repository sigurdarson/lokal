import Foundation

/// Finds the project a process belongs to by walking up from its working directory
/// (or the directories implied by its parents and command line) to the nearest manifest and git root.
public struct ProjectResolver: Sendable {
    public struct Input: Sendable {
        public var workingDirectory: String?
        public var ancestorWorkingDirectories: [String]
        public var arguments: [String]

        public init(workingDirectory: String?, ancestorWorkingDirectories: [String] = [], arguments: [String] = []) {
            self.workingDirectory = workingDirectory
            self.ancestorWorkingDirectories = ancestorWorkingDirectories
            self.arguments = arguments
        }
    }

    /// Files larger than this are not parsed.
    static let maximumManifestSize = 512 * 1024

    /// The walk stops before this directory. Home is never itself a project.
    public let homeDirectory: String

    public init(homeDirectory: String = NSHomeDirectory()) {
        self.homeDirectory = Self.trimmed(homeDirectory)
    }

    public func resolve(_ input: Input) -> Project? {
        let candidates = CandidateDirectories.candidates(
            workingDirectory: input.workingDirectory,
            ancestorWorkingDirectories: input.ancestorWorkingDirectories,
            arguments: input.arguments,
            home: homeDirectory
        )
        for candidate in candidates {
            if let project = resolve(directory: candidate) {
                return project
            }
        }
        return nil
    }

    /// Walks up from `directory` towards home. Nearest manifest names the project; nearest `.git` groups it.
    public func resolve(directory: String) -> Project? {
        var current = Self.trimmed(directory)
        var nearestManifest: (kind: ManifestKind, name: String, path: String)?
        var gitRoot: String?

        while current != "/", current != homeDirectory, !current.isEmpty {
            if nearestManifest == nil, let found = manifest(in: current) {
                nearestManifest = found
            }
            if Self.isGitRoot(current) {
                gitRoot = current
                break
            }
            let parent = (current as NSString).deletingLastPathComponent
            guard parent != current else { break }
            current = parent
        }

        if let manifest = nearestManifest {
            let repositoryName = gitRoot.map { ($0 as NSString).lastPathComponent }
            return Project(
                name: manifest.name,
                path: manifest.path,
                repositoryName: repositoryName,
                repositoryPath: gitRoot,
                manifest: manifest.kind
            )
        }
        if let gitRoot {
            let name = (gitRoot as NSString).lastPathComponent
            return Project(name: name, path: gitRoot, repositoryName: name, repositoryPath: gitRoot, manifest: .git)
        }
        return nil
    }

    // MARK: - Manifest lookup

    private func manifest(in directory: String) -> (kind: ManifestKind, name: String, path: String)? {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: directory) else { return nil }
        let names = Set(entries)
        let directoryName = (directory as NSString).lastPathComponent

        func read(_ file: String) -> Data? {
            let path = (directory as NSString).appendingPathComponent(file)
            guard let attributes = try? fileManager.attributesOfItem(atPath: path),
                let size = attributes[.size] as? Int, size <= Self.maximumManifestSize
            else { return nil }
            return fileManager.contents(atPath: path)
        }
        func text(_ file: String) -> String? {
            read(file).map { String(decoding: $0, as: UTF8.self) }
        }
        func result(_ kind: ManifestKind, _ name: String?) -> (ManifestKind, String, String) {
            (kind, name ?? directoryName, directory)
        }

        if names.contains("package.json") {
            return result(.packageJSON, read("package.json").flatMap(ManifestParsers.packageJSON))
        }
        if names.contains("Package.swift") {
            return result(.packageSwift, text("Package.swift").flatMap(ManifestParsers.packageSwift))
        }
        if names.contains("Cargo.toml") { return result(.cargo, text("Cargo.toml").flatMap(ManifestParsers.cargo)) }
        if names.contains("pyproject.toml") {
            return result(.pyproject, text("pyproject.toml").flatMap(ManifestParsers.pyproject))
        }
        if names.contains("go.mod") { return result(.goMod, text("go.mod").flatMap(ManifestParsers.goMod)) }
        if let gemspec = entries.first(where: { $0.hasSuffix(".gemspec") }) {
            return result(.gemspec, text(gemspec).flatMap(ManifestParsers.gemspec))
        }
        if names.contains("Gemfile") { return result(.gemfile, nil) }
        if names.contains("composer.json") {
            return result(.composer, read("composer.json").flatMap(ManifestParsers.composer))
        }
        if names.contains("mix.exs") { return result(.mix, text("mix.exs").flatMap(ManifestParsers.mix)) }
        if let deno = ["deno.json", "deno.jsonc"].first(where: names.contains) {
            return result(.deno, read(deno).flatMap(ManifestParsers.deno))
        }
        if names.contains("pubspec.yaml") {
            return result(.pubspec, text("pubspec.yaml").flatMap(ManifestParsers.pubspec))
        }
        if let gradle = ["settings.gradle.kts", "settings.gradle"].first(where: names.contains) {
            return result(.gradle, text(gradle).flatMap(ManifestParsers.gradle))
        }
        if names.contains("CMakeLists.txt") {
            return result(.cmake, text("CMakeLists.txt").flatMap(ManifestParsers.cmake))
        }
        if let xcode = entries.first(where: { $0.hasSuffix(".xcworkspace") })
            ?? entries.first(where: { $0.hasSuffix(".xcodeproj") })
        {
            return result(.xcodeproj, (xcode as NSString).deletingPathExtension)
        }
        return nil
    }

    /// `.git` may be a directory or, for worktrees and submodules, a file.
    private static func isGitRoot(_ directory: String) -> Bool {
        FileManager.default.fileExists(atPath: (directory as NSString).appendingPathComponent(".git"))
    }

    private static func trimmed(_ path: String) -> String {
        path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }
}
