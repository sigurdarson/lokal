import SwiftUI

/// The site's compact button: 28 pt tall, 8 pt radius, secondary on the sunken surface or primary on the inverse one.
struct CompactButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
    }

    var variant: Variant = .secondary

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration, variant: variant)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        let variant: Variant
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(Theme.label)
                .foregroundStyle(variant == .primary ? Theme.textOnInverseAAA : Theme.textAAA)
                .padding(.horizontal, Theme.buttonPaddingXCompact)
                .frame(height: Theme.buttonHeightCompact)
                .background(
                    variant == .primary ? Theme.surfaceInverse : Theme.surfaceSunken,
                    in: RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                )
                .opacity(configuration.isPressed ? 0.76 : hovering ? 0.88 : 1)
                .onHover { hovering = $0 }
                .animation(Theme.fast, value: hovering)
        }
    }
}
