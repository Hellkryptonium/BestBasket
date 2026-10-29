import Foundation
import Observation

@MainActor @Observable
final class TrackingViewModel {
    private let trackingRepository: any PriceTrackingRepository
    private let products: [CatalogProduct]
    private let offersByProductID: [String: [PriceOffer]]

    init(productRepository: any ProductRepository, trackingRepository: any PriceTrackingRepository) {
        self.trackingRepository = trackingRepository
        self.products = productRepository.products()
        self.offersByProductID = Dictionary(grouping: productRepository.allOffers(), by: \.productID)
    }

    var items: [TrackedItem] { trackingRepository.trackedItems() }
    func product(for item: TrackedItem) -> CatalogProduct? { products.first { $0.id == item.id } }
    func currentOffer(for item: TrackedItem) -> PriceOffer? {
        (offersByProductID[item.id] ?? []).filter(\.available).min { $0.effectivePrice < $1.effectivePrice }
    }
    func targetReached(for item: TrackedItem, at offer: PriceOffer) -> Bool {
        offer.price <= item.targetPrice
    }
    func track(_ product: CatalogProduct, targetPrice: Decimal) {
        var updated = items
        if let index = updated.firstIndex(where: { $0.id == product.id }) {
            updated[index].targetPrice = targetPrice
        } else {
            updated.append(TrackedItem(id: product.id, targetPrice: targetPrice))
        }
        trackingRepository.save(updated)
    }
    func updateTarget(for productID: String, to target: Decimal) {
        var updated = items
        guard let index = updated.firstIndex(where: { $0.id == productID }) else { return }
        updated[index].targetPrice = target
        trackingRepository.save(updated)
    }
    func untrack(_ item: TrackedItem) { trackingRepository.save(items.filter { $0.id != item.id }) }
}
