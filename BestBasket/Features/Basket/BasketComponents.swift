import SwiftUI

struct BasketLineRow:View {
    let product:CatalogProduct; let offer:PriceOffer; let line:BasketLine; @Bindable var model:BasketViewModel; let action:()->Void
    var body:some View { HStack(spacing:11) { Button(action:action) { ProductArt(product:product).frame(width:68,height:68) }.buttonStyle(.plain); VStack(alignment:.leading,spacing:4) { Text(product.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.ink); Text("\(offer.retailer) · \(product.packSize)").font(.caption).foregroundStyle(AppPalette.muted); Text("\(money(offer.price)) each").font(.caption.bold()).foregroundStyle(AppPalette.ink) }; Spacer(minLength:0); HStack(spacing:10) { Button { model.updateQuantity(line,by:-1) } label:{ Image(systemName:"minus.circle").font(.title3) }; Text("\(line.quantity)").font(.subheadline.bold()).monospacedDigit(); Button { model.updateQuantity(line,by:1) } label:{ Image(systemName:"plus.circle.fill").font(.title3) } }.foregroundStyle(AppPalette.cobalt) }.padding(11).background(.white,in:RoundedRectangle(cornerRadius:16)) }
}
struct PriceLine:View { let label:String; let value:String; var emphasized=false; var body:some View { HStack { Text(label); Spacer(); Text(value).fontWeight(emphasized ? .bold : .regular) }.font(emphasized ? .headline : .subheadline).foregroundStyle(AppPalette.ink) } }

