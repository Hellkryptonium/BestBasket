import SwiftUI

struct ContentView: View {
    @State private var dependencies = AppDependencies()
    @State private var selectedTab: AppTab = .discover
    @State private var selectedProduct: CatalogProduct?
    @State private var showingFilters = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView(
                model: dependencies.discover,
                essentialsModel: dependencies.essentials,
                cookShopModel: dependencies.cookShop,
                openProduct: { selectedProduct = $0 },
                goToSearch: { selectedTab = .search },
                goToBasket: { selectedTab = .basket },
                goToBasketWatch: { selectedTab = .tracking },
                openCategory: { category in
                    dependencies.search.selectedCategory = category
                    selectedTab = .search
                }
            )
            .tabItem { Label("Discover", systemImage: "sparkles") }
            .tag(AppTab.discover)

            SearchView(model: dependencies.search, openProduct: { selectedProduct = $0 }, showFilters: { showingFilters = true }, lists: dependencies.groceryLists)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search)

            GroceryListsView(model: dependencies.groceryLists)
                .tabItem { Label("Lists", systemImage: "list.bullet") }
                .tag(AppTab.lists)

            EssentialsView(model: dependencies.essentials)
                .tabItem { Label("Essentials", systemImage: "repeat") }
                .tag(AppTab.essentials)

            BasketView(model: dependencies.basket, openProduct: { selectedProduct = $0 })
                .tabItem {
                    Label("Basket\(dependencies.basket.itemCount == 0 ? "" : " · \(dependencies.basket.itemCount)")", systemImage: "basket.fill")
                }
                .tag(AppTab.basket)

            TrackingView(model: dependencies.tracking)
                .tabItem { Label("Basket Watch", systemImage: "bell.badge") }
                .tag(AppTab.tracking)

            PersonalizationView(model: dependencies.personalization)
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .tint(AppPalette.cobalt)
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(model: dependencies.productDetails(for: product))
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(model: dependencies.search)
        }
    }
}
