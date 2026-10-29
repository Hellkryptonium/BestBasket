import Foundation

enum ProductSort: String, CaseIterable, Identifiable {
    case relevance = "Relevant"
    case price = "Lowest price"
    case rating = "Top rated"
    case discount = "Discount"
    var id: String { rawValue }
}

struct BasketLine: Identifiable, Hashable {
    let id: String
    var offerID: String
    var quantity: Int
}

struct BasketRecommendationLine: Identifiable {
    let line: BasketLine
    let offer: PriceOffer
    var id: String { line.id }
}

struct TrackedItem: Identifiable, Hashable {
    let id: String
    var targetPrice: Decimal
}

struct ShoppingPreferences: Equatable {
    var preferredBrandIDs: Set<String> = []
    var preferredCategoryIDs: Set<String> = [PreferenceIDs.make(from: "Dairy"), PreferenceIDs.make(from: "Breakfast")]
    var preferredPlatformIDs: Set<String> = [PreferenceIDs.make(from: "Blinkit"), PreferenceIDs.make(from: "Zepto")]
    var primaryPriority: ShoppingPriority = .bestOverallValue
    var secondaryPriorities: Set<ShoppingPriority> = []
    var tripBudget: Decimal = 1500
    var monthlyBudget: Decimal?
    var householdSize: Int = 2
    var shoppingFrequency: ShoppingFrequency = .weekly
    var personalizationEnabled = true
    var searchPersonalizationEnabled = true
    var setupCompleted = false

    static var defaults: ShoppingPreferences { ShoppingPreferences() }
}

enum ShoppingPriority: String, CaseIterable, Codable, Identifiable {
    case lowestTotalPrice
    case bestOverallValue
    case preferredBrands
    case highestRated
    case fastestDelivery

    var id: String { rawValue }
    var title: String {
        switch self {
        case .lowestTotalPrice: "Lowest total price"
        case .bestOverallValue: "Best overall value"
        case .preferredBrands: "Preferred brands"
        case .highestRated: "Highest rated"
        case .fastestDelivery: "Fastest delivery"
        }
    }
}

enum ShoppingFrequency: String, CaseIterable, Codable, Identifiable {
    case severalTimesWeekly
    case weekly
    case biweekly
    case monthly

    var id: String { rawValue }
    var title: String {
        switch self {
        case .severalTimesWeekly: "Several times a week"
        case .weekly: "Weekly"
        case .biweekly: "Every two weeks"
        case .monthly: "Monthly"
        }
    }
}

extension ShoppingPreferences: Codable {
    private enum CodingKeys: String, CodingKey {
        case preferredBrandIDs, preferredCategoryIDs, preferredPlatformIDs
        case primaryPriority, secondaryPriorities, tripBudget, monthlyBudget
        case householdSize, shoppingFrequency, personalizationEnabled
        case searchPersonalizationEnabled, setupCompleted
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        preferredBrandIDs = try values.decodeIfPresent(Set<String>.self, forKey: .preferredBrandIDs) ?? []
        preferredCategoryIDs = try values.decodeIfPresent(Set<String>.self, forKey: .preferredCategoryIDs)
            ?? Self.defaults.preferredCategoryIDs
        preferredPlatformIDs = try values.decodeIfPresent(Set<String>.self, forKey: .preferredPlatformIDs)
            ?? Self.defaults.preferredPlatformIDs
        primaryPriority = try values.decodeIfPresent(ShoppingPriority.self, forKey: .primaryPriority) ?? .bestOverallValue
        secondaryPriorities = try values.decodeIfPresent(Set<ShoppingPriority>.self, forKey: .secondaryPriorities) ?? []
        tripBudget = max(0, try values.decodeIfPresent(Decimal.self, forKey: .tripBudget) ?? 1500)
        monthlyBudget = try values.decodeIfPresent(Decimal.self, forKey: .monthlyBudget).map { max(0, $0) }
        householdSize = min(20, max(1, try values.decodeIfPresent(Int.self, forKey: .householdSize) ?? 2))
        shoppingFrequency = try values.decodeIfPresent(ShoppingFrequency.self, forKey: .shoppingFrequency) ?? .weekly
        personalizationEnabled = try values.decodeIfPresent(Bool.self, forKey: .personalizationEnabled) ?? true
        searchPersonalizationEnabled = try values.decodeIfPresent(Bool.self, forKey: .searchPersonalizationEnabled) ?? true
        setupCompleted = try values.decodeIfPresent(Bool.self, forKey: .setupCompleted) ?? false
    }
}

enum PreferenceIDs {
    static func make(from displayName: String) -> String {
        displayName.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case search = "Search"
    case basket = "Basket"
    case tracking = "Tracking"
    case profile = "Profile"

    var id: String { rawValue }
}
