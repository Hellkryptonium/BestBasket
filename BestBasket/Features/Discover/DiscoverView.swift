import SwiftUI

struct DiscoverView: View {
    @Bindable var model: DiscoverViewModel
    let openProduct: (CatalogProduct) -> Void
    let goToSearch: () -> Void
    let goToBasket: () -> Void
    let openCategory: (String) -> Void
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased()).font(.caption.weight(.bold)).tracking(1.1).foregroundStyle(AppPalette.muted)
                            Text("Good morning, Sam").font(.title2.weight(.bold)).foregroundStyle(AppPalette.ink)
                            Text("A little better value, every shop.").font(.subheadline).foregroundStyle(AppPalette.muted)
                        }
                        Spacer()
                        Button(action: goToBasket) { Image(systemName: "basket.fill").font(.title3).foregroundStyle(AppPalette.ink).frame(width: 48,height: 48).background(.white,in:RoundedRectangle(cornerRadius: 16)) }
                            .overlay(alignment: .topTrailing) { if model.basketQuantity > 0 { Text("\(model.basketQuantity)").font(.caption2.bold()).foregroundStyle(.white).padding(5).background(AppPalette.cobalt,in:Circle()).offset(x:5,y:-5) } }
                            .accessibilityLabel("Basket, \(model.basketProductCount) products")
                    }
                    Button(action: goToSearch) {
                        HStack(spacing: 11) { Image(systemName: "magnifyingglass"); Text("Search products, brands, and more"); Spacer(); Image(systemName: "slider.horizontal.3") }
                            .font(.subheadline).foregroundStyle(AppPalette.muted).padding(16).background(.white,in:RoundedRectangle(cornerRadius: 17))
                    }.buttonStyle(.plain)
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("YOUR SHOP,\nA LITTLE SMARTER").font(.caption.weight(.heavy)).tracking(1).foregroundStyle(AppPalette.ink)
                            Text("Compare your everyday picks.").font(.title3.weight(.bold)).foregroundStyle(AppPalette.ink)
                            Button(action: goToSearch) { HStack { Text("Find a better price"); Image(systemName: "arrow.right") }.font(.caption.weight(.bold)).foregroundStyle(.white).padding(.horizontal,13).padding(.vertical,10).background(AppPalette.cobalt,in:RoundedRectangle(cornerRadius: 12)) }
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "basket.fill").font(.system(size: 42)).foregroundStyle(AppPalette.cobalt).rotationEffect(.degrees(-10))
                    }.padding(18).background(AppPalette.blush,in:RoundedRectangle(cornerRadius: 24))
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title:"Shop by aisle", subtitle:"Everyday essentials")
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(model.categories.prefix(6)), id:\.self) { category in
                                Button { openCategory(category) } label: {
                                    HStack(spacing: 10) { Image(systemName: categoryIcon(category)).font(.title3).foregroundStyle(AppPalette.cobalt).frame(width:36,height:36).background(AppPalette.cobalt.opacity(0.09),in:RoundedRectangle(cornerRadius:11)); Text(category).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.ink); Spacer(minLength:0) }
                                        .padding(10).background(.white,in:RoundedRectangle(cornerRadius:15))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    ProductRail(title:"Picked for your shop",
                                subtitle:model.personalizationEnabled ? "Based on your saved preferences" : "Popular sample products",
                                products:model.recommendations, model:model, openProduct:openProduct, showsReasons:true)
                    ProductRail(title:"Worth a closer look", subtitle:"Good ratings across sample listings", products:model.popularProducts, model:model, openProduct:openProduct)
                    HStack(alignment:.top,spacing:12) { Image(systemName:"chart.line.downtrend.xyaxis").font(.title2).foregroundStyle(AppPalette.pine); VStack(alignment:.leading,spacing:3) { Text("Keep an eye on prices").font(.headline); Text("Set a target and see when a sample offer reaches it.").font(.caption).foregroundStyle(AppPalette.muted) }; Spacer(); Image(systemName:"arrow.right").foregroundStyle(AppPalette.ink) }
                        .padding(16).background(.white,in:RoundedRectangle(cornerRadius:18))
                    Text("Sample catalogue and prices · no live retailer connections").font(.caption2).foregroundStyle(AppPalette.muted).frame(maxWidth:.infinity,alignment:.center)
                }.padding(20)
            }.appScreen("Discover")
        }
    }
    private func categoryIcon(_ value: String) -> String { switch value { case "Dairy": "drop.fill"; case "Pantry": "takeoutbag.and.cup.and.straw.fill"; case "Snacks": "birthday.cake.fill"; case "Personal care": "sparkles"; case "Household": "house.fill"; default: "leaf.fill" } }
}

