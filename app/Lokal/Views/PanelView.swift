import LokalCore
import SwiftUI

/// The popover content: header, grouped list, footer.
struct PanelView: View {
    @Environment(AppModel.self) private var model
    let updaterModel: UpdaterViewModel

    @State private var contentHeight: CGFloat = 0
    private let maximumListHeight: CGFloat = 480

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            list
            Divider()
            footer
        }
        .frame(width: 360)
        .onAppear { model.panelDidAppear() }
        .onDisappear { model.panelDidDisappear() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Lokal")
                .font(.headline)
            Text(countLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
            Spacer()
            Button {
                Task { await model.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .symbolEffect(.rotate, isActive: model.isRefreshing)
            }
            .buttonStyle(.borderless)
            .help("Refresh")
            .keyboardShortcut("r")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var countLabel: String {
        let base =
            switch model.listeningCount {
            case 0: "nothing listening"
            case 1: "1 port"
            case let count: "\(count) ports"
            }
        return model.hiddenCount > 0 ? "\(base) · \(model.hiddenCount) hidden" : base
    }

    @ViewBuilder
    private var list: some View {
        if !model.hasScannedOnce {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if model.snapshot.isEmpty {
            EmptyStateView()
        } else {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(model.snapshot.groups) { group in
                        GroupSectionView(group: group)
                    }
                }
                .padding(.vertical, 4)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    contentHeight = $0
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: min(contentHeight, maximumListHeight))
            .animation(.default, value: model.snapshot.groups.map(\.id))
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .keyboardShortcut(",")

            Button {
                updaterModel.checkForUpdates()
            } label: {
                Label("Check for Updates", systemImage: "arrow.down.circle")
            }
            .disabled(!updaterModel.canCheckForUpdates)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .buttonStyle(.borderless)
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
