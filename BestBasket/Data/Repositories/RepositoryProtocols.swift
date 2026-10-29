import Foundation

@MainActor
protocol ProductRepository {
    func products() -> [CatalogProduct]
    func offers(for productID: String) -> [PriceOffer]
    func allOffers() -> [PriceOffer]
    func platforms() -> [String]
}

@MainActor
protocol BasketRepository {
    func lines() -> [BasketLine]
    func save(_ lines: [BasketLine])
}

@MainActor
protocol PriceTrackingRepository {
    func trackedItems() -> [TrackedItem]
    func save(_ items: [TrackedItem])
}

@MainActor
protocol PreferencesRepository {
    var preferences: ShoppingPreferences { get set }
}
