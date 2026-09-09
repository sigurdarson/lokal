import SwiftUI

/// Fires `onPress` the moment the pointer goes down, instead of waiting for release.
/// Use for controls whose response should feel instant, such as opening the kill capsule.
struct PressButtonStyle: ButtonStyle {
    let onPress: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { onPress() }
            }
    }
}
