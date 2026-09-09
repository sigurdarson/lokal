import Foundation
import Testing

@testable import LokalCore

@Suite("ManifestParsers")
struct ManifestParsersTests {
    @Test("package.json name with and without scope")
    func packageJSON() {
        #expect(ManifestParsers.packageJSON(Data(#"{"name": "@acme/web", "private": true}"#.utf8)) == "web")
        #expect(ManifestParsers.packageJSON(Data(#"{"name": "lokal-site"}"#.utf8)) == "lokal-site")
        #expect(ManifestParsers.packageJSON(Data(#"{"private": true}"#.utf8)) == nil)
        #expect(ManifestParsers.packageJSON(Data("not json".utf8)) == nil)
    }

    @Test("Package.swift")
    func packageSwift() {
        let text = """
            // swift-tools-version: 6.0
            import PackageDescription
            let package = Package(
                name: "LokalCore",
                products: [.library(name: "Other", targets: ["X"])]
            )
            """
        #expect(ManifestParsers.packageSwift(text) == "LokalCore")
    }

    @Test("Cargo.toml package and workspace")
    func cargo() {
        #expect(
            ManifestParsers.cargo("[package]\nname = \"ripgrep\"\nversion = \"1\"\n\n[dependencies]\nname = \"x\"")
                == "ripgrep")
        #expect(ManifestParsers.cargo("[workspace]\nmembers = [\"a\"]") == nil)
        #expect(
            ManifestParsers.cargo("[dependencies]\nname = \"decoy\"\n[package]\nname = 'single' # comment") == "single")
    }

    @Test("pyproject PEP 621 and poetry")
    func pyproject() {
        #expect(ManifestParsers.pyproject("[project]\nname = \"api\"") == "api")
        #expect(ManifestParsers.pyproject("[tool.poetry]\nname = \"legacy\"") == "legacy")
        #expect(ManifestParsers.pyproject("[build-system]\nrequires = []") == nil)
    }

    @Test("go.mod module path")
    func goMod() {
        #expect(ManifestParsers.goMod("module github.com/acme/widgets\n\ngo 1.22") == "widgets")
        #expect(ManifestParsers.goMod("module github.com/acme/widgets/v2") == "widgets")
        #expect(ManifestParsers.goMod("module tool") == "tool")
    }

    @Test("Other manifests")
    func others() {
        #expect(ManifestParsers.gemspec("Gem::Specification.new do |s|\n  s.name = 'rack'\nend") == "rack")
        #expect(ManifestParsers.composer(Data(#"{"name": "laravel/laravel"}"#.utf8)) == "laravel")
        #expect(ManifestParsers.mix("def project do\n[app: :phoenix_app, version: \"0.1\"]") == "phoenix_app")
        #expect(ManifestParsers.deno(Data(#"{"name": "@std/fresh"}"#.utf8)) == "fresh")
        #expect(ManifestParsers.pubspec("name: flutter_app # the app\nversion: 1.0.0") == "flutter_app")
        #expect(ManifestParsers.gradle("rootProject.name = 'android-app'") == "android-app")
        #expect(ManifestParsers.gradle("rootProject.name = \"kts-app\"") == "kts-app")
        #expect(
            ManifestParsers.cmake("cmake_minimum_required(VERSION 3.20)\nproject(MyEngine VERSION 1.0)") == "MyEngine")
    }
}
