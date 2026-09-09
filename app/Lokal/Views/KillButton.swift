import AppKit
import LokalCore
import SwiftUI

/// The kill control. Tapping morphs it in place into a confirm capsule that drains over four seconds.
/// With Reduce Motion on, all movement becomes a crossfade and the drain becomes a stepped bar.
struct KillButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var namespace
    let entry: PortEntry

    private var state: KillState? { model.killStates[entry.id] }

    var body: some View {
        ZStack(alignment: .trailing) {
            switch state {
            case nil:
                idleButton
                    .transition(transition)
            case .confirming:
                confirmCapsule
                    .transition(transition)
            case .killing:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 24, height: 24)
                    .transition(transition)
            case .failed(let message):
                failedLabel(message)
                    .transition(transition)
            }
        }
        .animation(animation, value: state)
    }

    private var animation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.25)
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.85))
    }

    private var idleButton: some View {
        Button {
            let skip = NSEvent.modifierFlags.contains(.option)
            model.requestKill(entry, skipConfirmation: skip)
        } label: {
            Image(systemName: "xmark.circle")
                .font(.system(size: 14))
                .frame(width: 24, height: 24)
                .background {
                    Capsule()
                        .fill(.clear)
                        .matchedGeometryEffect(id: "capsule", in: namespace)
                }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help("Kill process (Option-click to skip confirmation)")
        .accessibilityLabel("Kill \(entry.label)")
    }

    private var confirmCapsule: some View {
        HStack(spacing: 0) {
            Button {
                model.confirmKill(entry)
            } label: {
                Text("Kill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .frame(height: 24)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.defaultAction)
            .accessibilityLabel("Confirm kill \(entry.label) on port \(String(entry.port))")

            Rectangle()
                .fill(.white.opacity(0.35))
                .frame(width: 1, height: 12)

            Button {
                model.cancelConfirmation(entry.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 22, height: 24)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Cancel")
        }
        .foregroundStyle(.white)
        .background {
            Capsule()
                .fill(.red)
                .matchedGeometryEffect(id: "capsule", in: namespace)
        }
        .overlay(alignment: .bottom) {
            if let confirmation = model.confirmations[entry.id] {
                DrainBar(confirmation: confirmation, reduceMotion: reduceMotion)
            }
        }
        .clipShape(Capsule())
        .onHover { model.setConfirmationPaused(entry.id, $0) }
        .accessibilityElement(children: .contain)
    }

    private func failedLabel(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.orange)
            .lineLimit(1)
            .frame(height: 24)
            .accessibilityLabel("Kill failed: \(message)")
    }
}

/// A hairline that empties as the confirmation times out. Freezes while the pointer hovers.
private struct DrainBar: View {
    let confirmation: KillConfirmation
    let reduceMotion: Bool

    var body: some View {
        TimelineView(schedule) { context in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.white.opacity(0.7))
                    .frame(width: geometry.size.width * confirmation.fractionRemaining(at: context.date), height: 2)
            }
        }
        .frame(height: 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var schedule: AnyTimelineSchedule {
        if reduceMotion {
            return AnyTimelineSchedule(.periodic(from: .now, by: 1))
        }
        return AnyTimelineSchedule(.animation(paused: confirmation.deadline == nil))
    }
}

private struct AnyTimelineSchedule: TimelineSchedule {
    private let entriesProvider: (Date, TimelineScheduleMode) -> AnyIterator<Date>

    init<S: TimelineSchedule>(_ schedule: S) {
        entriesProvider = { start, mode in
            var iterator = schedule.entries(from: start, mode: mode).makeIterator()
            return AnyIterator { iterator.next() }
        }
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        entriesProvider(startDate, mode)
    }
}
