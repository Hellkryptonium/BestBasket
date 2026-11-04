import SwiftUI

struct TrackingView: View {
    @Bindable var model: TrackingViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Toggle(isOn: Binding(get: { model.isEnabled }, set: { model.isEnabled = $0 })) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Watch my basket").font(.headline)
                            Text("Find meaningful savings on items already in your basket.")
                                .font(.caption).foregroundStyle(AppPalette.muted)
                        }
                    }
                    .tint(AppPalette.cobalt)
                    .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 16))

                    if model.isEnabled {
                        notificationsSection
                        dealsSection
                    } else {
                        ContentUnavailableView("Basket Watch is off", systemImage: "bell.slash",
                                               description: Text("Turn it on to compare available sample offers for your basket items."))
                    }
                    Text("Sample catalogue only. No live price changes or external notifications are used.")
                        .font(.caption2).foregroundStyle(AppPalette.muted)
                }
                .padding(18)
            }
            .background(AppPalette.oat)
            .appScreen("Basket Watch")
            .onAppear { model.refreshNotifications() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") { model.refreshNotifications() }
                        .disabled(!model.isEnabled)
                }
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(title: "Deal notifications", subtitle: "One saved notice per sample offer")
                Spacer()
                Button("Mark read") { model.markAllRead() }
                    .font(.caption.weight(.semibold)).disabled(model.notifications.allSatisfy { $0.readAt != nil })
            }
            if model.notifications.isEmpty {
                Text("No basket deals found yet.").font(.subheadline).foregroundStyle(AppPalette.muted)
            } else {
                ForEach(model.notifications) { notification in
                    HStack(spacing: 10) {
                        Image(systemName: notification.readAt == nil ? "bell.badge.fill" : "bell")
                            .foregroundStyle(notification.readAt == nil ? AppPalette.cobalt : AppPalette.muted)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(notificationTitle(notification)).font(.subheadline.weight(.semibold))
                            Text(notification.kind == .offerUnavailable
                                 ? "Previous offer is unavailable · alternative shown below"
                                 : "Potential saving \(money(notification.estimatedSavings)) · sample data")
                                .font(.caption).foregroundStyle(AppPalette.muted)
                        }
                        Spacer()
                        if notification.readAt == nil {
                            Button("Read") { model.markRead(notification) }.font(.caption.weight(.semibold))
                        }
                    }
                    .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Better offers for your basket", subtitle: "Only equivalent catalog products are compared")
            if model.isBasketEmpty {
                ContentUnavailableView("Your basket is empty", systemImage: "basket",
                                       description: Text("Add products in Search to start watching equivalent sample offers."))
                    .frame(minHeight: 160)
            } else if model.deals.isEmpty {
                ContentUnavailableView("No better offers", systemImage: "checkmark.circle",
                                       description: Text("Your current basket offers are already close to the best sample prices."))
                    .frame(minHeight: 160)
            }
            ForEach(model.deals) { deal in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ProductArt(product: deal.product).frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(deal.product.name).font(.subheadline.weight(.semibold))
                            Text("Qty \(deal.line.quantity) · same pack \(deal.product.packSize)")
                                .font(.caption).foregroundStyle(AppPalette.muted)
                        }
                        Spacer()
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(deal.currentOffer.available ? "Current · \(deal.currentOffer.retailer)" : "Unavailable · \(deal.currentOffer.retailer)")
                                .font(.caption).foregroundStyle(deal.currentOffer.available ? AppPalette.muted : AppPalette.tomato)
                            Text(money(deal.currentOffer.effectivePrice)).font(.subheadline.weight(.semibold))
                        }
                        Spacer()
                        Image(systemName: "arrow.right").foregroundStyle(AppPalette.muted)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Offer · \(deal.suggestedOffer.retailer)").font(.caption).foregroundStyle(AppPalette.pine)
                            Text(money(deal.suggestedOffer.effectivePrice)).font(.subheadline.weight(.semibold))
                        }
                    }
                    HStack {
                        Text("Save \(money(deal.savings)) for this quantity")
                            .font(.caption.weight(.bold)).foregroundStyle(AppPalette.pine)
                        Spacer()
                        Button("Apply offer") { model.apply(deal) }
                            .font(.caption.weight(.bold)).buttonStyle(.borderedProminent).tint(AppPalette.cobalt)
                    }
                }
                .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func notificationTitle(_ notification: BasketDealNotification) -> String {
        let productName = model.deals.first(where: { $0.product.id == notification.productID })?.product.name
            ?? notification.productID.replacingOccurrences(of: "-", with: " ").capitalized
        return notification.kind == .offerUnavailable
            ? "Basket offer unavailable for \(productName)"
            : "Better offer for \(productName)"
    }
}
