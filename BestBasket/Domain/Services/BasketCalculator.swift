import Foundation

struct BasketPlan: Identifiable {
    let name: String
    let total: Decimal
    let itemSubtotal: Decimal
    let deliveryFees: Decimal
    let platformFees: Decimal
    let discounts: Decimal
    let assignments: [BasketRecommendationLine]
    let platforms: [String]
    let excludedProducts: [String]
    var isComplete: Bool { excludedProducts.isEmpty }
    var id: String { name }
}

struct BasketSummary {
    let subtotal: Decimal
    let deliveryFees: Decimal
    let platformFees: Decimal
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
    let recommendedPlan: BasketPlan?
    let singlePlatformPlans: [BasketPlan]
    let cheapestSinglePlatform: BasketPlan?
    let bestMultiPlatform: BasketPlan?
    let mostExpensiveSinglePlatform: BasketPlan?
    let savingsVersusMostExpensive: Decimal
    let productsUnavailableEverywhere: [String]

    static let empty = BasketSummary(
        subtotal: 0, deliveryFees: 0, platformFees: 0, discount: 0, total: 0,
        recommendationName: "", recommendationTotal: 0, potentialSavings: 0,
        recommendedLines: [], tripBudget: 0, remainingBudget: 0, amountOverBudget: 0,
        lowerCostAlternatives: [], recommendedPlan: nil, singlePlatformPlans: [],
        cheapestSinglePlatform: nil, bestMultiPlatform: nil, mostExpensiveSinglePlatform: nil,
        savingsVersusMostExpensive: 0, productsUnavailableEverywhere: []
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
    private struct IndexedPlan {
        let plan: BasketPlan
        let usedPlatformCount: Int
    }

    static func calculate(lines: [BasketLine], products: [CatalogProduct], offers: [PriceOffer], platforms: [String],
                          preferences: ShoppingPreferences) -> BasketSummary {
        guard !lines.isEmpty else { return .empty }
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let offersByID = Dictionary(uniqueKeysWithValues: offers.map { ($0.id, $0) })
        let currentOffers = lines.compactMap { line -> (BasketLine, PriceOffer)? in
            guard let offer = offersByID[line.offerID] else { return nil }
            return (line, offer)
        }
        let subtotal = currentOffers.reduce(Decimal(0)) { $0 + $1.1.price * Decimal($1.0.quantity) }
        let discount = currentOffers.reduce(Decimal(0)) { $0 + $1.1.discount * Decimal($1.0.quantity) }
        let currentRetailers = Set(currentOffers.map { $0.1.retailer })
        let deliveryFees = currentRetailers.reduce(Decimal(0)) { total, retailer in
            total + platformDeliveryFee(retailer, offers: offers)
        }
        let platformFees = currentRetailers.reduce(Decimal(0)) { total, retailer in
            total + retailerPlatformFee(retailer, offers: offers)
        }
        let total = subtotal + deliveryFees + platformFees - discount

        let unavailable = lines.compactMap { line -> String? in
            let productID = offersByID[line.offerID]?.productID
            guard let productID,
                  !offers.contains(where: { $0.productID == productID && $0.available }) else { return nil }
            return productsByID[productID]?.name ?? productID
        }

        let candidates = enumeratePlans(lines: lines, productsByID: productsByID, offers: offers,
                                        platforms: platforms, offersByID: offersByID)
        let singles = candidates.filter { $0.usedPlatformCount == 1 }.map(\.plan)
        let completeSingles = singles.filter(\.isComplete)
        let completeMultis = candidates.filter { $0.usedPlatformCount > 1 && $0.plan.isComplete }.map(\.plan)
        let cheapestSingle = completeSingles.min(by: planIsCheaper)
        let bestMulti = completeMultis.min(by: planIsCheaper)
        let mostExpensive = completeSingles.max { lhs, rhs in
            lhs.total == rhs.total ? lhs.name > rhs.name : lhs.total < rhs.total
        }
        let recommended: BasketPlan?
        if let bestMulti, let cheapestSingle, bestMulti.total + 15 < cheapestSingle.total {
            recommended = bestMulti
        } else {
            recommended = cheapestSingle ?? bestMulti
        }
        let partial = recommended == nil
            ? candidates.map(\.plan).filter { !$0.assignments.isEmpty }.min(by: planIsCheaper)
            : nil
        let displayPlan = recommended ?? partial
        let alternativeSuggestions = preferences.personalizationEnabled && total > preferences.tripBudget
            ? offerAlternatives(lines: lines, currentOffers: currentOffers, productsByID: productsByID,
                                offers: offers, offersByID: offersByID, currentTotal: total)
            : []
        let savingsVsMost = displayPlan.flatMap { plan in mostExpensive.map { max(0, $0.total - plan.total) } } ?? 0
        let compareNotice = displayPlan?.excludedProducts ?? unavailable

        return BasketSummary(
            subtotal: subtotal, deliveryFees: deliveryFees, platformFees: platformFees, discount: discount, total: total,
            recommendationName: displayPlan?.name ?? "No comparable offers",
            recommendationTotal: displayPlan?.total ?? total,
            potentialSavings: max(0, total - (displayPlan?.total ?? total)),
            recommendedLines: displayPlan?.assignments ?? [], tripBudget: preferences.tripBudget,
            remainingBudget: max(0, preferences.tripBudget - total),
            amountOverBudget: max(0, total - preferences.tripBudget),
            lowerCostAlternatives: alternativeSuggestions, recommendedPlan: displayPlan,
            singlePlatformPlans: singles.sorted(by: planIsCheaper), cheapestSinglePlatform: cheapestSingle,
            bestMultiPlatform: bestMulti, mostExpensiveSinglePlatform: mostExpensive,
            savingsVersusMostExpensive: savingsVsMost,
            productsUnavailableEverywhere: Array(Set(compareNotice)).sorted()
        )
    }

    private static func enumeratePlans(lines: [BasketLine], productsByID: [String: CatalogProduct], offers: [PriceOffer],
                                       platforms: [String], offersByID: [String: PriceOffer]) -> [IndexedPlan] {
        guard !platforms.isEmpty else { return [] }
        // Enumerating retailer subsets is bounded by supported-platform count, not basket size.
        let retailerNames = Array(Set(platforms)).sorted()
        guard retailerNames.count <= 12 else { return [] }
        var results: [IndexedPlan] = []
        for mask in 1..<(1 << retailerNames.count) {
            let selectedPlatforms = retailerNames.enumerated().compactMap { index, name in
                mask & (1 << index) == 0 ? nil : name
            }
            var assignments: [BasketRecommendationLine] = []
            var excluded: [String] = []
            for line in lines {
                guard let original = offersByID[line.offerID],
                      let product = productsByID[original.productID] else {
                    excluded.append("Unknown basket item")
                    continue
                }
                let matchingOffers = offers.filter {
                    $0.productID == product.id && $0.available && selectedPlatforms.contains($0.retailer)
                }
                guard let selected = matchingOffers.min(by: { lhs, rhs in
                    let leftNet = lhs.price - lhs.discount
                    let rightNet = rhs.price - rhs.discount
                    if leftNet != rightNet { return leftNet < rightNet }
                    if lhs.deliveryFee != rhs.deliveryFee { return lhs.deliveryFee < rhs.deliveryFee }
                    return lhs.retailer < rhs.retailer
                }) else {
                    excluded.append(product.name)
                    continue
                }
                assignments.append(BasketRecommendationLine(line: line, offer: selected))
            }
            guard !assignments.isEmpty else { continue }
            let actualPlatforms = Array(Set(assignments.map { $0.offer.retailer })).sorted()
            guard actualPlatforms.count == selectedPlatforms.count else { continue }
            let itemSubtotal = assignments.reduce(Decimal(0)) { $0 + $1.offer.price * Decimal($1.line.quantity) }
            let discounts = assignments.reduce(Decimal(0)) { $0 + $1.offer.discount * Decimal($1.line.quantity) }
            let fees = actualPlatforms.reduce(Decimal(0)) { $0 + platformDeliveryFee($1, offers: offers) }
            let serviceFees = actualPlatforms.reduce(Decimal(0)) { $0 + retailerPlatformFee($1, offers: offers) }
            let label: String
            if actualPlatforms.count == 1 { label = "\(actualPlatforms[0]) only" }
            else { label = "Split across \(actualPlatforms.count) platforms" }
            let plan = BasketPlan(name: label, total: itemSubtotal + fees + serviceFees - discounts,
                                  itemSubtotal: itemSubtotal, deliveryFees: fees, platformFees: serviceFees, discounts: discounts,
                                  assignments: assignments, platforms: actualPlatforms,
                                  excludedProducts: Array(Set(excluded)).sorted())
            results.append(IndexedPlan(plan: plan, usedPlatformCount: actualPlatforms.count))
        }
        return results
    }

    private nonisolated static func planIsCheaper(_ lhs: BasketPlan, _ rhs: BasketPlan) -> Bool {
        lhs.total == rhs.total ? lhs.name < rhs.name : lhs.total < rhs.total
    }

    private static func platformDeliveryFee(_ platform: String, offers: [PriceOffer]) -> Decimal {
        offers.first(where: { $0.retailer == platform })?.deliveryFee ?? 0
    }

    private static func retailerPlatformFee(_ platform: String, offers: [PriceOffer]) -> Decimal {
        offers.first(where: { $0.retailer == platform })?.platformFee ?? 0
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
                let simulatedTotal = basketTotal(for: changedLines, offersByID: offersByID, offers: offers)
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

    private static func basketTotal(for lines: [BasketLine], offersByID: [String: PriceOffer], offers: [PriceOffer]) -> Decimal {
        let selected = lines.compactMap { line -> (BasketLine, PriceOffer)? in
            guard let offer = offersByID[line.offerID] else { return nil }
            return (line, offer)
        }
        let items = selected.reduce(Decimal(0)) { $0 + ($1.1.price - $1.1.discount) * Decimal($1.0.quantity) }
        let retailers = Set(selected.map { $0.1.retailer })
        let delivery = retailers.reduce(Decimal(0)) { $0 + platformDeliveryFee($1, offers: offers) }
        let service = retailers.reduce(Decimal(0)) { $0 + retailerPlatformFee($1, offers: offers) }
        return items + delivery + service
    }
}
