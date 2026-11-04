import Foundation

struct BasketDeal: Identifiable {
    let line: BasketLine
    let product: CatalogProduct
    let currentOffer: PriceOffer
    let suggestedOffer: PriceOffer
    let savings: Decimal
    let kind: BasketDealKind
    var id: String { "\(line.id)-\(suggestedOffer.id)" }
}

enum BasketWatchService {
    static func deals(lines: [BasketLine], products: [CatalogProduct], offers: [PriceOffer]) -> [BasketDeal] {
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        var result: [BasketDeal] = []
        for line in lines {
            guard let current = offers.first(where: { $0.id == line.offerID }),
                  let product = productsByID[current.productID] else { continue }
            let bestAlternative = offers
                .filter { $0.productID == product.id && $0.available && $0.id != current.id }
                .min { $0.effectivePrice == $1.effectivePrice ? $0.retailer < $1.retailer : $0.effectivePrice < $1.effectivePrice }
            if let alternative = bestAlternative {
                let difference = current.effectivePrice - alternative.effectivePrice
                if current.available && difference < max(5, current.effectivePrice / 20) { continue }
                result.append(BasketDeal(line: line, product: product, currentOffer: current,
                                         suggestedOffer: alternative,
                                         savings: max(0, difference) * Decimal(line.quantity),
                                         kind: current.available ? .betterOffer : .offerUnavailable))
            }
        }
        return result.sorted { $0.savings == $1.savings ? $0.product.name < $1.product.name : $0.savings > $1.savings }
    }
}
