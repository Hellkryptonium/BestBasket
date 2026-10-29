import Foundation

struct PersonalizedProduct: Identifiable {
    let product: CatalogProduct
    let reason: String
    var id: String { product.id }
}

struct RecommendationService {
    var offerRankingService = OfferRankingService()

    func rank(products: [CatalogProduct], offersByProductID: [String: [PriceOffer]],
               preferences: ShoppingPreferences) -> [PersonalizedProduct] {
        let ranked = products.sorted { lhs, rhs in
            compare(lhs, rhs, offersByProductID: offersByProductID, preferences: preferences)
        }
        return ranked.map { product in
            PersonalizedProduct(product: product,
                                reason: reason(for: product, offersByProductID: offersByProductID, preferences: preferences))
        }
    }

    func reason(for product: CatalogProduct, offersByProductID: [String: [PriceOffer]],
                preferences: ShoppingPreferences) -> String {
        guard preferences.personalizationEnabled else { return "Popular sample product" }
        if preferences.primaryPriority == .preferredBrands, isPreferredBrand(product, preferences) {
            return "Matches your preferred brand"
        }
        if isPreferredBrand(product, preferences) { return "Matches your preferred brand" }
        if preferences.primaryPriority == .highestRated, product.rating >= 4.5 {
            return String(format: "Highly rated at %.1f stars", product.rating)
        }
        if isPreferredCategory(product, preferences) { return "Popular in your favorite categories" }

        let offers = offersByProductID[product.id] ?? []
        if let recommendation = offerRankingService.rank(product: product, offers: offers, preferences: preferences).first {
            let platformID = PreferenceIDs.make(from: recommendation.offer.retailer)
            if preferences.preferredPlatformIDs.contains(platformID) {
                return "Best value among your preferred platforms"
            }
            if recommendation.offer.effectivePrice <= preferences.tripBudget {
                return "Fits your trip budget"
            }
            return recommendation.reason
        }
        return "Popular sample product"
    }

    private func compare(_ lhs: CatalogProduct, _ rhs: CatalogProduct,
                        offersByProductID: [String: [PriceOffer]], preferences: ShoppingPreferences) -> Bool {
        let lhsOffer = offerRankingService.rank(product: lhs, offers: offersByProductID[lhs.id] ?? [], preferences: preferences).first?.offer
        let rhsOffer = offerRankingService.rank(product: rhs, offers: offersByProductID[rhs.id] ?? [], preferences: preferences).first?.offer

        if preferences.personalizationEnabled {
            if let preferredOrder = comparePrimary(lhs, rhs, lhsOffer: lhsOffer, rhsOffer: rhsOffer,
                                                   offersByProductID: offersByProductID, preferences: preferences) {
                return preferredOrder
            }
            for priority in preferences.secondaryPriorities.sorted(by: { $0.rawValue < $1.rawValue }) {
                if let order = comparePriority(priority, lhs, rhs, lhsOffer: lhsOffer, rhsOffer: rhsOffer,
                                               preferences: preferences) { return order }
            }
            let lhsPreferredBrand = isPreferredBrand(lhs, preferences)
            let rhsPreferredBrand = isPreferredBrand(rhs, preferences)
            if lhsPreferredBrand != rhsPreferredBrand { return lhsPreferredBrand }
            let lhsPreferredCategory = isPreferredCategory(lhs, preferences)
            let rhsPreferredCategory = isPreferredCategory(rhs, preferences)
            if lhsPreferredCategory != rhsPreferredCategory { return lhsPreferredCategory }
            let lhsPreferredPlatform = lhsOffer.map { preferences.preferredPlatformIDs.contains(PreferenceIDs.make(from: $0.retailer)) } ?? false
            let rhsPreferredPlatform = rhsOffer.map { preferences.preferredPlatformIDs.contains(PreferenceIDs.make(from: $0.retailer)) } ?? false
            if lhsPreferredPlatform != rhsPreferredPlatform { return lhsPreferredPlatform }
            let lhsWithinBudget = (lhsOffer?.effectivePrice ?? .greatestFiniteMagnitude) <= preferences.tripBudget
            let rhsWithinBudget = (rhsOffer?.effectivePrice ?? .greatestFiniteMagnitude) <= preferences.tripBudget
            if lhsWithinBudget != rhsWithinBudget { return lhsWithinBudget }
        }

        if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
        return lhs.id < rhs.id
    }

    private func comparePrimary(_ lhs: CatalogProduct, _ rhs: CatalogProduct, lhsOffer: PriceOffer?, rhsOffer: PriceOffer?,
                                offersByProductID: [String: [PriceOffer]], preferences: ShoppingPreferences) -> Bool? {
        switch preferences.primaryPriority {
        case .lowestTotalPrice:
            return comparePrice(lhsOffer, rhsOffer)
        case .bestOverallValue:
            if let priceOrder = comparePrice(lhsOffer, rhsOffer) { return priceOrder }
            return nil
        case .preferredBrands:
            let left = isPreferredBrand(lhs, preferences), right = isPreferredBrand(rhs, preferences)
            return left == right ? nil : left
        case .highestRated:
            return lhs.rating == rhs.rating ? nil : lhs.rating > rhs.rating
        case .fastestDelivery:
            let left = fastestDelivery(lhs, offersByProductID: offersByProductID, preferences: preferences)
            let right = fastestDelivery(rhs, offersByProductID: offersByProductID, preferences: preferences)
            return left == right ? nil : left < right
        }
    }

    private func comparePriority(_ priority: ShoppingPriority, _ lhs: CatalogProduct, _ rhs: CatalogProduct,
                                 lhsOffer: PriceOffer?, rhsOffer: PriceOffer?, preferences: ShoppingPreferences) -> Bool? {
        switch priority {
        case .lowestTotalPrice, .bestOverallValue:
            return comparePrice(lhsOffer, rhsOffer)
        case .preferredBrands:
            let left = isPreferredBrand(lhs, preferences), right = isPreferredBrand(rhs, preferences)
            return left == right ? nil : left
        case .highestRated:
            return lhs.rating == rhs.rating ? nil : lhs.rating > rhs.rating
        case .fastestDelivery:
            let left = OfferRankingService.deliveryMinutes(lhsOffer?.delivery ?? "")
            let right = OfferRankingService.deliveryMinutes(rhsOffer?.delivery ?? "")
            return left == right ? nil : left < right
        }
    }

    private func comparePrice(_ lhs: PriceOffer?, _ rhs: PriceOffer?) -> Bool? {
        let left = lhs?.effectivePrice ?? .greatestFiniteMagnitude
        let right = rhs?.effectivePrice ?? .greatestFiniteMagnitude
        return left == right ? nil : left < right
    }

    private func fastestDelivery(_ product: CatalogProduct, offersByProductID: [String: [PriceOffer]],
                                 preferences: ShoppingPreferences) -> Int {
        offerRankingService.rank(product: product, offers: offersByProductID[product.id] ?? [], preferences: preferences)
            .first.map { OfferRankingService.deliveryMinutes($0.offer.delivery) } ?? Int.max
    }

    private func isPreferredBrand(_ product: CatalogProduct, _ preferences: ShoppingPreferences) -> Bool {
        preferences.preferredBrandIDs.contains(PreferenceIDs.make(from: product.brand))
    }
    private func isPreferredCategory(_ product: CatalogProduct, _ preferences: ShoppingPreferences) -> Bool {
        preferences.preferredCategoryIDs.contains(PreferenceIDs.make(from: product.category))
    }
}
