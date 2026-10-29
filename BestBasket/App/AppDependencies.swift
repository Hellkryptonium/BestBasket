import Foundation

@MainActor
final class AppDependencies {
    let productRepository: any ProductRepository
    let basketRepository: any BasketRepository
    let trackingRepository: any PriceTrackingRepository
    let preferencesRepository: any PreferencesRepository
    let recommendationService: RecommendationService
    let offerRankingService: OfferRankingService

    let discover: DiscoverViewModel
    let search: SearchViewModel
    let basket: BasketViewModel
    let tracking: TrackingViewModel
    let personalization: PersonalizationViewModel

    init() {
        let products = MockProductRepository()
        let basket = InMemoryBasketRepository()
        let tracking = InMemoryPriceTrackingRepository()
        let preferences = UserDefaultsPreferencesRepository(store: .standard)
        let offerRanking = OfferRankingService()
        let recommendations = RecommendationService(offerRankingService: offerRanking)

        self.productRepository = products
        self.basketRepository = basket
        self.trackingRepository = tracking
        self.preferencesRepository = preferences
        self.recommendationService = recommendations
        self.offerRankingService = offerRanking

        self.discover = DiscoverViewModel(productRepository: products, basketRepository: basket,
                                          preferencesRepository: preferences, recommendationService: recommendations,
                                          offerRankingService: offerRanking)
        self.search = SearchViewModel(productRepository: products, preferencesRepository: preferences,
                                      recommendationService: recommendations, offerRankingService: offerRanking)
        self.basket = BasketViewModel(productRepository: products, basketRepository: basket, preferencesRepository: preferences)
        self.tracking = TrackingViewModel(productRepository: products, trackingRepository: tracking)
        self.personalization = PersonalizationViewModel(preferencesRepository: preferences, productRepository: products)
    }

    func productDetails(for product: CatalogProduct) -> ProductDetailViewModel {
        ProductDetailViewModel(product: product, productRepository: productRepository,
                               basketRepository: basketRepository, trackingRepository: trackingRepository,
                               preferencesRepository: preferencesRepository, offerRankingService: offerRankingService)
    }
}
