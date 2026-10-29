import SwiftUI

struct ProductRail: View {
    let title: String; let subtitle: String; let products: [CatalogProduct]; @Bindable var model: DiscoverViewModel; let openProduct:(CatalogProduct)->Void; var showsReasons = false
    var body: some View { VStack(alignment:.leading,spacing:12) { SectionTitle(title:title,subtitle:subtitle); ScrollView(.horizontal,showsIndicators:false) { HStack(spacing:12) { ForEach(products) { product in ProductCard(product:product,model:model,reason:showsReasons ? model.reason(for:product) : nil) { openProduct(product) }.frame(width:190) } } } } }
}
struct ProductCard: View {
    let product: CatalogProduct; @Bindable var model: DiscoverViewModel; let reason: String?; let action:()->Void
    var body: some View { Button(action:action) { VStack(alignment:.leading,spacing:8) {
        ProductArt(product:product).frame(height:112)
        Text(product.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.ink).lineLimit(2).frame(maxWidth:.infinity,alignment:.leading)
        Text("\(product.brand) · \(product.packSize)").font(.caption).foregroundStyle(AppPalette.muted).lineLimit(1)
        HStack { Text(model.displayedOffer(for:product).map { money($0.price) } ?? "—").font(.headline.weight(.bold)).foregroundStyle(AppPalette.ink); Spacer(); Label(String(format:"%.1f",product.rating),systemImage:"star.fill").font(.caption2.weight(.semibold)).foregroundStyle(AppPalette.ink).labelStyle(.titleAndIcon) }
        Text("from \(model.displayedOffer(for:product)?.retailer ?? "sample store")").font(.caption2.weight(.medium)).foregroundStyle(AppPalette.pine)
        if let reason { Text(reason).font(.caption2.weight(.semibold)).foregroundStyle(AppPalette.cobalt).lineLimit(2) }
    }.padding(11).frame(maxWidth:.infinity,alignment:.leading).background(.white,in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(AppPalette.ink.opacity(0.06),lineWidth:1)) }.buttonStyle(.plain).accessibilityLabel("\(product.name), \(product.packSize), rated \(product.rating, specifier: "%.1f") stars") }
}
