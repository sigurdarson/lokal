import SwiftUI

/// The status item: icon, plus a count when the badge is enabled.
struct MenuBarLabel: View {
    let count: Int
    let showsBadge: Bool

    var body: some View {
        if showsBadge, count > 0 {
            HStack(spacing: 3) {
                icon
                Text(verbatim: String(count))
                    .monospacedDigit()
            }
        } else {
            icon
        }
    }

    /// The Lokal mark as a template image, so the menu bar tints it for light and dark.
    private var icon: some View {
        Image("MenuBarIcon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
    }
}
