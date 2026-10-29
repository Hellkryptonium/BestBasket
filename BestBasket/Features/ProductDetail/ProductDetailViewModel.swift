import Foundation
import Observation

@MainActor @Observable
final class ProductDetailViewModel {
    let product: CatalogProduct
    private let basketRepository: any BasketRepository
    private let trackingRepository: any PriceTrackingRepository
    private let preferencesRepository: any PreferencesRepository
    private let offerRankingService: OfferRankingService
    private let allOffers: [PriceOffer]

    init(product: CatalogProduct, productRepository: any ProductRepository,
         basketRepository: any BasketRepository, trackingRepository: any PriceTrackingRepository,
         preferencesRepository: any PreferencesRepository, offerRankingService: OfferRankingService) {
        self.product = product
        self.basketRepository = basketRepository
        self.trackingRepository = trackingRepository
        self.preferencesRepository = preferencesRepository
        self.offerRankingService = offerRankingService
        self.allOffers = productRepository.offers(for: product.id)
    }

    var rankedOffers: [RankedOffer] {
        offerRankingService.rank(product: product, offers: allOffers, preferences: preferencesRepository.preferences)
    }
    var offers: [PriceOffer] {
        rankedOffers.map(\.offer) + allOffers.filter { !$0.available }.sorted { $0.effectivePrice < $1.effectivePrice }
    }
    var bestOffer: PriceOffer? { rankedOffers.first?.offer }
    func offerReason(_ offer: PriceOffer) -> String? { rankedOffers.first(where: { $0.id == offer.id })?.reason }
    var trackedItem: TrackedItem? { trackingRepository.trackedItems().first { $0.id == product.id } }

    func add(_ offer: PriceOffer, toBasket quantity: Int = 1) {
        var lines = basketRepository.lines()
        if let index = lines.firstIndex(where: { $0.offerID == offer.id }) {
            lines[index].quantity += quantity
        } else {
            lines.append(BasketLine(id: UUID().uuidString, offerID: offer.id, quantity: quantity))
        }
        basketRepository.save(lines)
    }

    func track(targetPrice: Decimal) {
        var tracked = trackingRepository.trackedItems()
        if let index = tracked.firstIndex(where: { $0.id == product.id }) {
            tracked[index].targetPrice = targetPrice
        } else {
            tracked.append(TrackedItem(id: product.id, targetPrice: targetPrice))
        }
        trackingRepository.save(tracked)
    }
}
