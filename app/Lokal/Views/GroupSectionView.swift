import LokalCore
import SwiftUI

/// A muted group label, its primary rows, and a quiet disclosure for the hidden ones.
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
            Text(group.title)
                .font(Theme.label)
                .foregroundStyle(Theme.textAA)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .background(Theme.surfaceRaised.opacity(Theme.panelOpacity))
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
            .font(Theme.small)
            .foregroundStyle(Theme.textAA)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 6)
        .help("Debug inspectors, ephemeral sockets, apps and system services. Not part of a project.")
        .accessibilityLabel(expanded ? "Hide \(count) hidden ports" : "Show \(count) hidden ports")
    }
}
