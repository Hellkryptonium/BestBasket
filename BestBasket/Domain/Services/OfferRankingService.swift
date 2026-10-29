import Foundation

struct RankedOffer: Identifiable {
    let offer: PriceOffer
    let reason: String
    var id: String { offer.id }
}

struct OfferRankingService {
    func rank(product: CatalogProduct, offers: [PriceOffer], preferences: ShoppingPreferences) -> [RankedOffer] {
        let availableOffers = offers.filter(\.available)
        let sorted = availableOffers.sorted { left, right in
            compare(left, right, preferences: preferences)
        }
        guard let cheapest = availableOffers.map(\.effectivePrice).min() else { return [] }

        return sorted.map { offer in
            let reason: String
            if preferences.personalizationEnabled, preferences.primaryPriority == .fastestDelivery,
               Self.deliveryMinutes(offer.delivery) == Self.deliveryMinutes(sorted.first?.delivery ?? "") {
                reason = "Fastest available delivery"
            } else if preferences.personalizationEnabled,
                      preferences.preferredPlatformIDs.contains(PreferenceIDs.make(from: offer.retailer)),
                      offer.effectivePrice <= cheapest + 5 {
                reason = "On a preferred platform at a similar effective price"
            } else if offer.effectivePrice == cheapest {
                reason = "Lowest effective price"
            } else if product.rating >= 4.5 {
                reason = "Highly rated product with a competitive offer"
            } else {
                reason = "Best available effective price"
            }
            return RankedOffer(offer: offer, reason: reason)
        }
    }

    private func compare(_ lhs: PriceOffer, _ rhs: PriceOffer, preferences: ShoppingPreferences) -> Bool {
        let lhsDelivery = Self.deliveryMinutes(lhs.delivery)
        let rhsDelivery = Self.deliveryMinutes(rhs.delivery)
        if preferences.personalizationEnabled, preferences.primaryPriority == .fastestDelivery, lhsDelivery != rhsDelivery {
            return lhsDelivery < rhsDelivery
        }

        let priceDifference = lhs.effectivePrice - rhs.effectivePrice
        let usePreferenceTieBreak = preferences.personalizationEnabled && (preferences.primaryPriority == .bestOverallValue
            || preferences.secondaryPriorities.contains(.fastestDelivery)
            || preferences.secondaryPriorities.contains(.preferredBrands))
        if usePreferenceTieBreak, abs(priceDifference) <= 5 {
            let lhsPreferred = preferences.preferredPlatformIDs.contains(PreferenceIDs.make(from: lhs.retailer))
            let rhsPreferred = preferences.preferredPlatformIDs.contains(PreferenceIDs.make(from: rhs.retailer))
            if lhsPreferred != rhsPreferred { return lhsPreferred }
            if preferences.secondaryPriorities.contains(.fastestDelivery), lhsDelivery != rhsDelivery {
                return lhsDelivery < rhsDelivery
            }
        }

        if lhs.effectivePrice != rhs.effectivePrice { return lhs.effectivePrice < rhs.effectivePrice }
        if lhsDelivery != rhsDelivery { return lhsDelivery < rhsDelivery }
        return lhs.retailer < rhs.retailer
    }

    static func deliveryMinutes(_ estimate: String) -> Int {
        let digits = estimate.prefix { $0.isNumber }
        return Int(digits) ?? Int.max
    }
}
