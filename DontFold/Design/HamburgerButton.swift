import SwiftUI

/// Three thin ink horizontal lines, 30×30 tap target. Tap → opens the drawer.
/// Lives top-left on most screens (Home, PersonaPicker, ScenarioDetail, Result).
struct HamburgerButton: View {
    @Environment(MenuState.self) private var menu

    var body: some View {
        Button {
            menu.open()
        } label: {
            VStack(spacing: 4) {
                line
                line
                line
            }
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var line: some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .fill(Theme.ink)
            .frame(width: 18, height: 2)
    }
}
