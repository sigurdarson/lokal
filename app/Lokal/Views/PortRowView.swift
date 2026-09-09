import LokalCore
import SwiftUI

/// One listening port. Name and chip on the first line, port and process on the second,
/// open and kill controls on the right. Everything else is in the context menu.
struct PortRowView: View {
    @Environment(AppModel.self) private var model
    let entry: PortEntry

    @State private var hovering = false

    private var killState: KillState? { model.killStates[entry.id] }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.label)
                        .font(Theme.bodyMedium)
                        .foregroundStyle(Theme.textAAA)
                        .lineLimit(1)
                    if let project = entry.project, project.name != project.groupName {
                        Text(project.name)
                            .font(Theme.chip)
                            .foregroundStyle(Theme.textAA)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Theme.surfaceSunken, in: Capsule())
                            .lineLimit(1)
                    }
                    if entry.socket.isExposedToNetwork {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.nontextAA)
                            .help("Listening on all interfaces, reachable from the network")
                    }
                }
                HStack(spacing: 0) {
                    Text(verbatim: String(entry.port))
                        .font(Theme.captionMono)
                        .foregroundStyle(Theme.textMutedAAA)
                    Text(verbatim: " · " + entry.detail)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textAA)
                }
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            if killState == nil {
                HStack(spacing: 4) {
                    IconButton(symbol: "arrow.up.right.square", title: "Open in browser") {
                        model.open(entry)
                    }
                    .disabled(!entry.opensInBrowser)
                    KillButton(entry: entry)
                }
            } else {
                KillButton(entry: entry)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(hovering ? Theme.surfaceHoverDecorative : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(Theme.fast, value: hovering)
        .onTapGesture(count: 2) { model.open(entry) }
        .contextMenu { menuItems }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(entry.label), port \(String(entry.port)), \(entry.detail)")
    }

    @ViewBuilder
    private var menuItems: some View {
        Button("Open in browser") { model.open(entry) }
            .disabled(!entry.opensInBrowser)
        Button("Copy URL") { model.copyURL(entry) }
        if model.hasProjectActions(entry) {
            Divider()
            Button("Reveal in Finder") { model.revealInFinder(entry) }
            Button("Open in editor") { model.openInEditor(entry) }
            Button("Open in terminal") { model.openInTerminal(entry) }
        }
        Divider()
        Button("Kill process…") { model.requestKill(entry) }
        Button("Kill immediately") { model.requestKill(entry, skipConfirmation: true) }
    }
}
