import SwiftUI

func money(_ value: Decimal) -> String { let formatter = NumberFormatter(); formatter.numberStyle = .currency; formatter.locale = Locale(identifier:"en_IN"); formatter.currencyCode = "INR"; formatter.maximumFractionDigits = 0; return formatter.string(from:value as NSDecimalNumber) ?? "₹\(value)" }
