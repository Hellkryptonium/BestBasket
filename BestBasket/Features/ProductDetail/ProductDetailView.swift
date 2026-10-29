import SwiftUI

struct ProductDetailView: View {
    @Bindable var model: ProductDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var targetText = ""
    @State private var showTarget = false

    private var product: CatalogProduct { model.product }
    private var trackingActionButton: some View {
        Button(action: prepareTracking) {
            Label(model.trackedItem == nil ? "Track price" : "Edit price alert", systemImage: "bell.badge")
                .frame(maxWidth: .infinity).padding(14).background(.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppPalette.ink, lineWidth: 1.5))
        }
    }
    private var addBestOfferButton: some View {
        Button(action: addBestOffer) {
            Label("Add best offer", systemImage: "basket.badge.plus")
                .frame(maxWidth: .infinity).padding(14).foregroundStyle(.white)
                .background(AppPalette.cobalt, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppPalette.ink, lineWidth: 1.5))
                .shadow(color: AppPalette.ink, radius: 0, x: 0, y: 3)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ProductArt(product: product).frame(height: 235)
                    productSummary
                    offerComparison
                    recommendationExplanation
                    HStack(spacing: 10) { trackingActionButton; addBestOfferButton }
                        .font(.caption.weight(.bold)).foregroundStyle(AppPalette.ink)
                    Label("Retailer checkout will be available in a future version", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.medium)).foregroundStyle(AppPalette.muted).frame(maxWidth: .infinity)
                    Text("Sample data only · no purchase or retailer connection is available.")
                        .font(.caption2).foregroundStyle(AppPalette.muted).frame(maxWidth: .infinity)
                }
                .padding(18)
            }
            .background(AppPalette.oat)
            .navigationTitle("Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .alert("Set a target price", isPresented: $showTarget) {
                TextField("Target in rupees", text: $targetText).keyboardType(.decimalPad)
                Button("Save", action: saveTarget)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("We’ll highlight when a sample offer reaches your target.")
            }
        }
    }

    private var productSummary: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(product.brand) · \(product.category.uppercased())")
                .font(.caption.weight(.bold)).tracking(1).foregroundStyle(AppPalette.muted)
            Text(product.name).font(.title2.weight(.bold)).foregroundStyle(AppPalette.ink)
            Text(product.packSize).font(.subheadline).foregroundStyle(AppPalette.muted)
            Label("\(product.rating, specifier: "%.1f") · \(product.reviewCount) sample reviews", systemImage: "star.fill")
                .font(.caption).foregroundStyle(AppPalette.ink)
            Text(product.description).font(.subheadline).foregroundStyle(AppPalette.muted).padding(.top, 4)
        }
    }

    private var offerComparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Compare sample offers", subtitle: "Ranked using your saved priorities and effective price.")
            ForEach(model.offers) { offer in
                OfferRow(offer: offer, isBest: offer.id == model.bestOffer?.id,
                         reason: model.offerReason(offer)) {
                    model.add(offer)
                }
            }
        }
    }

    private var recommendationExplanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How we picked the best value").font(.subheadline.weight(.bold))
            Text("Available offers are ranked with your delivery, platform, and price preferences. Delivery fees are included in basket totals.")
                .font(.caption).foregroundStyle(AppPalette.muted)
        }
        .padding(14).background(AppPalette.blush.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
    }

    private func prepareTracking() {
        if let tracked = model.trackedItem {
            targetText = NSDecimalNumber(decimal: tracked.targetPrice).stringValue
        } else if let price = model.bestOffer?.price {
            targetText = NSDecimalNumber(decimal: price * Decimal(9) / Decimal(10)).stringValue
        }
        showTarget = true
    }
    private func addBestOffer() {
        guard let offer = model.bestOffer else { return }
        model.add(offer)
    }
    private func saveTarget() {
        let target = Decimal(string: targetText) ?? model.bestOffer?.price ?? 0
        model.track(targetPrice: target)
        targetText = ""
    }
}
