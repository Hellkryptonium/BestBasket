import Foundation
import Observation

@MainActor @Observable
final class DiscoverViewModel {
    private let basketRepository: any BasketRepository
    private let preferencesRepository: any PreferencesRepository
    private let recommendationService: RecommendationService
    private let offerRankingService: OfferRankingService
    let products: [CatalogProduct]
    private let offersByProductID: [String: [PriceOffer]]

    init(productRepository: any ProductRepository, basketRepository: any BasketRepository,
         preferencesRepository: any PreferencesRepository, recommendationService: RecommendationService,
         offerRankingService: OfferRankingService) {
        self.basketRepository = basketRepository
        self.preferencesRepository = preferencesRepository
        self.recommendationService = recommendationService
        self.offerRankingService = offerRankingService
        self.products = productRepository.products()
        self.offersByProductID = Dictionary(grouping: productRepository.allOffers(), by: \.productID)
    }

    var categories: [String] { Array(Set(products.map(\.category))).sorted() }
    var basketQuantity: Int { basketRepository.lines().reduce(0) { $0 + $1.quantity } }
    var basketProductCount: Int { basketRepository.lines().count }
    var personalizationEnabled: Bool { preferencesRepository.preferences.personalizationEnabled }
    var rankedRecommendations: [PersonalizedProduct] {
        recommendationService.rank(products: products, offersByProductID: offersByProductID,
                                   preferences: preferencesRepository.preferences)
    }
    var recommendations: [CatalogProduct] { Array(rankedRecommendations.prefix(8).map(\.product)) }
    var popularProducts: [CatalogProduct] {
        products.sorted { $0.rating == $1.rating ? $0.id < $1.id : $0.rating > $1.rating }.prefix(6).map { $0 }
    }

    func displayedOffer(for product: CatalogProduct) -> PriceOffer? {
        offerRankingService.rank(product: product, offers: offersByProductID[product.id] ?? [],
                                 preferences: preferencesRepository.preferences).first?.offer
    }

    func reason(for product: CatalogProduct) -> String? {
        guard preferencesRepository.preferences.personalizationEnabled else { return nil }
        return rankedRecommendations.first(where: { $0.id == product.id })?.reason
    }
}
