import Foundation
import Observation

@MainActor @Observable
final class BasketViewModel {
    private let basketRepository: any BasketRepository
    private let preferencesRepository: any PreferencesRepository
    private let offerRankingService: OfferRankingService
    private let products: [CatalogProduct]
    private let offers: [PriceOffer]
    private let platforms: [String]

    init(productRepository: any ProductRepository, basketRepository: any BasketRepository,
         preferencesRepository: any PreferencesRepository) {
        self.basketRepository = basketRepository
        self.preferencesRepository = preferencesRepository
        self.offerRankingService = OfferRankingService()
        self.products = productRepository.products()
        self.offers = productRepository.allOffers()
        self.platforms = productRepository.platforms()
    }

    var lines: [BasketLine] { basketRepository.lines() }
    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var summary: BasketSummary {
        BasketCalculator.calculate(lines: lines, products: products, offers: offers, platforms: platforms,
                                  preferences: preferencesRepository.preferences,
                                  offerRankingService: offerRankingService)
    }

    func offer(for line: BasketLine) -> PriceOffer? {
        offers.first { $0.id == line.offerID }
    }
    func product(for line: BasketLine) -> CatalogProduct? {
        guard let offer = offer(for: line) else { return nil }
        return products.first { $0.id == offer.productID }
    }
    func add(_ offer: PriceOffer, quantity: Int = 1) {
        var updated = lines
        if let index = updated.firstIndex(where: { $0.offerID == offer.id }) {
            updated[index].quantity += quantity
        } else {
            updated.append(BasketLine(id: UUID().uuidString, offerID: offer.id, quantity: quantity))
        }
        basketRepository.save(updated)
    }
    func updateQuantity(_ line: BasketLine, by amount: Int) {
        var updated = lines
        guard let index = updated.firstIndex(where: { $0.id == line.id }) else { return }
        updated[index].quantity += amount
        if updated[index].quantity <= 0 { updated.remove(at: index) }
        basketRepository.save(updated)
    }
    func replaceOffer(for lineID: String, with offer: PriceOffer) {
        var updated = lines
        guard let index = updated.firstIndex(where: { $0.id == lineID }) else { return }
        updated[index].offerID = offer.id
        basketRepository.save(updated)
    }
    func remove(_ line: BasketLine) { basketRepository.save(lines.filter { $0.id != line.id }) }
}
