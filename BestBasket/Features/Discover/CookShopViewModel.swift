import Foundation
import Observation

@MainActor @Observable
final class CookShopViewModel {
    private let basketRepository: any BasketRepository
    private var appStateRepository: PersistentAppStateRepository
    private let products: [CatalogProduct]
    private let offers: [PriceOffer]
    let groceryLists: GroceryListsViewModel
    var cuisineFilter = "All"
    var mealFilter = "All"
    var maximumCookingMinutes = 120
    var difficultyFilter = "All"
    var ingredientSearch = ""

    init(productRepository: any ProductRepository, basketRepository: any BasketRepository,
         appStateRepository: PersistentAppStateRepository, groceryLists: GroceryListsViewModel) {
        self.basketRepository = basketRepository
        self.appStateRepository = appStateRepository
        self.groceryLists = groceryLists
        self.products = productRepository.products()
        self.offers = productRepository.allOffers()
    }

    var recipes: [Recipe] { RecipeCatalogService.recipes }
    var cuisines: [String] { ["All"] + Array(Set(recipes.map(\.cuisine)).sorted()) }
    var meals: [String] { ["All"] + Array(Set(recipes.map(\.mealType)).sorted()) }
    var availableIngredients: Set<String> { appStateRepository.appState.availablePantryIngredients }

    func filteredRecipes() -> [RecipeMatch] {
        recipes.map { RecipeCatalogService.match($0, available: availableIngredients) }
            .filter { match in
                (cuisineFilter == "All" || match.recipe.cuisine == cuisineFilter)
                    && (mealFilter == "All" || match.recipe.mealType == mealFilter)
                    && match.recipe.preparationMinutes + match.recipe.cookingMinutes <= maximumCookingMinutes
                    && (difficultyFilter == "All" || match.recipe.difficulty.title == difficultyFilter)
                    && (ingredientSearch.isEmpty || match.recipe.ingredients.contains {
                        ([$0.name] + $0.aliases).contains { RecipeCatalogService.normalize($0).contains(RecipeCatalogService.normalize(ingredientSearch)) }
                    })
            }
            .sorted { $0.availableIngredients.count == $1.availableIngredients.count
                ? $0.missingIngredients.count < $1.missingIngredients.count
                : $0.availableIngredients.count > $1.availableIngredients.count }
    }

    func toggleIngredient(_ ingredient: String) {
        var state = appStateRepository.appState
        let key = RecipeCatalogService.normalize(ingredient)
        if let existing = state.availablePantryIngredients.first(where: { RecipeCatalogService.normalize($0) == key }) {
            state.availablePantryIngredients.remove(existing)
        } else {
            state.availablePantryIngredients.insert(ingredient)
        }
        appStateRepository.appState = state
    }

    func setIngredientAvailable(_ ingredient: String) {
        let trimmed = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var state = appStateRepository.appState
        state.availablePantryIngredients.insert(trimmed)
        appStateRepository.appState = state
    }

    func isAvailable(_ ingredient: String) -> Bool {
        let key = RecipeCatalogService.normalize(ingredient)
        return availableIngredients.contains { RecipeCatalogService.normalize($0) == key }
    }

    func product(for ingredient: RecipeIngredient) -> CatalogProduct? {
        guard let id = ingredient.productID else { return nil }
        return products.first { $0.id == id }
    }

    @discardableResult
    func addMissingIngredients(_ ingredients: [RecipeIngredient], servings: Int, baseServings: Int) -> Int {
        var added = 0
        for ingredient in ingredients {
            guard let productID = ingredient.productID,
                  let product = products.first(where: { $0.id == productID }),
                  let offer = offers.filter({ $0.productID == product.id && $0.available })
                    .min(by: { $0.effectivePrice < $1.effectivePrice }) else { continue }
            let exactPacks = ingredient.purchasePacksPerBaseRecipe * Decimal(servings) / Decimal(max(1, baseServings))
            let quantity = max(1, Int(ceil(NSDecimalNumber(decimal: exactPacks).doubleValue)))
            var lines = basketRepository.lines()
            if let index = lines.firstIndex(where: { line in
                offers.first(where: { $0.id == line.offerID })?.productID == product.id
            }) {
                lines[index].quantity += quantity
            } else {
                lines.append(BasketLine(id: UUID().uuidString, offerID: offer.id, quantity: quantity))
            }
            basketRepository.save(lines)
            added += 1
        }
        return added
    }

    @discardableResult
    func addMissingIngredients(_ ingredients: [RecipeIngredient], servings: Int, baseServings: Int, to list: SavedGroceryList) -> Int {
        var added = 0
        for ingredient in ingredients {
            guard let productID = ingredient.productID else { continue }
            let packs = ingredient.purchasePacksPerBaseRecipe * Decimal(servings) / Decimal(max(1, baseServings))
            let quantity = max(1, Int(ceil(NSDecimalNumber(decimal: packs).doubleValue)))
            groceryLists.add(productID, quantity: quantity, to: list); added += 1
        }
        return added
    }
}
