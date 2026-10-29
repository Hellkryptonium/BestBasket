import Foundation

struct BasketSummary {
    let subtotal: Decimal
    let deliveryFees: Decimal
    let discount: Decimal
    let total: Decimal
    let recommendationName: String
    let recommendationTotal: Decimal
    let potentialSavings: Decimal
    let recommendedLines: [BasketRecommendationLine]
    let tripBudget: Decimal
    let remainingBudget: Decimal
    let amountOverBudget: Decimal
    let lowerCostAlternatives: [BasketOfferAlternative]

    static let empty = BasketSummary(
        subtotal: 0, deliveryFees: 0, discount: 0, total: 0,
        recommendationName: "", recommendationTotal: 0, potentialSavings: 0,
        recommendedLines: [], tripBudget: 0, remainingBudget: 0, amountOverBudget: 0,
        lowerCostAlternatives: []
    )
}

struct BasketOfferAlternative: Identifiable {
    let lineID: String
    let productName: String
    let currentPlatform: String
    let suggestedOffer: PriceOffer
    let estimatedNewTotal: Decimal
    let estimatedSavings: Decimal
    var id: String { "\(lineID)-\(suggestedOffer.id)" }
}

enum BasketCalculator {
    static func calculate(lines: [BasketLine], products: [CatalogProduct], offers: [PriceOffer], platforms: [String],
                          preferences: ShoppingPreferences, offerRankingService: OfferRankingService) -> BasketSummary {
        guard !lines.isEmpty else { return .empty }
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let offersByID = Dictionary(uniqueKeysWithValues: offers.map { ($0.id, $0) })
        let currentOffers = lines.compactMap { line -> (BasketLine, PriceOffer)? in
            guard let offer = offersByID[line.offerID] else { return nil }
            return (line, offer)
        }

        let subtotal = currentOffers.reduce(Decimal(0)) { $0 + $1.1.price * Decimal($1.0.quantity) }
        let discount = currentOffers.reduce(Decimal(0)) { $0 + $1.1.discount * Decimal($1.0.quantity) }
        let currentPlatforms = Set(currentOffers.map { $0.1.retailer })
        let deliveryFees = currentPlatforms.reduce(Decimal(0)) { $0 + platformFee($1) }
        let total = subtotal + deliveryFees - discount

        let singleStoreOptions = platforms.compactMap { platform -> (String, Decimal, [BasketRecommendationLine], Int)? in
            var cost: Decimal = 0
            var assignments: [BasketRecommendationLine] = []
            var deliveryMinutes = 0
            for line in lines {
                guard let product = productsByID[productID(for: line, offersByID: offersByID)],
                      let offer = offers.first(where: { $0.productID == product.id && $0.retailer == platform && $0.available }) else { return nil }
                cost += (offer.price - offer.discount) * Decimal(line.quantity)
                deliveryMinutes += OfferRankingService.deliveryMinutes(offer.delivery)
                assignments.append(BasketRecommendationLine(line: line, offer: offer))
            }
            return (platform, cost + platformFee(platform), assignments, deliveryMinutes)
        }

        let splitAssignments = lines.compactMap { line -> BasketRecommendationLine? in
            guard let product = productsByID[productID(for: line, offersByID: offersByID)],
                  let offer = offerRankingService.rank(product: product,
                                                       offers: offers.filter { $0.productID == product.id },
                                                       preferences: preferences).first?.offer else { return nil }
            return BasketRecommendationLine(line: line, offer: offer)
        }
        let splitItems = splitAssignments.reduce(Decimal(0)) {
            $0 + ($1.offer.price - $1.offer.discount) * Decimal($1.line.quantity)
        }
        let splitPlatforms = Set(splitAssignments.map { $0.offer.retailer })
        let splitTotal = splitItems + splitPlatforms.reduce(Decimal(0)) { $0 + platformFee($1) }

        guard let cheapestSingleStore = singleStoreOptions.min(by: { comparePlans($0, $1, preferences: preferences) }) else {
            return BasketSummary(subtotal: subtotal, deliveryFees: deliveryFees, discount: discount, total: total,
                                 recommendationName: "Current basket", recommendationTotal: total,
                                 potentialSavings: 0, recommendedLines: currentOffers.map { BasketRecommendationLine(line: $0.0, offer: $0.1) },
                                 tripBudget: preferences.tripBudget, remainingBudget: max(0, preferences.tripBudget - total),
                                 amountOverBudget: max(0, total - preferences.tripBudget), lowerCostAlternatives: [])
        }
        let useSplit = splitAssignments.count == lines.count && splitPlatforms.count > 1 && splitTotal + 15 < cheapestSingleStore.1
        let recommendationTotal = useSplit ? splitTotal : cheapestSingleStore.1
        let recommendedLines = useSplit ? splitAssignments : cheapestSingleStore.2
        let planName = useSplit ? "Split across \(splitPlatforms.count) platforms" : "Shop at \(cheapestSingleStore.0)"
        let alternatives = preferences.personalizationEnabled && total > preferences.tripBudget
            ? offerAlternatives(lines: lines, currentOffers: currentOffers, productsByID: productsByID,
                                offers: offers, offersByID: offersByID, currentTotal: total)
            : []
        return BasketSummary(subtotal: subtotal, deliveryFees: deliveryFees, discount: discount, total: total,
                             recommendationName: planName, recommendationTotal: recommendationTotal,
                             potentialSavings: max(0, cheapestSingleStore.1 - recommendationTotal),
                             recommendedLines: recommendedLines, tripBudget: preferences.tripBudget,
                             remainingBudget: max(0, preferences.tripBudget - total),
                             amountOverBudget: max(0, total - preferences.tripBudget),
                             lowerCostAlternatives: alternatives)
    }

    private static func comparePlans(_ lhs: (String, Decimal, [BasketRecommendationLine], Int),
                                     _ rhs: (String, Decimal, [BasketRecommendationLine], Int),
                                     preferences: ShoppingPreferences) -> Bool {
        if preferences.personalizationEnabled, preferences.primaryPriority == .fastestDelivery,
           lhs.3 != rhs.3 { return lhs.3 < rhs.3 }
        if preferences.personalizationEnabled, abs(lhs.1 - rhs.1) <= 5 {
            let leftPreferred = preferences.preferredPlatformIDs.contains(PreferenceIDs.make(from: lhs.0))
            let rightPreferred = preferences.preferredPlatformIDs.contains(PreferenceIDs.make(from: rhs.0))
            if leftPreferred != rightPreferred { return leftPreferred }
        }
        return lhs.1 == rhs.1 ? lhs.0 < rhs.0 : lhs.1 < rhs.1
    }

    private static func offerAlternatives(lines: [BasketLine], currentOffers: [(BasketLine, PriceOffer)],
                                         productsByID: [String: CatalogProduct], offers: [PriceOffer],
                                         offersByID: [String: PriceOffer], currentTotal: Decimal) -> [BasketOfferAlternative] {
        var suggestions: [BasketOfferAlternative] = []
        for (line, currentOffer) in currentOffers {
            guard let product = productsByID[currentOffer.productID] else { continue }
            for alternative in offers where alternative.productID == product.id && alternative.available && alternative.id != currentOffer.id {
                var changedLines = lines
                guard let index = changedLines.firstIndex(where: { $0.id == line.id }) else { continue }
                changedLines[index].offerID = alternative.id
                let simulatedTotal = basketTotal(for: changedLines, offersByID: offersByID)
                guard simulatedTotal < currentTotal else { continue }
                suggestions.append(BasketOfferAlternative(lineID: line.id, productName: product.name,
                                                          currentPlatform: currentOffer.retailer,
                                                          suggestedOffer: alternative, estimatedNewTotal: simulatedTotal,
                                                          estimatedSavings: currentTotal - simulatedTotal))
            }
        }
        return suggestions.sorted {
            $0.estimatedSavings == $1.estimatedSavings
                ? $0.suggestedOffer.retailer < $1.suggestedOffer.retailer
                : $0.estimatedSavings > $1.estimatedSavings
        }.prefix(3).map { $0 }
    }

    private static func basketTotal(for lines: [BasketLine], offersByID: [String: PriceOffer]) -> Decimal {
        let selected = lines.compactMap { line -> (BasketLine, PriceOffer)? in
            guard let offer = offersByID[line.offerID] else { return nil }
            return (line, offer)
        }
        let items = selected.reduce(Decimal(0)) { $0 + ($1.1.price - $1.1.discount) * Decimal($1.0.quantity) }
        let fees = Set(selected.map { $0.1.retailer }).reduce(Decimal(0)) { $0 + platformFee($1) }
        return items + fees
    }

    private static func platformFee(_ platform: String) -> Decimal {
        platform == "BigBasket" ? 25 : (platform == "Blinkit" ? 15 : 18)
    }

    private static func productID(for line: BasketLine, offersByID: [String: PriceOffer]) -> String {
        offersByID[line.offerID]?.productID ?? ""
    }
}
