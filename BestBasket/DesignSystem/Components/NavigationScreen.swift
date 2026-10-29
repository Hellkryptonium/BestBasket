import SwiftUI

struct Screen: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .background(AppPalette.oat.ignoresSafeArea())
            .toolbarBackground(AppPalette.oat, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
    }
}

extension View {
    func appScreen(_ title: String) -> some View { modifier(Screen(title: title)) }
}
