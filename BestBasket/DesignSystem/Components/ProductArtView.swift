import SwiftUI

struct ProductArt: View {
    let product: CatalogProduct
    var body: some View { ZStack { RoundedRectangle(cornerRadius:15).fill(AppPalette.oat); Image(systemName:product.systemImage).resizable().scaledToFit().foregroundStyle(AppPalette.cobalt).padding(28); Text("SAMPLE").font(.system(size:8,weight:.bold)).tracking(1).foregroundStyle(AppPalette.muted).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.bottomTrailing).padding(8) }.accessibilityHidden(true) }
}
