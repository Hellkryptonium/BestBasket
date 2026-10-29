import Foundation
import SwiftData

@Model
final class GroceryList {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var items: [GroceryItem]

    init(name: String, createdAt: Date = .now, items: [GroceryItem] = []) {
        self.id = UUID()
        self.name = name
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
final class GroceryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var preferredBrand: String
    var packSize: String
    var quantity: Int
    var isChecked: Bool

    init(name: String, preferredBrand: String, packSize: String, quantity: Int = 1, isChecked: Bool = false) {
        self.id = UUID()
        self.name = name
        self.preferredBrand = preferredBrand
        self.packSize = packSize
        self.quantity = quantity
        self.isChecked = isChecked
    }
}
