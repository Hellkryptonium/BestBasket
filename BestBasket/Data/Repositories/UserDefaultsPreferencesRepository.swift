import Foundation
import Observation

@MainActor @Observable
final class UserDefaultsPreferencesRepository: PreferencesRepository {
    private let store: UserDefaults
    private let storageKey: String

    var preferences: ShoppingPreferences {
        didSet { persist() }
    }

    init(store: UserDefaults, storageKey: String = "bestbasket.shopping-preferences.v1") {
        self.store = store
        self.storageKey = storageKey
        if let data = store.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(ShoppingPreferences.self, from: data) {
            self.preferences = saved
        } else {
            self.preferences = .defaults
        }
    }

    func reset() {
        preferences = .defaults
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        store.set(data, forKey: storageKey)
    }
}
