import Foundation

@MainActor
struct MockProductRepository: ProductRepository {
    func products() -> [CatalogProduct] { MockCatalog.products }
    func offers(for productID: String) -> [PriceOffer] {
        MockCatalog.offers.filter { $0.productID == productID }
    }
    func allOffers() -> [PriceOffer] { MockCatalog.offers }
    func platforms() -> [String] { MockCatalog.platforms }
}
