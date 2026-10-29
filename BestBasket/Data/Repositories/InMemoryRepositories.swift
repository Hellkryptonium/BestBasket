import Observation

@MainActor @Observable
final class InMemoryBasketRepository: BasketRepository {
    private var storage: [BasketLine] = []
    func lines() -> [BasketLine] { storage }
    func save(_ lines: [BasketLine]) { storage = lines }
}

@MainActor @Observable
final class InMemoryPriceTrackingRepository: PriceTrackingRepository {
    private var storage: [TrackedItem] = []
    func trackedItems() -> [TrackedItem] { storage }
    func save(_ items: [TrackedItem]) { storage = items }
}

@MainActor @Observable
final class InMemoryPreferencesRepository: PreferencesRepository {
    var preferences = ShoppingPreferences()
}
