import SwiftUI

struct BasketView: View {
    @Bindable var model: BasketViewModel
    let openProduct: (CatalogProduct) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if model.lines.isEmpty {
                        ContentUnavailableView("Your basket is empty", systemImage: "basket",
                                               description: Text("Find products and add an offer to start comparing your shop."))
                        Text("Explore the sample catalogue in Search.")
                            .font(.caption).foregroundStyle(AppPalette.muted).frame(maxWidth: .infinity)
                    } else {
                        basketContents
                    }
                }
                .padding(18)
            }
            .background(AppPalette.oat)
            .appScreen("Basket")
        }
    }

    private var basketContents: some View {
        let summary = model.summary
        return VStack(alignment: .leading, spacing: 18) {
            Text("Your picks are shared across the app.")
                .font(.subheadline).foregroundStyle(AppPalette.muted)
            ForEach(model.lines) { line in
                if let product = model.product(for: line), let offer = model.offer(for: line) {
                    BasketLineRow(product: product, offer: offer, line: line, model: model) { openProduct(product) }
                }
            }
            totals(summary)
            budgetStatus(summary)
            if !summary.lowerCostAlternatives.isEmpty { budgetAlternatives(summary.lowerCostAlternatives) }
            optimization(summary)
            Text("Savings are compared with the least expensive single-platform option. Delivery fees are mock estimates.")
                .font(.caption2).foregroundStyle(AppPalette.muted)
        }
    }

    private func budgetStatus(_ summary: BasketSummary) -> some View {
        HStack(spacing: 10) {
            Image(systemName: summary.amountOverBudget > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(summary.amountOverBudget > 0 ? AppPalette.tomato : AppPalette.pine)
            VStack(alignment: .leading, spacing: 3) {
                Text("Trip budget · \(money(summary.tripBudget))").font(.subheadline.weight(.semibold))
                Text(summary.amountOverBudget > 0
                     ? "Over budget by \(money(summary.amountOverBudget))"
                     : "\(money(summary.remainingBudget)) remaining")
                    .font(.caption).foregroundStyle(summary.amountOverBudget > 0 ? AppPalette.tomato : AppPalette.pine)
            }
            Spacer()
        }
        .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
    }

    private func budgetAlternatives(_ alternatives: [BasketOfferAlternative]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(title: "Lower-cost alternatives", subtitle: "Same products, different available sample offers. Nothing changes until you choose.")
            ForEach(alternatives) { alternative in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(alternative.productName).font(.subheadline.weight(.semibold))
                        Text("\(alternative.currentPlatform) → \(alternative.suggestedOffer.retailer)")
                            .font(.caption).foregroundStyle(AppPalette.muted)
                        Text("Estimated basket saving \(money(alternative.estimatedSavings))")
                            .font(.caption2.weight(.semibold)).foregroundStyle(AppPalette.pine)
                    }
                    Spacer(minLength: 4)
                    Button("Switch offer") {
                        model.replaceOffer(for: alternative.lineID, with: alternative.suggestedOffer)
                    }
                    .font(.caption.weight(.bold)).buttonStyle(.bordered).tint(AppPalette.cobalt)
                }
                .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func totals(_ summary: BasketSummary) -> some View {
        VStack(spacing: 10) {
            PriceLine(label: "Items", value: money(summary.subtotal))
            PriceLine(label: "Sample delivery fees", value: money(summary.deliveryFees))
            PriceLine(label: "Offers", value: "−\(money(summary.discount))")
            Divider()
            PriceLine(label: "Basket total", value: money(summary.total), emphasized: true)
        }
        .padding(15).background(.white, in: RoundedRectangle(cornerRadius: 17))
    }

    private func optimization(_ summary: BasketSummary) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(title: "Basket optimization", subtitle: "Review the suggested platform for each item.")
            HStack {
                Image(systemName: "sparkles").foregroundStyle(AppPalette.pine)
                Text(summary.recommendationName).font(.subheadline.weight(.bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(money(summary.recommendationTotal)).font(.subheadline.bold())
                    Text("Save \(money(summary.potentialSavings)) vs one store")
                        .font(.caption2).foregroundStyle(AppPalette.pine)
                }
            }
            .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 15))
            VStack(spacing: 0) {
                ForEach(summary.recommendedLines) { assignment in
                    HStack {
                        Text(model.product(for: assignment.line)?.name ?? "Basket item")
                            .font(.caption.weight(.medium))
                        Spacer()
                        Text("\(assignment.offer.retailer) · \(money(assignment.offer.price - assignment.offer.discount)) each")
                            .font(.caption).foregroundStyle(AppPalette.muted)
                    }
                    .padding(.vertical, 9)
                    if assignment.id != summary.recommendedLines.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 13).background(.white, in: RoundedRectangle(cornerRadius: 15))
        }
    }
}
