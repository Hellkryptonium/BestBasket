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
            Text("All prices, fees, purchase history, and offers are sample data. No retailer checkout is connected.")
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
            PriceLine(label: "Sample platform fees", value: money(summary.platformFees))
            PriceLine(label: "Offers", value: "−\(money(summary.discount))")
            Divider()
            PriceLine(label: "Basket total", value: money(summary.total), emphasized: true)
        }
        .padding(15).background(.white, in: RoundedRectangle(cornerRadius: 17))
    }

    private func optimization(_ summary: BasketSummary) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle(title: "Basket Saver", subtitle: "Compare complete baskets with retailer delivery fees included.")
            if summary.cheapestSinglePlatform == nil && summary.bestMultiPlatform == nil {
                Text("No complete platform comparison is available for this basket.")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.tomato)
            }
            if let cheapest = summary.cheapestSinglePlatform {
                comparisonCard(title: "Cheapest single platform", plan: cheapest, accent: AppPalette.pine)
            }
            if !summary.singlePlatformPlans.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Single-platform totals").font(.caption.weight(.bold))
                    ForEach(summary.singlePlatformPlans) { plan in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(plan.name)
                                Spacer()
                                if !plan.isComplete { Text("Partial").foregroundStyle(AppPalette.tomato) }
                                Text(money(plan.total)).fontWeight(.semibold)
                            }
                            if !plan.excludedProducts.isEmpty {
                                Text("Excludes \(plan.excludedProducts.joined(separator: ", "))")
                                    .font(.caption2).foregroundStyle(AppPalette.tomato)
                            }
                        }
                        .font(.caption)
                    }
                }
                .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
            if let multi = summary.bestMultiPlatform {
                comparisonCard(title: "Best multi-platform option", plan: multi, accent: AppPalette.cobalt)
            }
            if let mostExpensive = summary.mostExpensiveSinglePlatform {
                HStack {
                    Text("Savings vs most expensive complete single-platform option")
                    Spacer()
                    Text(money(summary.savingsVersusMostExpensive)).fontWeight(.bold).foregroundStyle(AppPalette.pine)
                }
                .font(.caption).padding(12).background(.white, in: RoundedRectangle(cornerRadius: 13))
                Text("Most expensive eligible option: \(mostExpensive.name) · \(money(mostExpensive.total))")
                    .font(.caption2).foregroundStyle(AppPalette.muted)
            }
            if !summary.productsUnavailableEverywhere.isEmpty {
                Text("Not included in complete comparisons: \(summary.productsUnavailableEverywhere.joined(separator: ", ")).")
                    .font(.caption.weight(.semibold)).foregroundStyle(AppPalette.tomato)
                    .padding(11).background(.white, in: RoundedRectangle(cornerRadius: 12))
            }
            HStack {
                Image(systemName: "sparkles").foregroundStyle(AppPalette.pine)
                Text(summary.recommendationName).font(.subheadline.weight(.bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(money(summary.recommendationTotal)).font(.subheadline.bold())
                Text(summary.recommendedPlan?.isComplete == true
                     ? "Save \(money(summary.potentialSavings)) vs current basket"
                     : "Partial comparison · check excluded items")
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
                        Text("\(assignment.offer.retailer) · \(money(assignment.offer.price - assignment.offer.discount)) × \(assignment.line.quantity)")
                            .font(.caption).foregroundStyle(AppPalette.muted)
                    }
                    .padding(.vertical, 9)
                    if assignment.id != summary.recommendedLines.last?.id { Divider() }
                }
            }
            .padding(.horizontal, 13).background(.white, in: RoundedRectangle(cornerRadius: 15))
            if let plan = summary.recommendedPlan {
                Button {
                    model.apply(plan)
                } label: {
                    Label(plan.isComplete ? "Apply recommended offers to basket" : "Comparison is partial",
                          systemImage: plan.isComplete ? "checkmark.circle" : "exclamationmark.circle")
                        .frame(maxWidth: .infinity).padding(12)
                }
                .buttonStyle(.borderedProminent).tint(AppPalette.cobalt)
                .disabled(!plan.isComplete)
            }
        }
    }

    private func comparisonCard(title: String, plan: BasketPlan, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title).font(.caption.weight(.bold)).foregroundStyle(accent)
                Spacer()
                Text(money(plan.total)).font(.subheadline.weight(.bold))
            }
            Text(plan.platforms.joined(separator: " + ")).font(.caption).foregroundStyle(AppPalette.ink)
            HStack(spacing: 10) {
                Text("Items \(money(plan.itemSubtotal))")
                Text("Delivery \(money(plan.deliveryFees))")
                Text("Platform \(money(plan.platformFees))")
                Text("Discounts −\(money(plan.discounts))")
            }
            .font(.caption2).foregroundStyle(AppPalette.muted)
            if !plan.excludedProducts.isEmpty {
                Text("Partial option · excludes \(plan.excludedProducts.joined(separator: ", "))")
                    .font(.caption2.weight(.semibold)).foregroundStyle(AppPalette.tomato)
            }
            ForEach(plan.assignments) { assignment in
                HStack {
                    Text(model.product(for: assignment.line)?.name ?? "Basket item")
                    Spacer()
                    Text("\(assignment.offer.retailer) × \(assignment.line.quantity)")
                }
                .font(.caption2).foregroundStyle(AppPalette.muted)
            }
        }
        .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 14))
    }
}
