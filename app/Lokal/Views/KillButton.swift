import AppKit
import LokalCore
import SwiftUI

/// The kill control. Idle it is an × that winds up on hover; tapped, its background morphs in place
/// into a capsule on the inverse surface with Kill and cancel. Return confirms, Escape cancels,
/// Option-click skips. Reduce Motion replaces the spring with a crossfade.
struct KillButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var namespace
    let entry: PortEntry

    @State private var hovering = false

    private var state: KillState? { model.killStates[entry.id] }

    var body: some View {
        ZStack(alignment: .trailing) {
            switch state {
            case nil:
                idleButton
            case .confirming:
                confirmCapsule
            case .killing:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: Theme.iconButtonSize, height: Theme.iconButtonSize)
            case .failed(let message):
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(message)
                }
                .font(Theme.small)
                .foregroundStyle(Theme.textAA)
                .lineLimit(1)
                .frame(height: Theme.iconButtonSize)
                .accessibilityLabel("Kill failed: \(message)")
            }
        }
        .animation(reduceMotion ? Theme.fast : Theme.springPop, value: state)
    }

    /// The capsule is the one element shared between states; matchedGeometryEffect morphs it.
    private func capsule(_ fill: Color) -> some View {
        Capsule()
            .fill(fill)
            .matchedGeometryEffect(id: "capsule", in: namespace)
    }

    private var idleButton: some View {
        Button {
            model.requestKill(entry, skipConfirmation: NSEvent.modifierFlags.contains(.option))
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(hovering ? Theme.textAAA : Theme.nontextAA)
                .scaleEffect(hovering && !reduceMotion ? 1.2 : 1)
                .rotationEffect(hovering && !reduceMotion ? .degrees(90) : .zero)
                .frame(width: Theme.iconButtonSize, height: Theme.iconButtonSize)
                .background(capsule(hovering ? Theme.surfaceHoverDecorative : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? Theme.fast : Theme.springPop, value: hovering)
        .help("Kill process (Option-click to skip confirmation)")
        .accessibilityLabel("Kill \(entry.label)")
        .transition(.identity)
    }

    private var confirmCapsule: some View {
        HStack(spacing: 0) {
            Button {
                model.confirmKill(entry)
            } label: {
                Text("Kill")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .frame(height: Theme.iconButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .accessibilityLabel("Confirm kill \(entry.label) on port \(String(entry.port))")

            Button {
                model.cancelConfirmation(entry.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 22, height: Theme.iconButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(0.7)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Cancel")
        }
        .foregroundStyle(Theme.textOnInverseAAA)
        .background(capsule(Theme.surfaceInverse))
        .onHover { model.setConfirmationPaused(entry.id, $0) }
        .accessibilityElement(children: .contain)
        .transition(.opacity)
    }
}
