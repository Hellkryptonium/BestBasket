import SwiftUI

struct EssentialsView: View {
    @Bindable var model: EssentialsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newListName = ""
    @State private var customReminderEssential: EssentialSummary?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sampleHistorySection
                    remindersSection
                    savedListsSection
                    previousBasketsSection
                    Text("Purchase counts and prices shown here are static sample history. Reminders are in-app planning aids, not inventory or push alerts.")
                        .font(.caption2).foregroundStyle(AppPalette.muted)
                }
                .padding(18)
            }
            .background(AppPalette.oat)
            .navigationTitle("Everyday essentials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(item: $customReminderEssential) { essential in
                CustomReminderSheet(essential: essential) { days in
                    model.setReminder(for: essential, interval: .custom(days: days))
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var sampleHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Frequently purchased", subtitle: "From sample purchase history")
            ForEach(model.essentials) { essential in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ProductArt(product: essential.product).frame(width: 54, height: 54)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(essential.product.name).font(.subheadline.weight(.semibold))
                            Text("Bought \(essential.purchaseCount) times\(essential.typicalIntervalDays.map { " · about every \($0) days" } ?? "") · last \(essential.latestEntry.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(AppPalette.muted)
                        }
                        Spacer(minLength: 0)
                        Button { model.addEssential(essential) } label: {
                            Image(systemName: "basket.badge.plus").font(.title3).foregroundStyle(AppPalette.cobalt)
                                .frame(width: 42, height: 42).contentShape(Rectangle())
                        }
                        .accessibilityLabel("Add \(essential.product.name) to basket")
                    }
                    HStack(spacing: 5) {
                        Text("Current sample price")
                        Text(model.currentOffer(for: essential.product).map { money($0.price) } ?? "Unavailable")
                            .fontWeight(.semibold)
                        if let previous = essential.previousPrice {
                            Text("· previous sample purchase \(money(previous))")
                        }
                    }
                    .font(.caption2).foregroundStyle(AppPalette.muted)
                    HStack {
                        if let reminder = model.reminders.first(where: { $0.productID == essential.product.id }) {
                            Label("Next reminder \(reminder.nextReminderAt.formatted(date: .abbreviated, time: .omitted)) · \(reminder.interval.title)", systemImage: "bell")
                                .font(.caption2).foregroundStyle(AppPalette.pine)
                        } else {
                            Text("No refill reminder").font(.caption2).foregroundStyle(AppPalette.muted)
                        }
                        Spacer()
                        Menu("Reminder") {
                            Button("Daily") { model.setReminder(for: essential, interval: .daily) }
                            Button("Weekly") { model.setReminder(for: essential, interval: .weekly) }
                            Button("Custom interval…") { customReminderEssential = essential }
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Refill reminders", subtitle: "A prompt to plan a shop, not an inventory alert")
            if model.reminders.isEmpty {
                Text("Set a reminder from any essential above.").font(.subheadline).foregroundStyle(AppPalette.muted)
            } else {
                ForEach(model.reminders) { reminder in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(model.product(for: reminder.productID)?.name ?? "Grocery item")
                                .font(.subheadline.weight(.semibold))
                            Text("Last purchase \(reminder.lastPurchaseAt.formatted(date: .abbreviated, time: .omitted)) · next \(reminder.nextReminderAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2).foregroundStyle(AppPalette.muted)
                        }
                        Spacer(minLength: 4)
                        Toggle("Reminder enabled", isOn: Binding(
                            get: { reminder.enabled },
                            set: { model.setReminderEnabled(reminder, enabled: $0) }
                        ))
                        .labelsHidden().tint(AppPalette.cobalt)
                    }
                    .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var savedListsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Saved grocery lists", subtitle: "Reusable lists merge into your current basket")
            HStack {
                TextField("New list name", text: $newListName).textFieldStyle(.roundedBorder)
                Button("Create") {
                    model.createList(name: newListName)
                    newListName = ""
                }
                .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent).tint(AppPalette.cobalt)
            }
            if model.lists.isEmpty {
                Text("Create a list, then add products from the catalog menu.")
                    .font(.subheadline).foregroundStyle(AppPalette.muted)
            }
            ForEach(model.lists) { list in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(list.name).font(.headline)
                        Spacer()
                        Menu {
                            ForEach(model.catalogProducts) { product in
                                Button("Add \(product.name)") { model.addProduct(product, to: list) }
                            }
                        } label: { Label("Add item", systemImage: "plus") }
                    }
                    if list.items.isEmpty {
                        Text("No products yet.").font(.caption).foregroundStyle(AppPalette.muted)
                    }
                    ForEach(list.items) { item in
                        HStack(spacing: 8) {
                            Text(model.product(for: item.productID)?.name ?? item.productID).font(.caption)
                            Spacer()
                            Button { model.changeListQuantity(item, in: list, by: -1) } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(AppPalette.cobalt)
                            }.accessibilityLabel("Remove one")
                            Text("\(item.quantity)").font(.caption.monospacedDigit())
                            Button { model.changeListQuantity(item, in: list, by: 1) } label: {
                                Image(systemName: "plus.circle.fill").foregroundStyle(AppPalette.cobalt)
                            }.accessibilityLabel("Add one")
                        }
                    }
                    HStack {
                        Button("Add list to basket") { model.addListToBasket(list) }
                            .buttonStyle(.borderedProminent).tint(AppPalette.cobalt)
                        Button("Duplicate") { model.duplicateList(list) }.buttonStyle(.bordered)
                        Spacer()
                        Button(role: .destructive) { model.deleteList(list) } label: {
                            Image(systemName: "trash")
                        }.accessibilityLabel("Delete \(list.name)")
                    }
                }
                .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var previousBasketsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(title: "Previous baskets", subtitle: "Save a snapshot, then rebuild by adding it")
                Spacer()
                Button("Save current") { model.saveCurrentBasket() }
                    .font(.caption.weight(.semibold)).disabled(model.currentBasketIsEmpty)
            }
            if model.previousBaskets.isEmpty {
                Text("No basket snapshots saved yet.").font(.subheadline).foregroundStyle(AppPalette.muted)
            }
            ForEach(model.previousBaskets) { snapshot in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(snapshot.name).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("Sample total \(money(snapshot.total))").font(.caption.weight(.semibold))
                    }
                    ForEach(snapshot.items) { item in
                        HStack {
                            Text("\(model.product(for: item.productID)?.name ?? item.productID) × \(item.quantity)")
                                .font(.caption).foregroundStyle(AppPalette.muted)
                            Spacer()
                            Button("Add item") { model.restore(item) }.font(.caption.weight(.semibold))
                        }
                    }
                    Button("Add these items to current basket") { model.restore(snapshot) }
                        .buttonStyle(.bordered).tint(AppPalette.cobalt)
                }
                .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

private struct CustomReminderSheet: View {
    let essential: EssentialSummary
    let save: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var days = 14

    var body: some View {
        NavigationStack {
            Form {
                Section("Custom refill reminder") {
                    Text(essential.product.name)
                    Stepper("Every \(days) days", value: $days, in: 2...365)
                }
                Section {
                    Button("Save reminder") { save(days); dismiss() }
                }
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
