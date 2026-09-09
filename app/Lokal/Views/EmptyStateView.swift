import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Nothing listening")
                .font(Theme.bodyMedium)
                .foregroundStyle(Theme.textAAA)
            Text("Start a dev server or a database and it will show up here.")
                .font(Theme.small)
                .foregroundStyle(Theme.textAA)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
    }
}
