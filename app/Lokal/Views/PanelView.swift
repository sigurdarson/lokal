import LokalCore
import SwiftUI

/// The popover content: header, grouped list, footer. Flat, borderless, on the raised surface.
struct PanelView: View {
    @Environment(AppModel.self) private var model

    @State private var contentHeight: CGFloat = 0
    private let maximumListHeight: CGFloat = 520

    var body: some View {
        VStack(spacing: 0) {
            header
            list
            footer
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(width: Theme.panelWidth)
        .background(Theme.surfaceRaised.opacity(Theme.panelOpacity))
        .onAppear { model.panelDidAppear() }
        .onDisappear { model.panelDidDisappear() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Lokal")
                .font(Theme.title)
                .foregroundStyle(Theme.textAAA)
            Text(countLabel)
                .font(Theme.body)
                .foregroundStyle(Theme.textAA)
                .contentTransition(.numericText())
            Spacer()
            IconButton(symbol: "arrow.clockwise", title: "Refresh") {
                Task { await model.refresh() }
            }
            .keyboardShortcut("r")
            .symbolEffect(.rotate, isActive: model.isRefreshing)
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var countLabel: String {
        let count = model.listeningCount
        let base = count == 0 ? "nothing listening" : count == 1 ? "1 port" : "\(count) ports"
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
                LazyVStack(spacing: 0) {
                    ForEach(model.snapshot.groups) { group in
                        GroupSectionView(group: group)
                    }
                }
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    contentHeight = $0
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .frame(height: min(contentHeight, maximumListHeight))
            .animation(.default, value: model.snapshot.groups.map(\.id))
        }
    }

    private var footer: some View {
        HStack {
            SettingsLink {
                Text("Settings")
            }
            .buttonStyle(CompactButtonStyle())
            .keyboardShortcut(",")

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(CompactButtonStyle())
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }
}
