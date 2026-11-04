import SwiftUI

struct GroceryListsView: View {
    @Bindable var model: GroceryListsViewModel
    @State private var creating = false
    @State private var newName = ""
    @State private var selected: SavedGroceryList?
    var body: some View {
        NavigationStack {
            List {
                if model.lists.isEmpty {
                    ContentUnavailableView("Your lists start here", systemImage: "list.bullet", description: Text("Keep shopping plans separate from your checkout basket."))
                }
                ForEach(model.lists) { list in
                    NavigationLink(value: list) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(list.name).font(.headline).foregroundStyle(AppPalette.ink)
                            Text("\(list.items.count) items · \(list.items.filter(\.isChecked).count) checked").font(.caption).foregroundStyle(AppPalette.muted)
                        }
                    }.swipeActions {
                        Button("Delete", role: .destructive) { model.delete(list) }
                        Button("Copy") { model.duplicate(list) }.tint(AppPalette.cobalt)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(AppPalette.oat)
            .navigationTitle("Grocery Lists")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { creating = true } label: { Label("New list", systemImage: "plus") } } }
            .navigationDestination(for: SavedGroceryList.self) { list in GroceryListDetailView(model: model, listID: list.id) }
            .alert("New grocery list", isPresented: $creating) {
                TextField("List name", text: $newName)
                Button("Create") { _ = model.create(newName); newName = "" }
                Button("Cancel", role: .cancel) { newName = "" }
            }
        }
    }
}

private struct GroceryListDetailView: View {
    @Bindable var model: GroceryListsViewModel
    let listID: String
    private var list: SavedGroceryList? { model.lists.first { $0.id == listID } }
    var body: some View {
        Group {
            if let list {
                List {
                    if list.items.isEmpty { ContentUnavailableView("List is empty", systemImage: "cart", description: Text("Add products from Search or product details.")) }
                    ForEach(list.items) { item in
                        HStack(spacing: 12) {
                            Button { model.toggle(item, in: list) } label: { Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle").foregroundStyle(item.isChecked ? AppPalette.pine : AppPalette.muted) }.buttonStyle(.plain)
                            VStack(alignment: .leading) { Text(model.productName(item.productID)).font(.subheadline.weight(.medium)).strikethrough(item.isChecked); Text("Qty \(item.quantity)").font(.caption).foregroundStyle(AppPalette.muted) }
                            Spacer()
                            Stepper("", value: Binding(get: { item.quantity }, set: { model.change(item, in: list, by: $0 - item.quantity) }), in: 0...99).labelsHidden()
                        }
                    }
                    Section { Button { model.addToBasket(list) } label: { Label("Add unchecked items to Basket", systemImage: "basket") } }
                }.scrollContentBackground(.hidden).background(AppPalette.oat).navigationTitle(list.name).navigationBarTitleDisplayMode(.inline)
            } else { ContentUnavailableView("List unavailable", systemImage: "list.bullet") }
        }
    }
}
