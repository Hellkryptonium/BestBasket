import Foundation
import Observation

@MainActor @Observable
final class GroceryListsViewModel {
    private let state: UserDefaultsAppStateRepository
    private let products: any ProductRepository
    private let basket: any BasketRepository
    init(state: UserDefaultsAppStateRepository, products: any ProductRepository, basket: any BasketRepository) {
        self.state = state; self.products = products; self.basket = basket
    }
    var lists: [SavedGroceryList] { state.appState.savedLists }
    var listCount: Int { lists.count }
    func productName(_ id: String) -> String { products.products().first(where: { $0.id == id })?.name ?? id }
    func create(_ name: String = "Shopping list") -> String {
        let list = SavedGroceryList(name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Shopping list" : name, items: [])
        var data = state.appState; data.savedLists.insert(list, at: 0); state.appState = data
        return list.id
    }
    func rename(_ list: SavedGroceryList, to name: String) {
        guard let i = lists.firstIndex(where: { $0.id == list.id }), !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var data = state.appState; data.savedLists[i].name = name; data.savedLists[i].updatedAt = .now; state.appState = data
    }
    func delete(_ list: SavedGroceryList) { var data = state.appState; data.savedLists.removeAll { $0.id == list.id }; state.appState = data }
    func duplicate(_ list: SavedGroceryList) { var copy = list; copy.id = UUID().uuidString; copy.name += " copy"; copy.items = list.items.map { GroceryListItem(productID: $0.productID, quantity: $0.quantity, isChecked: $0.isChecked) }; var data = state.appState; data.savedLists.insert(copy, at: 0); state.appState = data }
    func add(_ productID: String, quantity: Int = 1, to list: SavedGroceryList) {
        guard let i = lists.firstIndex(where: { $0.id == list.id }) else { return }
        var data = state.appState
        if let j = data.savedLists[i].items.firstIndex(where: { $0.productID == productID }) { data.savedLists[i].items[j].quantity += max(1, quantity); data.savedLists[i].items[j].isChecked = false }
        else { data.savedLists[i].items.append(GroceryListItem(productID: productID, quantity: max(1, quantity))) }
        data.savedLists[i].updatedAt = .now; state.appState = data
    }
    func toggle(_ item: GroceryListItem, in list: SavedGroceryList) {
        guard let i = lists.firstIndex(where: { $0.id == list.id }), let j = lists[i].items.firstIndex(where: { $0.id == item.id }) else { return }
        var data = state.appState; data.savedLists[i].items[j].isChecked.toggle(); data.savedLists[i].updatedAt = .now; state.appState = data
    }
    func change(_ item: GroceryListItem, in list: SavedGroceryList, by amount: Int) {
        guard let i = lists.firstIndex(where: { $0.id == list.id }), let j = lists[i].items.firstIndex(where: { $0.id == item.id }) else { return }
        var data = state.appState; data.savedLists[i].items[j].quantity += amount
        if data.savedLists[i].items[j].quantity <= 0 { data.savedLists[i].items.remove(at: j) }
        data.savedLists[i].updatedAt = .now; state.appState = data
    }
    func addToBasket(_ list: SavedGroceryList, itemIDs: Set<String>? = nil) {
        var lines = basket.lines()
        for item in list.items where itemIDs?.contains(item.id) ?? !item.isChecked {
            guard let offer = products.offers(for: item.productID).filter(\.available).min(by: { $0.effectivePrice < $1.effectivePrice }) else { continue }
            if let i = lines.firstIndex(where: { $0.id == item.productID }) { lines[i].quantity += item.quantity }
            else { lines.append(BasketLine(id: item.productID, offerID: offer.id, quantity: item.quantity)) }
        }
        basket.save(lines)
    }
}
