import LokalCore
import SwiftUI

/// One listening port: icon, label, details, hover actions, port and the kill control.
struct PortRowView: View {
    @Environment(AppModel.self) private var model
    let entry: PortEntry

    @State private var hovering = false

    private var isConfirming: Bool { model.killStates[entry.id] != nil }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.icon)
                .font(.system(size: 15))
                .foregroundStyle(
                    entry.container != nil || entry.confidentService != nil ? Color.accentColor : .secondary
                )
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.label)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    if let project = entry.project, project.name != project.groupName {
                        Text(project.name)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                            .lineLimit(1)
                    }
                    if entry.socket.isExposedToNetwork {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .help("Listening on all interfaces, reachable from the network")
                    }
                }
                Text(entry.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if hovering, !isConfirming {
                actions
                    .transition(.opacity)
            }

            Text(verbatim: ":" + String(entry.port))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)

            KillButton(entry: entry)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .background(hovering ? Color.primary.opacity(0.05) : .clear, in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 4)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
        .onTapGesture(count: 2) { model.open(entry) }
        .contextMenu { menuItems }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(entry.label), port \(String(entry.port)), \(entry.detail)")
    }

    private var actions: some View {
        HStack(spacing: 2) {
            actionButton("safari", "Open in browser") { model.open(entry) }
                .disabled(!entry.opensInBrowser)
            actionButton("doc.on.doc", "Copy URL") { model.copyURL(entry) }
            if model.hasProjectActions(entry) {
                actionButton("folder", "Reveal in Finder") { model.revealInFinder(entry) }
                actionButton("chevron.left.forwardslash.chevron.right", "Open in editor") { model.openInEditor(entry) }
                actionButton("terminal", "Open in Terminal") { model.openInTerminal(entry) }
            }
        }
    }

    private func actionButton(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.borderless)
        .help(title)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var menuItems: some View {
        Button("Open in Browser") { model.open(entry) }
            .disabled(!entry.opensInBrowser)
        Button("Copy URL") { model.copyURL(entry) }
        if model.hasProjectActions(entry) {
            Divider()
            Button("Reveal in Finder") { model.revealInFinder(entry) }
            Button("Open in Editor") { model.openInEditor(entry) }
            Button("Open in Terminal") { model.openInTerminal(entry) }
        }
        Divider()
        Button("Kill Process…") { model.requestKill(entry) }
        Button("Kill Immediately") { model.requestKill(entry, skipConfirmation: true) }
    }
}
