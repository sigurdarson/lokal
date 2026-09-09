import AppKit
import SwiftUI

/// The app's design tokens, mirroring web/src/styles/tokens.css.
///
/// Colours are the same eleven achromatic OKLCH grays. For an achromatic OKLab colour the relative
/// luminance is exactly L³, so the sRGB value is derived from that and the contrast tiers measured for
/// the website (see web/DESIGN.md) hold here too. Names carry the WCAG tier they guarantee:
/// `textAAA` ≥ 7:1, `textAA` ≥ 4.5:1, `nontextAA` ≥ 3:1, `decorative` no requirement.
enum Theme {
    // MARK: Primitives

    static let gray50 = gray(0.985)
    static let gray100 = gray(0.97)
    static let gray200 = gray(0.922)
    static let gray300 = gray(0.87)
    static let gray400 = gray(0.708)
    static let gray500 = gray(0.556)
    static let gray600 = gray(0.439)
    static let gray700 = gray(0.371)
    static let gray800 = gray(0.269)
    static let gray900 = gray(0.205)
    static let gray950 = gray(0.145)

    // MARK: Surfaces

    static let surfacePage = dynamic(light: gray50, dark: gray950)
    static let surfaceRaised = dynamic(light: gray100, dark: gray900)
    static let surfaceSunken = dynamic(light: gray200, dark: gray800)
    static let surfaceInverse = dynamic(light: gray900, dark: gray50)
    /// Hover wash over any surface: gray-950 at 6% in light, gray-50 at 16% in dark.
    static let surfaceHoverDecorative = dynamic(
        light: gray950.withAlphaComponent(0.06),
        dark: gray50.withAlphaComponent(0.16)
    )

    // MARK: Text

    static let textAAA = dynamic(light: gray900, dark: gray50)
    static let textMutedAAA = dynamic(light: gray700, dark: gray300)
    static let textAA = dynamic(light: gray600, dark: gray400)
    static let textOnInverseAAA = dynamic(light: gray50, dark: gray900)

    // MARK: Non-text

    static let nontextAA = Color(nsColor: gray500)
    static let borderDecorative = dynamic(light: gray200, dark: gray800)

    // MARK: Metrics (points; the web values in rem × 16)

    static let panelWidth: CGFloat = 360
    static let buttonHeight: CGFloat = 36
    static let buttonHeightCompact: CGFloat = 28
    static let buttonPaddingX: CGFloat = 12
    static let buttonPaddingXCompact: CGFloat = 10
    static let buttonRadius: CGFloat = 8
    static let iconButtonSize: CGFloat = 24
    static let radiusSmall: CGFloat = 6
    static let radiusLarge: CGFloat = 14
    static let panelOpacity: Double = 0.92

    // MARK: Type

    static let title = Font.system(size: 13, weight: .semibold)
    static let body = Font.system(size: 13)
    static let bodyMedium = Font.system(size: 13, weight: .medium)
    static let caption = Font.system(size: 11.5)
    static let captionMono = Font.system(size: 11.5, design: .monospaced)
    static let label = Font.system(size: 12, weight: .semibold)
    static let small = Font.system(size: 12)
    static let chip = Font.system(size: 10, weight: .medium)

    // MARK: Motion

    static let springPop = Animation.spring(duration: 0.26, bounce: 0.35)
    static let fast = Animation.easeOut(duration: 0.12)

    // MARK: Helpers

    /// sRGB gray for an OKLCH lightness with zero chroma.
    static func gray(_ lightness: Double) -> NSColor {
        let linear = pow(lightness, 3)
        let channel = linear <= 0.0031308 ? 12.92 * linear : 1.055 * pow(linear, 1 / 2.4) - 0.055
        return NSColor(srgbRed: channel, green: channel, blue: channel, alpha: 1)
    }

    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            })
    }
}
