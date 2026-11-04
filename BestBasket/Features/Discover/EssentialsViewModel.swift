import Foundation
import Observation

struct EssentialSummary: Identifiable {
    let product: CatalogProduct
    let purchaseCount: Int
    let latestEntry: PurchaseHistoryEntry
    let previousPrice: Decimal?
    let typicalIntervalDays: Int?
    var id: String { product.id }
}

@MainActor @Observable
final class EssentialsViewModel {
    private var appStateRepository: PersistentAppStateRepository
    private let basketRepository: any BasketRepository
    private let products: [CatalogProduct]
    private let offers: [PriceOffer]
    private let purchaseHistory = MockPurchaseHistory.entries

    init(productRepository: any ProductRepository, appStateRepository: PersistentAppStateRepository,
         basketRepository: any BasketRepository) {
        self.appStateRepository = appStateRepository
        self.basketRepository = basketRepository
        self.products = productRepository.products()
        self.offers = productRepository.allOffers()
    }

    var essentials: [EssentialSummary] {
        let grouped = Dictionary(grouping: purchaseHistory, by: \.productID)
        return grouped.compactMap { productID, entries in
            guard let product = products.first(where: { $0.id == productID }),
                  let latest = entries.max(by: { $0.purchaseDate < $1.purchaseDate }) else { return nil }
            let previous = entries.filter { $0.id != latest.id }.max(by: { $0.purchaseDate < $1.purchaseDate })?.unitPrice
            let orderedDates = entries.map(\.purchaseDate).sorted()
            let interval = orderedDates.count > 1
                ? Int((orderedDates.last!.timeIntervalSince(orderedDates.first!) / Double(orderedDates.count - 1) / 86_400).rounded())
                : nil
            return EssentialSummary(product: product, purchaseCount: entries.count, latestEntry: latest,
                                     previousPrice: previous, typicalIntervalDays: interval)
        }
        .sorted { $0.purchaseCount == $1.purchaseCount ? $0.latestEntry.purchaseDate > $1.latestEntry.purchaseDate : $0.purchaseCount > $1.purchaseCount }
    }

    var lists: [SavedGroceryList] { appStateRepository.appState.savedLists }
    var previousBaskets: [PreviousBasketSnapshot] { appStateRepository.appState.previousBaskets }
    var reminders: [RefillReminder] { appStateRepository.appState.reminders }
    var catalogProducts: [CatalogProduct] { products.sorted { $0.name < $1.name } }
    var currentBasketIsEmpty: Bool { basketRepository.lines().isEmpty }

    func currentOffer(for product: CatalogProduct) -> PriceOffer? {
        offers.filter { $0.productID == product.id && $0.available }.min { $0.effectivePrice < $1.effectivePrice }
    }

    func addEssential(_ essential: EssentialSummary) {
        guard let offer = currentOffer(for: essential.product) else { return }
        addProduct(productID: essential.product.id, quantity: essential.latestEntry.quantity, offer: offer)
    }

    func createList(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var state = appStateRepository.appState
        state.savedLists.insert(SavedGroceryList(name: trimmed, items: []), at: 0)
        appStateRepository.appState = state
    }

    func renameList(_ list: SavedGroceryList, to name: String) {
        var state = appStateRepository.appState
        guard let index = state.savedLists.firstIndex(where: { $0.id == list.id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.savedLists[index].name = trimmed
        state.savedLists[index].updatedAt = .now
        appStateRepository.appState = state
    }

    func deleteList(_ list: SavedGroceryList) {
        var state = appStateRepository.appState
        state.savedLists.removeAll { $0.id == list.id }
        appStateRepository.appState = state
    }

    func duplicateList(_ list: SavedGroceryList) {
        var state = appStateRepository.appState
        state.savedLists.insert(SavedGroceryList(name: "\(list.name) copy", items: list.items), at: 0)
        appStateRepository.appState = state
    }

    func addProduct(_ product: CatalogProduct, to list: SavedGroceryList) {
        var state = appStateRepository.appState
        guard let listIndex = state.savedLists.firstIndex(where: { $0.id == list.id }) else { return }
        if let itemIndex = state.savedLists[listIndex].items.firstIndex(where: { $0.productID == product.id }) {
            state.savedLists[listIndex].items[itemIndex].quantity += 1
        } else {
            state.savedLists[listIndex].items.append(GroceryListItem(productID: product.id, quantity: 1))
        }
        state.savedLists[listIndex].updatedAt = .now
        appStateRepository.appState = state
    }

    func changeListQuantity(_ item: GroceryListItem, in list: SavedGroceryList, by amount: Int) {
        var state = appStateRepository.appState
        guard let listIndex = state.savedLists.firstIndex(where: { $0.id == list.id }),
              let itemIndex = state.savedLists[listIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        state.savedLists[listIndex].items[itemIndex].quantity += amount
        if state.savedLists[listIndex].items[itemIndex].quantity <= 0 {
            state.savedLists[listIndex].items.remove(at: itemIndex)
        }
        state.savedLists[listIndex].updatedAt = .now
        appStateRepository.appState = state
    }

    func addListToBasket(_ list: SavedGroceryList) {
        for item in list.items {
            guard let offer = bestOffer(for: item.productID) else { continue }
            addProduct(productID: item.productID, quantity: item.quantity, offer: offer)
        }
    }

    func saveCurrentBasket(name: String = "Basket · \(Date.now.formatted(date: .abbreviated, time: .omitted))") {
        let basketItems = basketRepository.lines().compactMap { line -> GroceryListItem? in
            guard let offer = offers.first(where: { $0.id == line.offerID }) else { return nil }
            return GroceryListItem(productID: offer.productID, quantity: line.quantity)
        }
        guard !basketItems.isEmpty else { return }
        let currentLines = basketRepository.lines()
        let selectedOffers = currentLines.compactMap { line in offers.first(where: { $0.id == line.offerID }).map { (line, $0) } }
        let itemTotal = selectedOffers.reduce(Decimal(0)) { $0 + ($1.1.price - $1.1.discount) * Decimal($1.0.quantity) }
        let fees = Set(selectedOffers.map { $0.1.retailer }).reduce(Decimal(0)) { total, retailer in
            total + (selectedOffers.first(where: { $0.1.retailer == retailer })?.1.deliveryFee ?? 0)
        }
        let platformFees = Set(selectedOffers.map { $0.1.retailer }).reduce(Decimal(0)) { total, retailer in
            total + (selectedOffers.first(where: { $0.1.retailer == retailer })?.1.platformFee ?? 0)
        }
        let total = itemTotal + fees + platformFees
        var state = appStateRepository.appState
        state.previousBaskets.insert(PreviousBasketSnapshot(name: name, items: basketItems, total: total), at: 0)
        appStateRepository.appState = state
    }

    func restore(_ snapshot: PreviousBasketSnapshot) {
        snapshot.items.forEach(restore)
    }

    func restore(_ item: GroceryListItem) {
        guard let offer = bestOffer(for: item.productID) else { return }
        addProduct(productID: item.productID, quantity: item.quantity, offer: offer)
    }

    func setReminder(for essential: EssentialSummary, interval: RefillInterval = .weekly) {
        var state = appStateRepository.appState
        let lastPurchase = essential.latestEntry.purchaseDate
        let next = nextDate(after: lastPurchase, interval: interval.days)
        if let index = state.reminders.firstIndex(where: { $0.productID == essential.product.id }) {
            state.reminders[index].interval = interval
            state.reminders[index].lastPurchaseAt = lastPurchase
            state.reminders[index].nextReminderAt = next
            state.reminders[index].enabled = true
        } else {
            state.reminders.append(RefillReminder(id: UUID().uuidString, productID: essential.product.id,
                                                  interval: interval, lastPurchaseAt: lastPurchase,
                                                  nextReminderAt: next, enabled: true))
        }
        appStateRepository.appState = state
    }

    func setReminderEnabled(_ reminder: RefillReminder, enabled: Bool) {
        var state = appStateRepository.appState
        guard let index = state.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        state.reminders[index].enabled = enabled
        appStateRepository.appState = state
    }

    func updateReminderInterval(_ reminder: RefillReminder, interval: RefillInterval) {
        var state = appStateRepository.appState
        guard let index = state.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        state.reminders[index].interval = interval
        state.reminders[index].nextReminderAt = nextDate(after: state.reminders[index].lastPurchaseAt, interval: interval.days)
        appStateRepository.appState = state
    }

    func product(for id: String) -> CatalogProduct? { products.first { $0.id == id } }

    private func bestOffer(for productID: String) -> PriceOffer? {
        offers.filter { $0.productID == productID && $0.available }.min { $0.effectivePrice < $1.effectivePrice }
    }

    private func addProduct(productID: String, quantity: Int, offer: PriceOffer) {
        var lines = basketRepository.lines()
        if let index = lines.firstIndex(where: { line in
            offers.first(where: { $0.id == line.offerID })?.productID == productID
        }) {
            lines[index].quantity += quantity
        } else {
            lines.append(BasketLine(id: UUID().uuidString, offerID: offer.id, quantity: quantity))
        }
        basketRepository.save(lines)
    }

    private func nextDate(after date: Date, interval: Int) -> Date {
        var next = Calendar.current.date(byAdding: .day, value: max(1, interval), to: date) ?? date.addingTimeInterval(86400)
        while next <= .now {
            next = Calendar.current.date(byAdding: .day, value: max(1, interval), to: next) ?? next.addingTimeInterval(86400)
        }
        return next
    }
}
