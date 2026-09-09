import LokalCore
import SwiftUI

/// A section header plus its rows.
struct GroupSectionView: View {
    let group: ProjectGroup

    var body: some View {
        Section {
            ForEach(group.entries) { entry in
                PortRowView(entry: entry)
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(group.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(.bar)
        }
    }

    private var icon: String {
        switch group.kind {
        case .project: "folder"
        case .containers: "shippingbox"
        case .services: "server.rack"
        case .other: "ellipsis.circle"
        }
    }
}
