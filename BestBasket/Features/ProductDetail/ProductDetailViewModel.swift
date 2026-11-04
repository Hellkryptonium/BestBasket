import Foundation
import Observation

@MainActor @Observable
final class ProductDetailViewModel {
    let product: CatalogProduct
    private let basketRepository: any BasketRepository
    private let preferencesRepository: any PreferencesRepository
    private let offerRankingService: OfferRankingService
    private let allOffers: [PriceOffer]
    private let productOffers: [PriceOffer]
    let groceryLists: GroceryListsViewModel

    init(product: CatalogProduct, productRepository: any ProductRepository,
         basketRepository: any BasketRepository,
         preferencesRepository: any PreferencesRepository, offerRankingService: OfferRankingService,
         groceryLists: GroceryListsViewModel) {
        self.product = product
        self.basketRepository = basketRepository
        self.preferencesRepository = preferencesRepository
        self.offerRankingService = offerRankingService
        self.allOffers = productRepository.allOffers()
        self.productOffers = productRepository.offers(for: product.id)
        self.groceryLists = groceryLists
    }

    var rankedOffers: [RankedOffer] {
        offerRankingService.rank(product: product, offers: productOffers, preferences: preferencesRepository.preferences)
    }
    var offers: [PriceOffer] {
        rankedOffers.map(\.offer) + productOffers.filter { !$0.available }.sorted { $0.effectivePrice < $1.effectivePrice }
    }
    var bestOffer: PriceOffer? { rankedOffers.first?.offer }
    func offerReason(_ offer: PriceOffer) -> String? { rankedOffers.first(where: { $0.id == offer.id })?.reason }
    func add(_ offer: PriceOffer, toBasket quantity: Int = 1) {
        var lines = basketRepository.lines()
        if let index = lines.firstIndex(where: { basketRepositoryProductID(for: $0) == offer.productID }) {
            lines[index].quantity += quantity
        } else {
            lines.append(BasketLine(id: UUID().uuidString, offerID: offer.id, quantity: quantity))
        }
        basketRepository.save(lines)
    }

    private func basketRepositoryProductID(for line: BasketLine) -> String? {
        // Product IDs are stable prefixes in this mock catalog's offer IDs.
        allOffers.first(where: { $0.id == line.offerID })?.productID
    }
}
