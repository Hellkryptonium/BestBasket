import Foundation

enum MockPurchaseHistory {
    static let entries: [PurchaseHistoryEntry] = {
        let calendar = Calendar.current
        let samples: [(String, Int, Decimal, String, Int)] = [
            ("amul-milk", 1, 60, "Blinkit", 14), ("amul-milk", 1, 62, "Zepto", 7),
            ("oats", 1, 180, "BigBasket", 24), ("oats", 1, 185, "Blinkit", 9),
            ("coffee", 1, 239, "Zepto", 37), ("coffee", 1, 245, "Blinkit", 12),
            ("eggs", 1, 69, "Blinkit", 20), ("eggs", 1, 72, "Zepto", 8),
            ("paneer", 1, 91, "BigBasket", 16), ("paneer", 2, 95, "Blinkit", 5),
            ("bread", 1, 46, "Zepto", 10), ("bread", 1, 48, "Blinkit", 3)
        ]
        return samples.enumerated().map { index, sample in
            PurchaseHistoryEntry(id: "sample-purchase-\(index)", productID: sample.0, quantity: sample.1,
                                 unitPrice: sample.2, platform: sample.3,
                                 purchaseDate: calendar.date(byAdding: .day, value: -sample.4, to: .now) ?? .now)
        }
    }()
}
