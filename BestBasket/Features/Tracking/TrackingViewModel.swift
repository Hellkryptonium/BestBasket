import Foundation
import Observation

@MainActor @Observable
final class TrackingViewModel {
    private var appStateRepository: PersistentAppStateRepository
    private let basketRepository: any BasketRepository
    private let products: [CatalogProduct]
    private let offers: [PriceOffer]

    init(productRepository: any ProductRepository, appStateRepository: PersistentAppStateRepository,
         basketRepository: any BasketRepository) {
        self.appStateRepository = appStateRepository
        self.basketRepository = basketRepository
        self.products = productRepository.products()
        self.offers = productRepository.allOffers()
        refreshNotifications()
    }

    var isEnabled: Bool {
        get { appStateRepository.appState.basketWatchEnabled }
        set {
            var state = appStateRepository.appState
            state.basketWatchEnabled = newValue
            appStateRepository.appState = state
            if newValue { refreshNotifications() }
        }
    }

    var deals: [BasketDeal] {
        guard isEnabled else { return [] }
        return BasketWatchService.deals(lines: basketRepository.lines(), products: products, offers: offers)
    }

    var isBasketEmpty: Bool { basketRepository.lines().isEmpty }

    var notifications: [BasketDealNotification] {
        appStateRepository.appState.dealNotifications.sorted { $0.createdAt > $1.createdAt }
    }

    func refreshNotifications() {
        guard isEnabled else { return }
        var state = appStateRepository.appState
        var known = Set(state.dealNotifications.map(\.id))
        for deal in BasketWatchService.deals(lines: basketRepository.lines(), products: products, offers: offers) {
            let id = "deal-\(deal.product.id)-\(deal.currentOffer.id)-\(deal.suggestedOffer.id)"
            guard known.insert(id).inserted else { continue }
            state.dealNotifications.append(BasketDealNotification(
                id: id, productID: deal.product.id, originalOfferID: deal.currentOffer.id,
                suggestedOfferID: deal.suggestedOffer.id, estimatedSavings: deal.savings,
                kind: deal.kind, createdAt: .now, readAt: nil
            ))
        }
        appStateRepository.appState = state
    }

    func markRead(_ notification: BasketDealNotification) {
        var state = appStateRepository.appState
        guard let index = state.dealNotifications.firstIndex(where: { $0.id == notification.id }) else { return }
        state.dealNotifications[index].readAt = .now
        appStateRepository.appState = state
    }

    func markAllRead() {
        var state = appStateRepository.appState
        for index in state.dealNotifications.indices where state.dealNotifications[index].readAt == nil {
            state.dealNotifications[index].readAt = .now
        }
        appStateRepository.appState = state
    }

    func apply(_ deal: BasketDeal) {
        var lines = basketRepository.lines()
        guard let index = lines.firstIndex(where: { $0.id == deal.line.id }),
              offers.first(where: { $0.id == lines[index].offerID })?.productID == deal.product.id,
              deal.suggestedOffer.productID == deal.product.id else { return }
        lines[index].offerID = deal.suggestedOffer.id
        basketRepository.save(lines)
        markNotificationRead(productID: deal.product.id, offerID: deal.suggestedOffer.id)
    }

    private func markNotificationRead(productID: String, offerID: String) {
        var state = appStateRepository.appState
        for index in state.dealNotifications.indices where state.dealNotifications[index].productID == productID
            && state.dealNotifications[index].suggestedOfferID == offerID {
            state.dealNotifications[index].readAt = .now
        }
        appStateRepository.appState = state
    }
}
