import Foundation

struct CatalogProduct: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let packSize: String
    let category: String
    let systemImage: String
    let rating: Double
    let reviewCount: Int
    let description: String
}
