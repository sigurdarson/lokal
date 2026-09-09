import Darwin
import Foundation
import Testing

@testable import LokalCore

@Suite("ProcessArgumentsParser")
struct ProcessArgumentsParserTests {
    private func buffer(executable: String, arguments: [String], environment: [String] = ["HOME=/x"]) -> [UInt8] {
        var bytes: [UInt8] = []
        let argc = UInt32(arguments.count)
        bytes += [UInt8(argc & 0xff), UInt8((argc >> 8) & 0xff), UInt8((argc >> 16) & 0xff), UInt8(argc >> 24)]
        bytes += Array(executable.utf8) + [0, 0, 0, 0]  // path plus alignment padding
        for argument in arguments { bytes += Array(argument.utf8) + [0] }
        for variable in environment { bytes += Array(variable.utf8) + [0] }
        return bytes
    }

    @Test("Parses executable path and argv, ignoring environment")
    func parses() {
        let raw = buffer(executable: "/usr/local/bin/node", arguments: ["node", "/app/node_modules/.bin/next", "dev"])
        let result = ProcessArgumentsParser.parse(raw)
        #expect(result?.executablePath == "/usr/local/bin/node")
        #expect(result?.arguments == ["node", "/app/node_modules/.bin/next", "dev"])
    }

    @Test("Empty argv")
    func empty() {
        let result = ProcessArgumentsParser.parse(buffer(executable: "/bin/x", arguments: []))
        #expect(result?.arguments == [])
        #expect(ProcessArgumentsParser.parse([1, 0]) == nil)
    }
}

@Suite("LibprocProcessInspector")
struct LibprocProcessInspectorTests {
    @Test("Describes the current process")
    func describesSelf() throws {
        let details = try #require(LibprocProcessInspector().details(for: getpid()))
        #expect(details.pid == getpid())
        #expect(!details.name.isEmpty)
        #expect(details.executablePath?.hasPrefix("/") == true)
        #expect(details.workingDirectory?.hasPrefix("/") == true)
        #expect(details.parentPID == getppid())
        #expect(!details.arguments.isEmpty)
        #expect(details.startTime > 0)
        #expect(details.userID == getuid())
    }

    @Test("Unknown pid yields nil")
    func unknown() {
        #expect(LibprocProcessInspector().details(for: 99_999_999) == nil)
    }
}

@Suite("CommandLabeler")
struct CommandLabelerTests {
    private func process(_ name: String, _ arguments: [String]) -> ProcessDetails {
        ProcessDetails(pid: 1, name: name, executablePath: "/usr/bin/\(name)", arguments: arguments)
    }

    @Test("node running a bin script")
    func nodeBin() {
        #expect(CommandLabeler.label(for: process("node", ["node", "/p/node_modules/.bin/next", "dev"])) == "next dev")
        #expect(CommandLabeler.label(for: process("node", ["node", "server.js"])) == "server")
        #expect(
            CommandLabeler.label(for: process("node", ["node", "--inspect", "dist/index.mjs", "--port", "3000"]))
                == "index")
    }

    @Test("python module and script")
    func python() {
        #expect(
            CommandLabeler.label(for: process("python3", ["python3", "-m", "http.server", "8000"]))
                == "http.server 8000")
        #expect(
            CommandLabeler.label(for: process("python", ["python", "manage.py", "runserver"])) == "manage runserver")
    }

    @Test("descriptive executables get no label")
    func descriptive() {
        #expect(CommandLabeler.label(for: process("postgres", ["postgres", "-D", "/data"])) == nil)
        #expect(CommandLabeler.label(for: process("node", ["node"])) == nil)
    }
}

@Suite("ProcessTerminator")
struct ProcessTerminatorTests {
    @Test("Signalling an invalid pid fails cleanly")
    func invalidPID() {
        #expect(throws: ProcessTerminator.Failure.noSuchProcess) { try ProcessTerminator().terminate(0) }
        #expect(throws: ProcessTerminator.Failure.noSuchProcess) { try ProcessTerminator().terminate(99_999_999) }
    }

    @Test("Running check")
    func running() {
        #expect(ProcessTerminator.isRunning(getpid()))
        #expect(!ProcessTerminator.isRunning(99_999_999))
    }
}
