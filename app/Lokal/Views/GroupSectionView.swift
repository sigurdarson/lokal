import LokalCore
import SwiftUI

/// A foldable group: its label is a button, its primary rows follow, then a quiet disclosure for hidden ports.
struct GroupSectionView: View {
    @Environment(AppModel.self) private var model
    let group: ProjectGroup

    private var collapsed: Bool { model.isCollapsed(group.id) }

    private var showsAll: Bool {
        model.preferences.showsAuxiliaryPorts || model.isExpanded(group.id)
    }

    var body: some View {
        Section {
            if !collapsed {
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
            }
        } header: {
            header
        }
    }

    private var header: some View {
        Button {
            model.toggleCollapsed(group.id)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(collapsed ? -90 : 0))
                Text(group.title)
                    .lineLimit(1)
                Spacer()
                if collapsed {
                    Text(verbatim: String(visibleCount))
                        .contentTransition(.numericText())
                }
            }
            .font(Theme.label)
            .foregroundStyle(Theme.textAA)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverWash()
        .animation(Theme.fast, value: collapsed)
        .help(collapsed ? "Show this group" : "Hide this group")
        .accessibilityLabel(collapsed ? "Show \(group.title)" : "Hide \(group.title)")
        .accessibilityAddTraits(.isHeader)
    }

    private var visibleCount: Int {
        model.preferences.showsAuxiliaryPorts ? group.entries.count : group.primaryEntries.count
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
            .font(Theme.small)
            .foregroundStyle(Theme.textAA)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverWash()
        .help("Debug inspectors, ephemeral sockets, apps and system services. Not part of a project.")
        .accessibilityLabel(expanded ? "Hide \(count) hidden ports" : "Show \(count) hidden ports")
    }
}
