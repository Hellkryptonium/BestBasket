import SwiftUI

struct TrackingView:View {
    @Bindable var model:TrackingViewModel; let openProduct:(CatalogProduct)->Void
    var body:some View { NavigationStack { ScrollView { VStack(alignment:.leading,spacing:14) { Text("Your sample price alerts").font(.subheadline).foregroundStyle(AppPalette.muted)
        if model.items.isEmpty { ContentUnavailableView("Nothing tracked yet",systemImage:"chart.line.uptrend.xyaxis",description:Text("Open a product and set a target price to add an alert.")) }
        ForEach(model.items) { tracked in if let product=model.product(for:tracked), let current=model.currentOffer(for:tracked) { TrackingCard(product:product,current:current,item:tracked,model:model) { openProduct(product) } } }
        Text("Price history and target checks are illustrative sample data, not live notifications.").font(.caption2).foregroundStyle(AppPalette.muted).padding(.top,5)
    }.padding(18) }.background(AppPalette.oat).appScreen("Tracking") } }
}
struct TrackingCard:View {
    let product:CatalogProduct; let current:PriceOffer; let item:TrackedItem; @Bindable var model:TrackingViewModel; let action:()->Void
    var body:some View { VStack(alignment:.leading,spacing:12) { HStack(spacing:12) { Button(action:action) { HStack(spacing:12) { ProductArt(product:product).frame(width:62,height:62); VStack(alignment:.leading,spacing:3) { Text(product.name).font(.subheadline.bold()).foregroundStyle(AppPalette.ink); Text("\(current.retailer) · sample offer").font(.caption).foregroundStyle(AppPalette.muted) } }.frame(maxWidth:.infinity,alignment:.leading) }.buttonStyle(.plain); Button { model.untrack(item) } label:{ Image(systemName:"trash").foregroundStyle(AppPalette.muted) }.accessibilityLabel("Remove \(product.name) price alert") }
        HStack { VStack(alignment:.leading,spacing:3) { Text("NOW").font(.caption2.weight(.bold)).foregroundStyle(AppPalette.muted); Text(money(current.price)).font(.headline.bold()) }; Spacer(); Image(systemName:"arrow.right").foregroundStyle(AppPalette.muted); Spacer(); VStack(alignment:.trailing,spacing:3) { Text("YOUR TARGET").font(.caption2.weight(.bold)).foregroundStyle(AppPalette.muted); Text(money(item.targetPrice)).font(.headline.bold()).foregroundStyle(model.targetReached(for:item,at:current) ? AppPalette.pine : AppPalette.cobalt) } }
        HStack(spacing:4) { ForEach(0..<18,id:\.self) { index in Capsule().fill(index > 12 ? AppPalette.cobalt : AppPalette.pine.opacity(0.42)).frame(width:10,height:CGFloat(14 + (index * 17 % 30))) } }.frame(maxWidth:.infinity,alignment:.center).frame(height:44).background(AppPalette.oat,in:RoundedRectangle(cornerRadius:10)).accessibilityLabel("Illustrative sample price history")
        Text(model.targetReached(for:item,at:current) ? "Target reached in this sample." : "Target not reached in this sample.").font(.caption.weight(.semibold)).foregroundStyle(model.targetReached(for:item,at:current) ? AppPalette.pine : AppPalette.muted)
    }.padding(14).background(.white,in:RoundedRectangle(cornerRadius:17)) }
}

