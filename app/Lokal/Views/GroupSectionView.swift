import LokalCore
import SwiftUI

/// A foldable group: its label is a button, its rows follow. Hidden ports appear only when the setting is on.
struct GroupSectionView: View {
    @Environment(AppModel.self) private var model
    let group: ProjectGroup

    private var collapsed: Bool { model.isCollapsed(group.id) }

    var body: some View {
        Section {
            if !collapsed {
                ForEach(group.primaryEntries) { entry in
                    PortRowView(entry: entry)
                }
                if model.preferences.showsAuxiliaryPorts {
                    ForEach(group.auxiliaryEntries) { entry in
                        PortRowView(entry: entry)
                            .opacity(0.72)
                    }
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
}
