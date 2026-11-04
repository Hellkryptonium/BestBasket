import Foundation

struct RecipeMatch: Identifiable {
    let recipe: Recipe
    let availableIngredients: [RecipeIngredient]
    let missingIngredients: [RecipeIngredient]
    var id: String { recipe.id }
    var matchPercent: Int {
        guard !recipe.ingredients.isEmpty else { return 0 }
        return Int((Double(availableIngredients.count) / Double(recipe.ingredients.count) * 100).rounded())
    }
}

enum RecipeCatalogService {
    static let recipes: [Recipe] = [
        Recipe(id: "paneer-bhurji", name: "Paneer Bhurji", description: "A quick, warmly spiced paneer scramble with tomatoes and onions.", cuisine: "Indian", mealType: "Dinner", preparationMinutes: 10, cookingMinutes: 15, difficulty: .easy, servings: 2, ingredients: [
            .init(name: "Paneer", quantity: 200, unit: "g", aliases: ["cottage cheese"], productID: "paneer"),
            .init(name: "Tomatoes", quantity: 2, unit: "pieces", aliases: ["tomato"], productID: "tomatoes"),
            .init(name: "Onions", quantity: 1, unit: "piece", aliases: ["onion"], productID: "onions"),
            .init(name: "Milk", quantity: 2, unit: "tbsp", productID: "amul-milk", purchasePacksPerBaseRecipe: 0)
        ], instructions: ["Crumble the paneer and chop the tomatoes and onion.", "Soften the onion in a pan, then cook the tomatoes with spices.", "Fold in the paneer and a splash of milk; cook for 3 minutes."], systemImage: "frying.pan"),
        Recipe(id: "tomato-egg-toast", name: "Tomato Egg Toast", description: "Crisp toast topped with soft eggs and a simple tomato mix.", cuisine: "Fusion", mealType: "Breakfast", preparationMinutes: 8, cookingMinutes: 12, difficulty: .easy, servings: 2, ingredients: [
            .init(name: "Eggs", quantity: 4, unit: "pieces", aliases: ["egg"], productID: "eggs"),
            .init(name: "Bread", quantity: 4, unit: "slices", aliases: ["toast"], productID: "bread"),
            .init(name: "Tomatoes", quantity: 1, unit: "piece", aliases: ["tomato"], productID: "tomatoes"),
            .init(name: "Onions", quantity: 0.5, unit: "piece", aliases: ["onion"], productID: "onions")
        ], instructions: ["Toast the bread until crisp.", "Cook chopped tomatoes and onion until soft.", "Scramble or fry the eggs and serve over the toast with the tomato mix."], systemImage: "sun.max.fill"),
        Recipe(id: "masala-oats", name: "Savory Masala Oats", description: "A fast one-pan bowl with oats and everyday vegetables.", cuisine: "Indian", mealType: "Breakfast", preparationMinutes: 5, cookingMinutes: 10, difficulty: .easy, servings: 2, ingredients: [
            .init(name: "Oats", quantity: 1, unit: "cup", productID: "oats"),
            .init(name: "Tomatoes", quantity: 1, unit: "piece", aliases: ["tomato"], productID: "tomatoes"),
            .init(name: "Onions", quantity: 0.5, unit: "piece", aliases: ["onion"], productID: "onions"),
            .init(name: "Milk", quantity: 0.5, unit: "cup", productID: "amul-milk")
        ], instructions: ["Toast the oats in a dry pan for 2 minutes.", "Cook onion and tomato with your preferred spices.", "Add oats and water or milk; simmer until soft."], systemImage: "leaf.fill"),
        Recipe(id: "atta-flatbread", name: "Quick Atta Flatbread", description: "Simple pan-cooked flatbreads for a weeknight meal.", cuisine: "Indian", mealType: "Dinner", preparationMinutes: 15, cookingMinutes: 15, difficulty: .medium, servings: 4, ingredients: [
            .init(name: "Atta", quantity: 2, unit: "cups", aliases: ["whole wheat flour"], productID: "atta"),
            .init(name: "Milk", quantity: 0.5, unit: "cup", productID: "amul-milk"),
            .init(name: "Salt", quantity: 0.5, unit: "tsp", aliases: ["tata salt"], productID: "tata-salt")
        ], instructions: ["Mix atta, a pinch of salt and enough water to make a soft dough.", "Rest for 10 minutes, then divide and roll into flat rounds.", "Cook each round on a hot pan, turning until lightly browned."], systemImage: "takeoutbag.and.cup.and.straw.fill")
    ]

    static let pantryChoices = ["Paneer", "Tomatoes", "Onions", "Milk", "Eggs", "Bread", "Oats", "Atta", "Salt"]

    static func match(_ recipe: Recipe, available: Set<String>) -> RecipeMatch {
        let normalized = Set(available.map(normalize))
        let present = recipe.ingredients.filter { ingredient in
            ([ingredient.name] + ingredient.aliases).map(normalize).contains(where: normalized.contains)
        }
        let presentIDs = Set(present.map(\.id))
        return RecipeMatch(recipe: recipe, availableIngredients: present,
                           missingIngredients: recipe.ingredients.filter { !presentIDs.contains($0.id) })
    }

    nonisolated static func normalize(_ value: String) -> String {
        let clean = value.lowercased().folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return clean.hasSuffix("s") ? String(clean.dropLast()) : clean
    }
}
