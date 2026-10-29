import Foundation
import Observation

@MainActor @Observable
final class SearchViewModel {
    private var preferencesRepository: any PreferencesRepository
    private let recommendationService: RecommendationService
    private let offerRankingService: OfferRankingService
    let products: [CatalogProduct]
    private let offersByProductID: [String: [PriceOffer]]
    let platforms: [String]
    var recentSearches = ["oats", "Amul milk"]
    var query = ""
    var selectedCategory: String?
    var selectedBrand: String?
    var selectedPlatform: String?
    var maximumPrice: Decimal?
    var minimumRating = 0.0
    var inStockOnly = false
    var sort: ProductSort = .relevance

    init(productRepository: any ProductRepository, preferencesRepository: any PreferencesRepository,
         recommendationService: RecommendationService, offerRankingService: OfferRankingService) {
        self.preferencesRepository = preferencesRepository
        self.recommendationService = recommendationService
        self.offerRankingService = offerRankingService
        self.products = productRepository.products()
        self.offersByProductID = Dictionary(grouping: productRepository.allOffers(), by: \.productID)
        self.platforms = productRepository.platforms()
    }

    var categories: [String] { Array(Set(products.map(\.category))).sorted() }
    var brands: [String] { Array(Set(products.map(\.brand))).sorted() }
    var activeFilterCount: Int {
        [selectedCategory != nil, selectedBrand != nil, selectedPlatform != nil,
         maximumPrice != nil, minimumRating > 0, inStockOnly].filter { $0 }.count
    }
    var searchPersonalizationEnabled: Bool {
        get {
            let preferences = preferencesRepository.preferences
            return preferences.personalizationEnabled && preferences.searchPersonalizationEnabled
        }
        set {
            var preferences = preferencesRepository.preferences
            preferences.searchPersonalizationEnabled = newValue
            preferencesRepository.preferences = preferences
        }
    }

    func offers(for product: CatalogProduct) -> [PriceOffer] { offersByProductID[product.id] ?? [] }
    func displayedOffer(for product: CatalogProduct) -> PriceOffer? {
        if let selectedPlatform,
           let offer = offers(for: product).first(where: { $0.retailer == selectedPlatform && $0.available }) {
            return offer
        }
        return offerRankingService.rank(product: product, offers: offers(for: product),
                                        preferences: preferencesRepository.preferences).first?.offer
    }
    func personalizationReason(for product: CatalogProduct) -> String? {
        guard searchPersonalizationEnabled else { return nil }
        return recommendationService.reason(for: product, offersByProductID: offersByProductID,
                                            preferences: preferencesRepository.preferences)
    }

    func searchResults(query input: String? = nil) -> [CatalogProduct] {
        let term = normalize(input ?? query)
        var results = products.filter { product in
            let searchableText = normalize("\(product.name) \(product.brand) \(product.packSize) \(product.category)")
            let matchesText = term.isEmpty || searchableText.contains(term)
                || term.split(separator: " ").allSatisfy { searchableText.contains($0) }
            let matchesCategory = selectedCategory == nil || selectedCategory == product.category
            let matchesBrand = selectedBrand == nil || selectedBrand == product.brand
            let offers = offers(for: product).filter { selectedPlatform == nil || $0.retailer == selectedPlatform }
            let availableOffers = offers.filter(\.available)
            let matchesPrice = maximumPrice.map { limit in availableOffers.contains { $0.effectivePrice <= limit } } ?? true
            let matchesAvailability = !inStockOnly || !availableOffers.isEmpty
            return matchesText && matchesCategory && matchesBrand && matchesPrice && matchesAvailability
                && product.rating >= minimumRating && (selectedPlatform == nil || !availableOffers.isEmpty)
        }
        switch sort {
        case .relevance:
            let personalizedOrder = searchPersonalizationEnabled
                ? Dictionary(uniqueKeysWithValues: recommendationService
                    .rank(products: products, offersByProductID: offersByProductID,
                          preferences: preferencesRepository.preferences)
                    .enumerated().map { ($0.element.id, $0.offset) })
                : [:]
            results.sort { lhs, rhs in
                let leftRelevance = relevance(lhs, term: term)
                let rightRelevance = relevance(rhs, term: term)
                if leftRelevance != rightRelevance { return leftRelevance > rightRelevance }
                let leftPreference = personalizedOrder[lhs.id] ?? Int.max
                let rightPreference = personalizedOrder[rhs.id] ?? Int.max
                return leftPreference == rightPreference ? lhs.id < rhs.id : leftPreference < rightPreference
            }
        case .price:
            results.sort { comparePrice($0, $1) }
        case .rating:
            results.sort { $0.rating == $1.rating ? $0.id < $1.id : $0.rating > $1.rating }
        case .discount:
            results.sort { compareDiscount($0, $1) }
        }
        return results
    }

    func suggestions(for input: String) -> [CatalogProduct] {
        let term = normalize(input)
        guard !term.isEmpty else { return [] }
        return products.filter { normalize("\($0.name) \($0.brand)").contains(term) }.prefix(5).map { $0 }
    }

    func recordSearch(_ value: String) {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(value) == .orderedSame }
        recentSearches.insert(value, at: 0)
        recentSearches = Array(recentSearches.prefix(6))
    }

    func resetFilters() {
        selectedCategory = nil; selectedBrand = nil; selectedPlatform = nil
        maximumPrice = nil; minimumRating = 0; inStockOnly = false; sort = .relevance
    }

    private func bestOffer(for product: CatalogProduct) -> PriceOffer? {
        offers(for: product).filter(\.available).min { $0.effectivePrice < $1.effectivePrice }
    }
    private func normalize(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    private func relevance(_ product: CatalogProduct, term: String) -> Int {
        let name = normalize(product.name), brand = normalize(product.brand)
        if term.isEmpty { return 0 }
        if name == term { return 5 }
        if name.hasPrefix(term) { return 4 }
        if brand == term || brand.hasPrefix(term) { return 3 }
        if name.contains(term) { return 2 }
        return 1
    }
    private func comparePrice(_ lhs: CatalogProduct, _ rhs: CatalogProduct) -> Bool {
        let left = bestOffer(for: lhs)?.effectivePrice ?? Decimal.greatestFiniteMagnitude
        let right = bestOffer(for: rhs)?.effectivePrice ?? Decimal.greatestFiniteMagnitude
        return left == right ? lhs.id < rhs.id : left < right
    }
    private func compareDiscount(_ lhs: CatalogProduct, _ rhs: CatalogProduct) -> Bool {
        let left = discount(for: lhs), right = discount(for: rhs)
        return left == right ? lhs.id < rhs.id : left > right
    }
    private func discount(for product: CatalogProduct) -> Decimal {
        offers(for: product).map { offer in offer.originalPrice.map { $0 - offer.price } ?? 0 }.max() ?? 0
    }
}
