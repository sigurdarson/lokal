import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Nothing listening", systemImage: "network.slash")
        } description: {
            Text("Start a dev server or a database and it will show up here.")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
