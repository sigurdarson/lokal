import Foundation

/// A section in the panel.
public struct ProjectGroup: Sendable, Hashable, Identifiable {
    public enum Kind: Sendable, Hashable {
        case project
        case containers
        case services
        case other
    }

    public let id: String
    public let title: String
    public let kind: Kind
    public let project: Project?
    public let entries: [PortEntry]

    public init(id: String, title: String, kind: Kind, project: Project? = nil, entries: [PortEntry]) {
        self.id = id
        self.title = title
        self.kind = kind
        self.project = project
        self.entries = entries
    }
}

/// Everything listening at one moment in time.
public struct Snapshot: Sendable, Hashable {
    public let entries: [PortEntry]
    public let groups: [ProjectGroup]
    public let capturedAt: Date

    public init(entries: [PortEntry], capturedAt: Date = Date()) {
        self.entries = entries
        self.groups = SnapshotBuilder.groups(from: entries)
        self.capturedAt = capturedAt
    }

    public static let empty = Snapshot(entries: [], capturedAt: .distantPast)

    public var isEmpty: Bool { entries.isEmpty }
}

enum SnapshotBuilder {
    static func groups(from entries: [PortEntry]) -> [ProjectGroup] {
        var projectGroups: [String: (Project, [PortEntry])] = [:]
        var containers: [PortEntry] = []
        var services: [PortEntry] = []
        var other: [PortEntry] = []

        for entry in entries {
            if let project = entry.project {
                projectGroups[project.groupKey, default: (project, [])].1.append(entry)
            } else if entry.container != nil {
                containers.append(entry)
            } else if entry.confidentService != nil {
                services.append(entry)
            } else {
                other.append(entry)
            }
        }

        var groups: [ProjectGroup] = projectGroups.values
            .map { project, entries in
                ProjectGroup(
                    id: "project:\(project.groupKey)",
                    title: project.groupName,
                    kind: .project,
                    project: project,
                    entries: sorted(entries)
                )
            }
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                    || (lhs.title == rhs.title && lhs.id < rhs.id)
            }

        if !containers.isEmpty {
            groups.append(
                ProjectGroup(id: "containers", title: "Containers", kind: .containers, entries: sorted(containers)))
        }
        if !services.isEmpty {
            groups.append(ProjectGroup(id: "services", title: "Services", kind: .services, entries: sorted(services)))
        }
        if !other.isEmpty {
            groups.append(ProjectGroup(id: "other", title: "Other", kind: .other, entries: sorted(other)))
        }
        return groups
    }

    private static func sorted(_ entries: [PortEntry]) -> [PortEntry] {
        entries.sorted { lhs, rhs in
            lhs.port != rhs.port ? lhs.port < rhs.port : lhs.pid < rhs.pid
        }
    }
}
