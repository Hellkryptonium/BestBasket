import SwiftUI

struct PersonalizationView: View {
    @Bindable var model: PersonalizationViewModel
    @State private var showingSetup = false
    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Tune product, offer, and basket recommendations to the way you shop.")
                        .font(.subheadline).foregroundStyle(AppPalette.muted)
                    Button { showingSetup = true } label: {
                        Label("Quick setup", systemImage: "sparkles")
                    }
                }

                Section("Shopping priority") {
                    Picker("Primary priority", selection: preferenceBinding(\.primaryPriority)) {
                        ForEach(ShoppingPriority.allCases) { priority in Text(priority.title).tag(priority) }
                    }
                    DisclosureGroup("Secondary priorities") {
                        ForEach(ShoppingPriority.allCases.filter { $0 != model.preferences.primaryPriority }) { priority in
                            Toggle(priority.title, isOn: Binding(
                                get: { model.preferences.secondaryPriorities.contains(priority) },
                                set: { _ in model.toggleSecondaryPriority(priority) }
                            ))
                        }
                    }
                }

                Section("Preferred brands") {
                    DisclosureGroup("Choose brands (\(model.preferences.preferredBrandIDs.count) selected)") {
                        preferenceChips(model.brands, id: { PreferenceIDs.make(from: $0) },
                                        selected: { model.preferences.preferredBrandIDs.contains($0) },
                                        toggle: model.toggleBrand)
                    }
                }

                Section("Preferred platforms") {
                    preferenceChips(model.platforms, id: { PreferenceIDs.make(from: $0) },
                                    selected: { model.preferences.preferredPlatformIDs.contains($0) },
                                    toggle: model.togglePlatform)
                }

                Section("Favorite categories") {
                    preferenceChips(model.categories, id: { PreferenceIDs.make(from: $0) },
                                    selected: { model.preferences.preferredCategoryIDs.contains($0) },
                                    toggle: model.toggleCategory)
                }

                Section("Budget and household") {
                    HStack {
                        Text("Per shopping trip")
                        Spacer()
                        Text("₹")
                        TextField("Trip budget", value: preferenceBinding(\.tripBudget), format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 110)
                    }
                    Toggle("Set a monthly budget", isOn: monthlyBudgetEnabled)
                    if model.preferences.monthlyBudget != nil {
                        HStack {
                            Text("Monthly")
                            Spacer()
                            Text("₹")
                            TextField("Monthly budget", value: monthlyBudgetInput, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 110)
                        }
                    }
                    Stepper(value: preferenceBinding(\.householdSize), in: 1...20) {
                        LabeledContent("Household size", value: "\(model.preferences.householdSize)")
                    }
                    Picker("Shopping frequency", selection: preferenceBinding(\.shoppingFrequency)) {
                        ForEach(ShoppingFrequency.allCases) { frequency in Text(frequency.title).tag(frequency) }
                    }
                }

                Section("Personalization controls") {
                    Toggle("Personalized recommendations", isOn: preferenceBinding(\.personalizationEnabled))
                    Toggle("Personalize Search ranking", isOn: preferenceBinding(\.searchPersonalizationEnabled))
                        .disabled(!model.preferences.personalizationEnabled)
                    Text("Turning personalization off keeps your saved choices and restores neutral ranking.")
                        .font(.caption).foregroundStyle(AppPalette.muted)
                }

                Section {
                    Button("Reset preferences", role: .destructive) { confirmingReset = true }
                } footer: {
                    Text("Changes save automatically on this device. Product and platform data are illustrative mock data.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.oat)
            .appScreen("Your profile")
            .sheet(isPresented: $showingSetup) { PersonalizationSetupSheet(model: model) }
            .confirmationDialog("Reset all personalization choices?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset preferences", role: .destructive, action: model.resetPreferences)
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private var monthlyBudgetEnabled: Binding<Bool> {
        Binding(
            get: { model.preferences.monthlyBudget != nil },
            set: { enabled in
                var updated = model.preferences
                updated.monthlyBudget = enabled ? (updated.monthlyBudget ?? updated.tripBudget * 4) : nil
                model.preferences = updated
            }
        )
    }

    private var monthlyBudgetInput: Binding<Decimal> {
        Binding(
            get: { model.preferences.monthlyBudget ?? 0 },
            set: { value in var updated = model.preferences; updated.monthlyBudget = max(0, value); model.preferences = updated }
        )
    }

    private func preferenceBinding<Value>(_ keyPath: WritableKeyPath<ShoppingPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { model.preferences[keyPath: keyPath] },
            set: { value in var updated = model.preferences; updated[keyPath: keyPath] = value; model.preferences = updated }
        )
    }

    private func preferenceChips(_ values: [String], id: @escaping (String) -> String,
                                 selected: @escaping (String) -> Bool,
                                 toggle: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), alignment: .leading)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                Button { toggle(value) } label: {
                    Text(value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selected(id(value)) ? .white : AppPalette.ink)
                        .padding(.horizontal, 11).padding(.vertical, 8)
                        .background(selected(id(value)) ? AppPalette.cobalt : AppPalette.oat, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected(id(value)) ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
