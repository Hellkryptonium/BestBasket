import Foundation

@MainActor
final class AppDependencies {
    let productRepository: any ProductRepository
    let basketRepository: any BasketRepository
    let appStateRepository: UserDefaultsAppStateRepository
    let preferencesRepository: any PreferencesRepository
    let recommendationService: RecommendationService
    let offerRankingService: OfferRankingService

    let discover: DiscoverViewModel
    let search: SearchViewModel
    let basket: BasketViewModel
    let tracking: TrackingViewModel
    let essentials: EssentialsViewModel
    let cookShop: CookShopViewModel
    let personalization: PersonalizationViewModel
    let groceryLists: GroceryListsViewModel

    init() {
        let products = MockProductRepository()
        let appState = UserDefaultsAppStateRepository(store: .standard)
        let preferences = UserDefaultsPreferencesRepository(store: .standard)
        let offerRanking = OfferRankingService()
        let recommendations = RecommendationService(offerRankingService: offerRanking)

        self.productRepository = products
        self.basketRepository = appState
        self.appStateRepository = appState
        self.preferencesRepository = preferences
        self.recommendationService = recommendations
        self.offerRankingService = offerRanking

        self.discover = DiscoverViewModel(productRepository: products, basketRepository: appState,
                                          preferencesRepository: preferences, recommendationService: recommendations,
                                          offerRankingService: offerRanking)
        self.search = SearchViewModel(productRepository: products, preferencesRepository: preferences,
                                      recommendationService: recommendations, offerRankingService: offerRanking,
                                      basketRepository: appState)
        self.basket = BasketViewModel(productRepository: products, basketRepository: appState, preferencesRepository: preferences)
        self.tracking = TrackingViewModel(productRepository: products, appStateRepository: appState,
                                          basketRepository: appState)
        self.groceryLists = GroceryListsViewModel(state: appState, products: products, basket: appState)
        self.essentials = EssentialsViewModel(productRepository: products, appStateRepository: appState,
                                              basketRepository: appState)
        self.cookShop = CookShopViewModel(productRepository: products, basketRepository: appState,
                                          appStateRepository: appState, groceryLists: groceryLists)
        self.personalization = PersonalizationViewModel(preferencesRepository: preferences, productRepository: products)
    }

    func productDetails(for product: CatalogProduct) -> ProductDetailViewModel {
        ProductDetailViewModel(product: product, productRepository: productRepository,
                               basketRepository: basketRepository,
                               preferencesRepository: preferencesRepository, offerRankingService: offerRankingService,
                               groceryLists: groceryLists)
    }
}
