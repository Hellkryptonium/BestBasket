import Observation

@MainActor @Observable
final class PersonalizationViewModel {
    private var preferencesRepository: any PreferencesRepository
    let brands: [String]
    let categories: [String]
    let platforms: [String]

    init(preferencesRepository: any PreferencesRepository, productRepository: any ProductRepository) {
        self.preferencesRepository = preferencesRepository
        self.brands = Array(Set(productRepository.products().map(\.brand))).sorted()
        self.categories = Array(Set(productRepository.products().map(\.category))).sorted()
        self.platforms = productRepository.platforms()
    }

    var preferences: ShoppingPreferences {
        get { preferencesRepository.preferences }
        set { preferencesRepository.preferences = newValue }
    }

    func resetPreferences() {
        preferencesRepository.preferences = .defaults
    }

    func toggleBrand(_ brand: String) {
        var updated = preferences
        let id = PreferenceIDs.make(from: brand)
        if updated.preferredBrandIDs.contains(id) { updated.preferredBrandIDs.remove(id) }
        else { updated.preferredBrandIDs.insert(id) }
        preferences = updated
    }

    func toggleCategory(_ category: String) {
        var updated = preferences
        let id = PreferenceIDs.make(from: category)
        if updated.preferredCategoryIDs.contains(id) { updated.preferredCategoryIDs.remove(id) }
        else { updated.preferredCategoryIDs.insert(id) }
        preferences = updated
    }

    func togglePlatform(_ platform: String) {
        var updated = preferences
        let id = PreferenceIDs.make(from: platform)
        if updated.preferredPlatformIDs.contains(id) { updated.preferredPlatformIDs.remove(id) }
        else { updated.preferredPlatformIDs.insert(id) }
        preferences = updated
    }

    func toggleSecondaryPriority(_ priority: ShoppingPriority) {
        var updated = preferences
        if updated.secondaryPriorities.contains(priority) { updated.secondaryPriorities.remove(priority) }
        else { updated.secondaryPriorities.insert(priority) }
        updated.secondaryPriorities.remove(updated.primaryPriority)
        preferences = updated
    }
}
