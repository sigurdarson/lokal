import Foundation
import Testing

@testable import LokalCore

/// Builds throwaway directory trees under a temp "home" so the walk stops predictably.
struct TemporaryTree {
    let home: URL

    init() throws {
        home = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("lokal-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
    }

    @discardableResult
    func directory(_ path: String) throws -> String {
        let url = home.appendingPathComponent(path, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.path
    }

    func file(_ path: String, _ contents: String = "") throws {
        let url = home.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    func path(_ relative: String) -> String {
        home.appendingPathComponent(relative).path
    }

    func remove() {
        try? FileManager.default.removeItem(at: home)
    }
}

@Suite("ProjectResolver")
struct ProjectResolverTests {
    @Test("Nearest manifest names the project, git root groups it")
    func monorepo() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.directory("code/lokal/.git")
        try tree.file("code/lokal/package.json", #"{"name": "lokal-monorepo"}"#)
        try tree.file("code/lokal/apps/web/package.json", #"{"name": "@lokal/web"}"#)
        try tree.directory("code/lokal/apps/web/src")

        let resolver = ProjectResolver(homeDirectory: tree.home.path)
        let project = try #require(resolver.resolve(directory: tree.path("code/lokal/apps/web/src")))
        #expect(project.name == "web")
        #expect(project.repositoryName == "lokal")
        #expect(project.displayName == "lokal / web")
        #expect(project.groupKey == tree.path("code/lokal"))
        #expect(project.manifest == .packageJSON)
    }

    @Test("Git root only")
    func gitOnly() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.directory("src/tool/.git")
        try tree.directory("src/tool/lib")

        let project = ProjectResolver(homeDirectory: tree.home.path).resolve(directory: tree.path("src/tool/lib"))
        #expect(project?.name == "tool")
        #expect(project?.displayName == "tool")
        #expect(project?.manifest == .git)
    }

    @Test("Worktree .git file counts as a root")
    func worktreeFile() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.file("wt/feature/.git", "gitdir: /somewhere/.git/worktrees/feature")
        try tree.file("wt/feature/go.mod", "module example.com/org/svc\n")

        let project = ProjectResolver(homeDirectory: tree.home.path).resolve(directory: tree.path("wt/feature"))
        #expect(project?.name == "svc")
        #expect(project?.repositoryName == "feature")
        #expect(project?.displayName == "feature / svc")
    }

    @Test("Manifest without a name falls back to the directory name")
    func privatePackage() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.file("p/site/package.json", #"{"private": true}"#)

        let project = ProjectResolver(homeDirectory: tree.home.path).resolve(directory: tree.path("p/site"))
        #expect(project?.name == "site")
        #expect(project?.repositoryName == nil)
    }

    @Test("Same-name repo and package collapse to one label")
    func sameName() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.directory("r/app/.git")
        try tree.file("r/app/Cargo.toml", "[package]\nname = \"app\"")

        let project = ProjectResolver(homeDirectory: tree.home.path).resolve(directory: tree.path("r/app"))
        #expect(project?.displayName == "app")
    }

    @Test("Nothing found yields nil; home itself is never a project")
    func nothing() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.file("package.json", #"{"name": "home-should-be-ignored"}"#)
        try tree.directory("plain/dir")

        let resolver = ProjectResolver(homeDirectory: tree.home.path)
        #expect(resolver.resolve(directory: tree.path("plain/dir")) == nil)
        #expect(resolver.resolve(directory: tree.home.path) == nil)
    }

    @Test("Falls back to ancestor cwd and argv script path")
    func inputFallbacks() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.file("proj/package.json", #"{"name": "viteapp"}"#)
        try tree.directory("proj/node_modules/.bin")

        let resolver = ProjectResolver(homeDirectory: tree.home.path)
        let viaAncestor = resolver.resolve(
            ProjectResolver.Input(workingDirectory: "/", ancestorWorkingDirectories: [tree.path("proj")])
        )
        #expect(viaAncestor?.name == "viteapp")

        let viaArgv = resolver.resolve(
            ProjectResolver.Input(
                workingDirectory: nil,
                arguments: ["node", tree.path("proj/node_modules/.bin/vite"), "--port", "5173"]
            )
        )
        #expect(viaArgv?.name == "viteapp")
    }

    @Test("Xcode project directory")
    func xcode() throws {
        let tree = try TemporaryTree()
        defer { tree.remove() }
        try tree.directory("ios/Fancy.xcodeproj")
        #expect(ProjectResolver(homeDirectory: tree.home.path).resolve(directory: tree.path("ios"))?.name == "Fancy")
    }
}

@Suite("CandidateDirectories")
struct CandidateDirectoriesTests {
    @Test("Strips tooling components and file names")
    func implied() {
        #expect(CandidateDirectories.directory(impliedBy: "/Users/x/proj/node_modules/.bin/vite") == "/Users/x/proj")
        #expect(CandidateDirectories.directory(impliedBy: "/Users/x/proj/.venv/bin/python") == "/Users/x/proj")
        #expect(CandidateDirectories.directory(impliedBy: "/Users/x/proj/server.js") == "/Users/x/proj")
        #expect(CandidateDirectories.directory(impliedBy: "/Users/x/proj/bin/serve") == "/Users/x/proj/bin/serve")
        #expect(CandidateDirectories.directory(impliedBy: "/node_modules/x") == nil)
    }

    @Test("Rejects root, home and system paths; keeps order and uniqueness")
    func filtering() {
        let home = "/Users/x"
        let candidates = CandidateDirectories.candidates(
            workingDirectory: "/",
            ancestorWorkingDirectories: ["/Users/x", "/Users/x/code/a", "/Users/x/code/a"],
            arguments: ["/usr/bin/node", "/Users/x/code/a/node_modules/.bin/next", "/Applications/Foo.app/x"],
            home: home
        )
        #expect(candidates == ["/Users/x/code/a"])
        #expect(!CandidateDirectories.isUsable("/System/Library", home: home))
        #expect(!CandidateDirectories.isUsable("/opt/homebrew/var/postgresql@16", home: home))
        #expect(CandidateDirectories.isUsable("/Volumes/work/pg", home: home))
    }
}
