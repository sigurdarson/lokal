import SwiftUI

/// The site's hover wash: a translucent gray over any surface while the pointer is inside.
struct HoverWash: ViewModifier {
    var cornerRadius: CGFloat = 0
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(
                hovering ? Theme.surfaceHoverDecorative : Color.clear,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .animation(Theme.fast, value: hovering)
    }
}

extension View {
    func hoverWash(cornerRadius: CGFloat = 0) -> some View {
        modifier(HoverWash(cornerRadius: cornerRadius))
    }
}
