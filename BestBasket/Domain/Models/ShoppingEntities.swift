import Foundation

enum ProductSort: String, CaseIterable, Identifiable {
    case relevance = "Relevant"
    case price = "Lowest price"
    case rating = "Top rated"
    case discount = "Discount"
    var id: String { rawValue }
}

struct BasketLine: Identifiable, Hashable, Codable {
    let id: String
    var offerID: String
    var quantity: Int
}

struct BasketRecommendationLine: Identifiable {
    let line: BasketLine
    let offer: PriceOffer
    var id: String { line.id }
}

struct GroceryListItem: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var productID: String
    var quantity: Int
    var isChecked: Bool = false

    private enum CodingKeys: String, CodingKey { case id, productID, quantity, isChecked }
    init(id: String = UUID().uuidString, productID: String, quantity: Int, isChecked: Bool = false) {
        self.id = id; self.productID = productID; self.quantity = quantity; self.isChecked = isChecked
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        productID = try values.decode(String.self, forKey: .productID)
        quantity = try values.decode(Int.self, forKey: .quantity)
        isChecked = try values.decodeIfPresent(Bool.self, forKey: .isChecked) ?? false
    }
}

struct SavedGroceryList: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var items: [GroceryListItem]
    var createdAt: Date = .now
    var updatedAt: Date = .now
}

struct PreviousBasketSnapshot: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var items: [GroceryListItem]
    var total: Decimal
    var savedAt: Date = .now
}

struct PurchaseHistoryEntry: Identifiable, Hashable, Codable {
    var id: String
    var productID: String
    var quantity: Int
    var unitPrice: Decimal
    var platform: String
    var purchaseDate: Date
}

enum RefillInterval: Codable, Hashable {
    case daily
    case weekly
    case custom(days: Int)

    var days: Int {
        switch self {
        case .daily: 1
        case .weekly: 7
        case .custom(let days): min(365, max(1, days))
        }
    }

    var title: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .custom(let days): "Every \(days) days"
        }
    }
}

struct RefillReminder: Identifiable, Hashable, Codable {
    var id: String
    var productID: String
    var interval: RefillInterval
    var lastPurchaseAt: Date
    var nextReminderAt: Date
    var enabled: Bool
}

enum BasketDealKind: String, Codable, Hashable {
    case betterOffer
    case offerUnavailable
}

struct BasketDealNotification: Identifiable, Hashable, Codable {
    var id: String
    var productID: String
    var originalOfferID: String
    var suggestedOfferID: String
    var estimatedSavings: Decimal
    var kind: BasketDealKind
    var createdAt: Date
    var readAt: Date?

    init(id: String, productID: String, originalOfferID: String, suggestedOfferID: String,
         estimatedSavings: Decimal, kind: BasketDealKind = .betterOffer,
         createdAt: Date, readAt: Date?) {
        self.id = id
        self.productID = productID
        self.originalOfferID = originalOfferID
        self.suggestedOfferID = suggestedOfferID
        self.estimatedSavings = estimatedSavings
        self.kind = kind
        self.createdAt = createdAt
        self.readAt = readAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, productID, originalOfferID, suggestedOfferID, estimatedSavings, kind, createdAt, readAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productID = try container.decode(String.self, forKey: .productID)
        originalOfferID = try container.decode(String.self, forKey: .originalOfferID)
        suggestedOfferID = try container.decode(String.self, forKey: .suggestedOfferID)
        estimatedSavings = try container.decode(Decimal.self, forKey: .estimatedSavings)
        kind = try container.decodeIfPresent(BasketDealKind.self, forKey: .kind) ?? .betterOffer
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
    }
}

struct RecipeIngredient: Identifiable, Hashable, Codable {
    var id: String { name }
    var name: String
    var quantity: Decimal
    var unit: String
    var aliases: [String] = []
    var productID: String?
    var purchasePacksPerBaseRecipe: Decimal = 1
}

enum RecipeDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy, medium, hard
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Recipe: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var description: String
    var cuisine: String
    var mealType: String
    var preparationMinutes: Int
    var cookingMinutes: Int
    var difficulty: RecipeDifficulty
    var servings: Int
    var ingredients: [RecipeIngredient]
    var instructions: [String]
    var systemImage: String
}

struct AppPersistentState: Codable {
    var basketLines: [BasketLine] = []
    var savedLists: [SavedGroceryList] = []
    var previousBaskets: [PreviousBasketSnapshot] = []
    var reminders: [RefillReminder] = []
    var dealNotifications: [BasketDealNotification] = []
    var basketWatchEnabled = true
    var availablePantryIngredients: Set<String> = []
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
    case lists = "Lists"
    case essentials = "Essentials"
    case basket = "Basket"
    case tracking = "Tracking"
    case profile = "Profile"

    var id: String { rawValue }
}
