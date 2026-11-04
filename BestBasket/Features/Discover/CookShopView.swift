import SwiftUI

struct CookShopView: View {
    @Bindable var model: CookShopViewModel
    @State private var selectedRecipe: RecipeMatch?
    @State private var customIngredient = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ingredientPicker
                    filters
                    let matches = model.filteredRecipes()
                    if matches.isEmpty {
                        ContentUnavailableView("No recipes match", systemImage: "fork.knife",
                                               description: Text("Change a filter or try another ingredient."))
                    } else {
                        ForEach(matches) { match in
                            RecipeCard(match: match) { selectedRecipe = match }
                        }
                    }
                    Text("Recipes and ingredient matches are sample content. Your basket is never treated as your pantry.")
                        .font(.caption2).foregroundStyle(AppPalette.muted)
                }
                .padding(18)
            }
            .background(AppPalette.oat)
            .navigationTitle("Cook & Shop")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedRecipe) { match in
                RecipeDetailSheet(match: match, model: model)
            }
        }
    }

    private var ingredientPicker: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(title: "What do you have?", subtitle: "Select ingredients explicitly; the basket is not your pantry")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(RecipeCatalogService.pantryChoices, id: \.self) { ingredient in
                    let selected = model.isAvailable(ingredient)
                    Button { model.toggleIngredient(ingredient) } label: {
                        Label(ingredient, systemImage: selected ? "checkmark.circle.fill" : "circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selected ? .white : AppPalette.ink)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(selected ? AppPalette.cobalt : .white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            HStack {
                TextField("Add an ingredient you have", text: $customIngredient)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                Button("Add") {
                    model.setIngredientAvailable(customIngredient)
                    customIngredient = ""
                }
                .disabled(customIngredient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private var filters: some View {
        VStack(spacing: 10) {
            TextField("Filter by ingredient", text: $model.ingredientSearch)
                .padding(11).background(.white, in: RoundedRectangle(cornerRadius: 12))
            HStack {
                Picker("Cuisine", selection: $model.cuisineFilter) {
                    ForEach(model.cuisines, id: \.self) { Text($0).tag($0) }
                }
                Picker("Meal", selection: $model.mealFilter) {
                    ForEach(model.meals, id: \.self) { Text($0).tag($0) }
                }
            }
            HStack {
                Picker("Difficulty", selection: $model.difficultyFilter) {
                    ForEach(["All"] + RecipeDifficulty.allCases.map(\.title), id: \.self) { Text($0).tag($0) }
                }
                Picker("Total time", selection: $model.maximumCookingMinutes) {
                    Text("Any time").tag(120)
                    Text("Under 15 min").tag(15)
                    Text("Under 30 min").tag(30)
                }
            }
        }
        .pickerStyle(.menu)
    }
}

private struct RecipeCard: View {
    let match: RecipeMatch
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: match.recipe.systemImage)
                    .font(.system(size: 28, weight: .medium)).foregroundStyle(AppPalette.cobalt)
                    .frame(width: 72, height: 72).background(AppPalette.oat, in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.recipe.name).font(.subheadline.weight(.bold)).foregroundStyle(AppPalette.ink)
                    Text("\(match.recipe.cuisine) · \(match.recipe.mealType) · \(match.recipe.cookingMinutes) min · \(match.recipe.difficulty.title)")
                        .font(.caption2).foregroundStyle(AppPalette.muted)
                    Text("\(match.availableIngredients.count) available · \(match.missingIngredients.count) needed")
                        .font(.caption.weight(.semibold)).foregroundStyle(AppPalette.pine)
                }
                Spacer(minLength: 4)
                Text("\(match.matchPercent)%")
                    .font(.caption.weight(.bold)).foregroundStyle(AppPalette.cobalt)
            }
            .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct RecipeDetailSheet: View {
    let match: RecipeMatch
    @Bindable var model: CookShopViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var servings = 2
    @State private var selectedMissing: Set<String> = []
    @State private var showAdded = false
    @State private var addedCount = 0

    private var recipe: Recipe { match.recipe }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    Image(systemName: recipe.systemImage)
                        .font(.system(size: 48)).foregroundStyle(AppPalette.cobalt)
                        .frame(maxWidth: .infinity).frame(height: 140)
                        .background(AppPalette.blush, in: RoundedRectangle(cornerRadius: 22))
                    Text(recipe.description).font(.subheadline).foregroundStyle(AppPalette.muted)
                    Text("\(recipe.cuisine) · \(recipe.mealType) · Prep \(recipe.preparationMinutes) min · Cook \(recipe.cookingMinutes) min · \(recipe.difficulty.title)")
                        .font(.caption).foregroundStyle(AppPalette.muted)
                    Stepper("Serves \(servings)", value: $servings, in: 1...12)
                        .font(.subheadline.weight(.semibold))
                    SectionTitle(title: "Ingredients", subtitle: "Scaled to \(servings) servings")
                    ForEach(recipe.ingredients) { ingredient in
                        ingredientRow(ingredient)
                    }
                    SectionTitle(title: "Method")
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)").font(.caption.bold()).foregroundStyle(.white)
                                .frame(width: 25, height: 25).background(AppPalette.cobalt, in: Circle())
                            Text(instruction).font(.subheadline).foregroundStyle(AppPalette.ink)
                        }
                    }
                    Button {
                        addedCount = model.addMissingIngredients(selectedIngredients, servings: servings, baseServings: recipe.servings)
                        showAdded = true
                    } label: {
                        Label("Add selected missing ingredients", systemImage: "basket.badge.plus")
                            .frame(maxWidth: .infinity).padding(14).font(.subheadline.weight(.bold))
                    }
                    .buttonStyle(.borderedProminent).tint(AppPalette.cobalt)
                    .disabled(selectedIngredients.isEmpty)
                    Menu {
                        ForEach(model.groceryLists.lists) { list in
                            Button(list.name) {
                                addedCount = model.addMissingIngredients(selectedIngredients, servings: servings, baseServings: recipe.servings, to: list)
                                showAdded = true
                            }
                        }
                        Button("Create recipe list") {
                            _ = model.groceryLists.create("\(recipe.name) ingredients")
                            if let list = model.groceryLists.lists.first {
                                addedCount = model.addMissingIngredients(selectedIngredients, servings: servings, baseServings: recipe.servings, to: list)
                            }
                            showAdded = true
                        }
                    } label: {
                        Label("Add selected to Grocery List", systemImage: "text.badge.plus")
                            .frame(maxWidth: .infinity).padding(14).font(.subheadline.weight(.bold))
                    }.buttonStyle(.bordered)
                    Text("Matched catalog products are added using a sample offer and merged into existing basket lines. Unmatched ingredients are skipped.")
                        .font(.caption2).foregroundStyle(AppPalette.muted)
                }
                .padding(18)
            }
            .background(AppPalette.oat)
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear {
                servings = recipe.servings
                selectedMissing = Set(match.missingIngredients.map(\.id))
            }
            .alert("Ingredients added", isPresented: $showAdded) {
                Button("OK") { dismiss() }
            } message: {
                Text("Added \(addedCount) matched grocery product(s) to your existing basket.")
            }
        }
    }

    private var selectedIngredients: [RecipeIngredient] {
        match.missingIngredients.filter { selectedMissing.contains($0.id) && model.product(for: $0) != nil }
    }

    @ViewBuilder
    private func ingredientRow(_ ingredient: RecipeIngredient) -> some View {
        let required = ingredient.quantity * Decimal(servings) / Decimal(max(1, recipe.servings))
        let amount = NSDecimalNumber(decimal: required).stringValue
        let isAvailable = match.availableIngredients.contains(where: { $0.id == ingredient.id })
        let product = model.product(for: ingredient)
        HStack(spacing: 9) {
            if isAvailable {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppPalette.pine)
            } else if product != nil {
                Button {
                    if selectedMissing.contains(ingredient.id) { selectedMissing.remove(ingredient.id) }
                    else { selectedMissing.insert(ingredient.id) }
                } label: {
                    Image(systemName: selectedMissing.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(AppPalette.cobalt)
                }
                .accessibilityLabel("Select \(ingredient.name) to add")
            } else {
                Image(systemName: "exclamationmark.circle").foregroundStyle(AppPalette.tomato)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(amount) \(ingredient.unit) \(ingredient.name)").font(.subheadline)
                Text(isAvailable ? "You marked this as available" : (product.map { "Missing · matched to \($0.name)" } ?? "Missing · no confident catalog match"))
                    .font(.caption2).foregroundStyle(isAvailable ? AppPalette.pine : AppPalette.muted)
            }
            Spacer()
        }
        .padding(10).background(.white, in: RoundedRectangle(cornerRadius: 12))
    }
}
