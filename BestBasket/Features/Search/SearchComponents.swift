import SwiftUI

struct SearchResultRow: View {
    let product:CatalogProduct; @Bindable var model:SearchViewModel; let action:()->Void
    var body:some View { Button(action:action) { HStack(spacing:12) { ProductArt(product:product).frame(width:78,height:78); VStack(alignment:.leading,spacing:4) { Text(product.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.ink).lineLimit(2); Text("\(product.brand) · \(product.packSize)").font(.caption).foregroundStyle(AppPalette.muted); if let reason = model.personalizationReason(for: product) { Text(reason).font(.caption2.weight(.medium)).foregroundStyle(AppPalette.cobalt).lineLimit(1) }; HStack(spacing:8) { Label(String(format:"%.1f",product.rating),systemImage:"star.fill").foregroundStyle(AppPalette.ink); Text("·"); Text("\(model.offers(for:product).filter(\.available).count) sample offers").foregroundStyle(AppPalette.pine) }.font(.caption2) }; Spacer(minLength:0); VStack(alignment:.trailing,spacing:3) { Text(model.displayedOffer(for:product).map { money($0.price) } ?? "—").font(.subheadline.weight(.bold)).foregroundStyle(AppPalette.ink); Text("from \(model.displayedOffer(for:product)?.retailer ?? "")").font(.caption2).foregroundStyle(AppPalette.muted) } }.padding(11).background(.white,in:RoundedRectangle(cornerRadius:16)) }.buttonStyle(.plain) }
}
struct FilterPill: View { let title:String; let remove:()->Void; var body:some View { Button(action:remove) { HStack(spacing:5) { Text(title); Image(systemName:"xmark") }.font(.caption.weight(.semibold)).foregroundStyle(.white).padding(.horizontal,10).padding(.vertical,7).background(AppPalette.cobalt,in:Capsule()) } } }
struct FilterSheet: View {
    @Bindable var model:SearchViewModel
    @Environment(\.dismiss) private var dismiss
    var body:some View { NavigationStack { Form {
        Section("Category") { Picker("Any category",selection:$model.selectedCategory) { Text("All categories").tag(String?.none); ForEach(model.categories,id:\.self) { Text($0).tag(Optional($0)) } } }
        Section("Brand") { Picker("Any brand",selection:$model.selectedBrand) { Text("All brands").tag(String?.none); ForEach(model.brands,id:\.self) { Text($0).tag(Optional($0)) } } }
        Section("Shopping platform") { Picker("Any platform",selection:$model.selectedPlatform) { Text("All platforms").tag(String?.none); ForEach(model.platforms,id:\.self) { Text($0).tag(Optional($0)) } } }
        Section("Price and quality") { Toggle("In-stock offers only",isOn:$model.inStockOnly); HStack { Text("Minimum rating"); Spacer(); Picker("Minimum rating",selection:$model.minimumRating) { Text("Any").tag(0.0); Text("4+ stars").tag(4.0); Text("4.5+ stars").tag(4.5) }.labelsHidden() }; HStack { Text("Maximum effective price"); Spacer(); Picker("Max price",selection:Binding(get:{ NSDecimalNumber(decimal:model.maximumPrice ?? 0).doubleValue },set:{ model.maximumPrice=$0 == 0 ? nil : Decimal($0) })) { Text("Any").tag(0.0); Text("₹100").tag(100.0); Text("₹250").tag(250.0); Text("₹500").tag(500.0) }.labelsHidden() } }
        Section { Button("Reset filters",role:.destructive) { model.resetFilters() } }
    }.scrollContentBackground(.hidden).background(AppPalette.oat).navigationTitle("Filters").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } } } }
}
