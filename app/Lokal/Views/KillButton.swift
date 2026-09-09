import AppKit
import LokalCore
import SwiftUI

/// The kill control. Idle it is an × that winds up on hover; tapped, it pops into a capsule on the
/// inverse surface with Kill and cancel. Return confirms, Escape cancels, Option-click skips.
/// Reduce Motion replaces the spring and pop with crossfades.
struct KillButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let entry: PortEntry

    private var state: KillState? { model.killStates[entry.id] }

    var body: some View {
        ZStack(alignment: .trailing) {
            switch state {
            case nil:
                IconButton(symbol: "xmark", title: "Kill process (Option-click to skip confirmation)", windsUp: true) {
                    model.requestKill(entry, skipConfirmation: NSEvent.modifierFlags.contains(.option))
                }
                .accessibilityLabel("Kill \(entry.label)")
                .transition(.opacity)
            case .confirming:
                confirmCapsule
                    .transition(popTransition)
            case .killing:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: Theme.iconButtonSize, height: Theme.iconButtonSize)
                    .transition(.opacity)
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
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? Theme.fast : Theme.springPop, value: state)
    }

    private var popTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.6, anchor: .trailing).combined(with: .opacity)
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
        .background(Theme.surfaceInverse, in: Capsule())
        .onHover { model.setConfirmationPaused(entry.id, $0) }
        .accessibilityElement(children: .contain)
    }
}
