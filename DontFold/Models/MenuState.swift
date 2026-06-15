import SwiftUI

/// Drives the left-side drawer's open/closed state. Lives in the environment;
/// any screen with a hamburger button calls `open()` and the overlay in
/// `RootView` slides in.
@Observable
@MainActor
final class MenuState {
    var isOpen: Bool = false

    func open() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isOpen = true
        }
    }

    func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isOpen = false
        }
    }

    func toggle() {
        if isOpen { close() } else { open() }
    }
}
