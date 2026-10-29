import SwiftUI

struct OfferRow: View {
    let offer: PriceOffer
    let isBest: Bool
    let reason: String?
    let add: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(offer.retailer).font(.subheadline.weight(.bold))
                    if isBest {
                        Text("TOP MATCH")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(AppPalette.ink)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(AppPalette.marigold, in: Capsule())
                    }
                }
                .foregroundStyle(AppPalette.ink)
                Text(offer.available ? "In stock · sample delivery \(offer.delivery)" : "Currently unavailable · sample listing")
                    .font(.caption2).foregroundStyle(offer.available ? AppPalette.pine : AppPalette.tomato)
                if let reason {
                    Text(reason).font(.caption2.weight(.medium)).foregroundStyle(AppPalette.cobalt)
                }
                Text("Delivery fee \(money(offer.deliveryFee))\(offer.discount > 0 ? " · item offer −\(money(offer.discount))" : "")")
                    .font(.caption2).foregroundStyle(AppPalette.muted)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(offer.price)).font(.headline.weight(.bold)).foregroundStyle(AppPalette.ink)
                Text("incl. fee \(money(offer.effectivePrice))").font(.caption2).foregroundStyle(AppPalette.muted)
            }
            Button(action: add) {
                Image(systemName: "plus").font(.caption.bold()).foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(offer.available ? AppPalette.cobalt : AppPalette.muted, in: Circle())
            }
            .disabled(!offer.available)
            .accessibilityLabel("Add \(offer.retailer) offer")
        }
        .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 15))
    }
}
