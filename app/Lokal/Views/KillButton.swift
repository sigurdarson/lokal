import AppKit
import LokalCore
import SwiftUI

/// The kill control, one persistent view. Idle it is an × on a 6 pt rounded square that winds up on hover.
/// Tapped, a Kill label grows in beside the ×, the background stretches into a capsule on the inverse
/// surface, and the × becomes cancel. Return confirms, Escape cancels, Option-click skips.
struct KillButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let entry: PortEntry

    @State private var hovering = false

    private var state: KillState? { model.killStates[entry.id] }
    private var confirming: Bool { state == .confirming }

    var body: some View {
        switch state {
        case nil, .confirming:
            control
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

    private var control: some View {
        HStack(spacing: 0) {
            if confirming {
                Button {
                    model.confirmKill(entry)
                } label: {
                    Text("Kill")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.leading, 10)
                        .padding(.trailing, 4)
                        .frame(height: Theme.iconButtonSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel("Confirm kill \(entry.label) on port \(String(entry.port))")
                .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }

            Button {
                if confirming { model.cancelConfirmation(entry.id) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: confirming ? 9 : 12, weight: confirming ? .bold : .medium))
                    .scaleEffect(hovering && !confirming && !reduceMotion ? 1.2 : 1)
                    .rotationEffect(hovering && !confirming && !reduceMotion ? .degrees(90) : .zero)
                    .opacity(confirming ? 0.7 : 1)
                    .frame(width: confirming ? 22 : Theme.iconButtonSize, height: Theme.iconButtonSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(
                PressButtonStyle {
                    // Opening the capsule happens on press so the morph starts with no perceptible delay.
                    guard !confirming else { return }
                    model.requestKill(entry, skipConfirmation: NSEvent.modifierFlags.contains(.option))
                }
            )
            .keyboardShortcut(confirming ? .cancelAction : nil)
            .help(confirming ? "Cancel" : "Kill process (Option-click to skip confirmation)")
            .accessibilityLabel(confirming ? "Cancel" : "Kill \(entry.label)")
        }
        .foregroundStyle(confirming ? Theme.textOnInverseAAA : hovering ? Theme.textAAA : Theme.nontextAA)
        .background(
            RoundedRectangle(
                cornerRadius: confirming ? Theme.iconButtonSize / 2 : Theme.radiusSmall, style: .continuous
            )
            .fill(confirming ? Theme.surfaceInverse : hovering ? Theme.surfaceHoverDecorative : Color.clear)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: confirming ? Theme.iconButtonSize / 2 : Theme.radiusSmall, style: .continuous)
        )
        .onHover { isHovering in
            hovering = isHovering
            if confirming { model.setConfirmationPaused(entry.id, isHovering) }
        }
        .animation(reduceMotion ? Theme.fast : Theme.springPop, value: confirming)
        .animation(reduceMotion ? Theme.fast : Theme.springPop, value: hovering)
        .accessibilityElement(children: .contain)
    }
}
