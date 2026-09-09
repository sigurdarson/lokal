import SwiftUI

/// A 24 pt icon button in the non-text gray that darkens and gets the hover wash on hover.
/// Optionally winds up (scale and quarter turn) on hover, like the site's kill control.
struct IconButton: View {
    let symbol: String
    let title: String
    var windsUp = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(hovering ? Theme.textAAA : Theme.nontextAA)
                .scaleEffect(hovering && !reduceMotion ? (windsUp ? 1.2 : 1.15) : 1)
                .rotationEffect(windsUp && hovering && !reduceMotion ? .degrees(90) : .zero)
                .frame(width: Theme.iconButtonSize, height: Theme.iconButtonSize)
                .background(
                    hovering ? Theme.surfaceHoverDecorative : Color.clear,
                    in: RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? Theme.fast : Theme.springPop, value: hovering)
        .help(title)
        .accessibilityLabel(title)
    }
}
