import LokalCore
import SwiftUI

/// A section header, its primary rows, and a disclosure for the auxiliary ones.
struct GroupSectionView: View {
    @Environment(AppModel.self) private var model
    let group: ProjectGroup

    private var showsAll: Bool {
        model.preferences.showsAuxiliaryPorts || model.isExpanded(group.id)
    }

    var body: some View {
        Section {
            ForEach(group.primaryEntries) { entry in
                PortRowView(entry: entry)
            }
            if showsAll {
                ForEach(group.auxiliaryEntries) { entry in
                    PortRowView(entry: entry)
                        .opacity(0.72)
                }
            }
            if !group.auxiliaryEntries.isEmpty, !model.preferences.showsAuxiliaryPorts {
                disclosure
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(group.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(.bar)
        }
    }

    private var disclosure: some View {
        let count = group.auxiliaryEntries.count
        let expanded = model.isExpanded(group.id)
        let noun = count == 1 ? "hidden port" : "hidden ports"
        return Button {
            model.toggleExpanded(group.id)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                Text(verbatim: expanded ? "Hide \(count) \(noun)" : "\(count) \(noun)")
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 48)
        .padding(.trailing, 16)
        .padding(.vertical, 5)
        .help("Debug inspectors, ephemeral sockets, apps and system services. Not part of a project.")
        .accessibilityLabel(expanded ? "Hide \(count) hidden ports" : "Show \(count) hidden ports")
    }

    private var icon: String {
        switch group.kind {
        case .project: "folder"
        case .containers: "shippingbox"
        case .services: "server.rack"
        case .other: "ellipsis.circle"
        }
    }
}
