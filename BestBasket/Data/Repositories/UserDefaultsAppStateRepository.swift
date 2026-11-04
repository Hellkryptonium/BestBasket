import Foundation
import Observation

@MainActor @Observable
final class UserDefaultsAppStateRepository: PersistentAppStateRepository {
    private let store: UserDefaults
    private let storageKey: String

    var appState: AppPersistentState {
        didSet { persist() }
    }

    init(store: UserDefaults, storageKey: String = "bestbasket.app-state.v1") {
        self.store = store
        self.storageKey = storageKey
        if let data = store.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppPersistentState.self, from: data) {
            self.appState = decoded
        } else {
            self.appState = AppPersistentState()
            if store.data(forKey: storageKey) != nil { store.removeObject(forKey: storageKey) }
        }
    }

    func lines() -> [BasketLine] { appState.basketLines }

    func save(_ lines: [BasketLine]) {
        var updated = appState
        updated.basketLines = lines
        appState = updated
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(appState) else { return }
        store.set(data, forKey: storageKey)
    }
}
