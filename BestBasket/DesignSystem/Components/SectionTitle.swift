import SwiftUI

struct SectionTitle: View {
    let title: String; var subtitle: String? = nil
    var body: some View { VStack(alignment:.leading,spacing:3) { Text(title).font(.headline.weight(.bold)).foregroundStyle(AppPalette.ink); if let subtitle { Text(subtitle).font(.caption).foregroundStyle(AppPalette.muted) } } }
}
