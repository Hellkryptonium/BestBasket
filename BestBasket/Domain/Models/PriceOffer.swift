import Foundation

struct PriceOffer: Identifiable, Hashable {
    let id: String
    let productID: String
    let retailer: String
    let price: Decimal
    let originalPrice: Decimal?
    let discount: Decimal
    let deliveryFee: Decimal
    let available: Bool
    let delivery: String
    let colorName: String

    var effectivePrice: Decimal { price + deliveryFee - discount }
}
