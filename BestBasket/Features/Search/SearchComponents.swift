import SwiftUI

struct SearchResultRow: View {
    let product: CatalogProduct
    @Bindable var model: SearchViewModel
    let lists: GroceryListsViewModel
    let action: () -> Void
    @State private var expanded = false
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    ProductArt(product: product).frame(width: 68, height: 68)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.ink).lineLimit(2)
                        Text("\(product.brand) · \(product.packSize)").font(.caption).foregroundStyle(AppPalette.muted)
                        if let reason = model.personalizationReason(for: product) { Text(reason).font(.caption2).foregroundStyle(AppPalette.cobalt).lineLimit(1) }
                        Text("★ \(String(format: "%.1f", product.rating)) · \(model.offers(for: product).filter(\.available).count) platform offers").font(.caption2).foregroundStyle(AppPalette.pine)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing) {
                        Text(model.displayedOffer(for: product).map { money($0.effectivePrice) } ?? "—").font(.subheadline.weight(.bold)).foregroundStyle(AppPalette.ink)
                        Text("best offer").font(.caption2).foregroundStyle(AppPalette.muted)
                    }
                }.padding(11).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Button { withAnimation(.snappy) { expanded.toggle() } } label: {
                Label(expanded ? "Hide platform prices" : "Compare platforms", systemImage: "arrow.left.arrow.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(AppPalette.cobalt).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.bottom, 10)
            }.buttonStyle(.plain)
            if expanded {
                ForEach(model.offers(for: product).filter(\.available).sorted { $0.effectivePrice < $1.effectivePrice }) { offer in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) { Text(offer.retailer).font(.caption.weight(.semibold)); Text(offer.delivery).font(.caption2).foregroundStyle(AppPalette.muted) }
                        Spacer()
                        Text(money(offer.effectivePrice)).font(.caption.weight(.bold))
                        Menu {
                            ForEach(lists.lists) { list in Button(list.name) { lists.add(product.id, to: list) } }
                            Button("Create list and add") {
                                _ = lists.create()
                                if let list = lists.lists.first { lists.add(product.id, to: list) }
                            }
                        } label: { Image(systemName: "text.badge.plus").foregroundStyle(AppPalette.cobalt).padding(.leading, 5) }
                        Button { model.addToBasket(offer) } label: { Image(systemName: "basket.badge.plus").foregroundStyle(AppPalette.pine).padding(.leading, 5) }.accessibilityLabel("Add \(product.name) from \(offer.retailer) to Basket")
                    }.padding(.horizontal, 12).padding(.vertical, 9)
                    if offer.id != model.offers(for: product).filter(\.available).sorted(by: { $0.effectivePrice < $1.effectivePrice }).last?.id { Divider().padding(.leading, 12) }
                }
            }
        }.background(.white, in: RoundedRectangle(cornerRadius: 16)).clipShape(RoundedRectangle(cornerRadius: 16))
    }
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
