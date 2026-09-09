import SwiftUI

/// The status item: icon, plus a count when the badge is enabled.
struct MenuBarLabel: View {
    let count: Int
    let showsBadge: Bool

    var body: some View {
        if showsBadge, count > 0 {
            HStack(spacing: 3) {
                Image(systemName: "network.slash")
                Text(verbatim: String(count))
                    .monospacedDigit()
            }
        } else {
            Image(systemName: "network.slash")
        }
    }
}
