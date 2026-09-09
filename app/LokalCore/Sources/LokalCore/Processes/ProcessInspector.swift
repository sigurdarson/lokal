import Darwin

/// Something that can describe a process by pid. Abstracted for testing the scanner.
public protocol ProcessInspecting: Sendable {
    func details(for pid: pid_t) -> ProcessDetails?
}

/// Gathers process details from libproc and sysctl. No shelling out.
public struct LibprocProcessInspector: ProcessInspecting {
    public init() {}

    public func details(for pid: pid_t) -> ProcessDetails? {
        guard let name = Libproc.name(of: pid) else { return nil }
        let info = Libproc.bsdInfo(of: pid)
        let parsed = Libproc.rawArguments(of: pid).flatMap(ProcessArgumentsParser.parse)
        return ProcessDetails(
            pid: pid,
            name: name,
            executablePath: Libproc.executablePath(of: pid) ?? parsed?.executablePath,
            workingDirectory: Libproc.workingDirectory(of: pid),
            parentPID: info.map { pid_t($0.pbi_ppid) },
            arguments: parsed?.arguments ?? [],
            startTime: info?.pbi_start_tvsec ?? 0,
            userID: info.map(\.pbi_uid)
        )
    }
}
