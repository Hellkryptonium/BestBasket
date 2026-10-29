import SwiftUI

struct PersonalizationSetupSheet: View {
    @Bindable var model: PersonalizationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ShoppingPreferences
    @State private var step = 0

    init(model: PersonalizationViewModel) {
        self.model = model
        _draft = State(initialValue: model.preferences)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("STEP \(step + 1) OF 3").font(.caption.weight(.bold)).tracking(1).foregroundStyle(AppPalette.muted)
                    Spacer()
                    Button("Skip") { dismiss() }.font(.subheadline.weight(.semibold))
                }
                ProgressView(value: Double(step + 1), total: 3).tint(AppPalette.cobalt)
                stepContent
                Spacer(minLength: 0)
                HStack {
                    if step > 0 { Button("Back") { step -= 1 }.buttonStyle(.bordered) }
                    Spacer()
                    Button(step == 2 ? "Save preferences" : "Continue") {
                        if step == 2 {
                            draft.setupCompleted = true
                            model.preferences = draft
                            dismiss()
                        } else {
                            step += 1
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(AppPalette.cobalt)
                }
            }
            .padding(20)
            .background(AppPalette.oat.ignoresSafeArea())
            .navigationTitle("Quick setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            VStack(alignment: .leading, spacing: 14) {
                Text("What brands do you reach for?").font(.title3.bold())
                Text("We’ll give those products a boost in recommendations.").font(.subheadline).foregroundStyle(AppPalette.muted)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), alignment: .leading)], alignment: .leading, spacing: 9) {
                        ForEach(model.brands, id: \.self) { brand in
                            setupChip(brand, selected: draft.preferredBrandIDs.contains(PreferenceIDs.make(from: brand))) {
                                toggle(brand, in: &draft.preferredBrandIDs)
                            }
                        }
                    }
                }
            }
        case 1:
            VStack(alignment: .leading, spacing: 14) {
                Text("What matters most?").font(.title3.bold())
                Text("You can adjust these choices any time.").font(.subheadline).foregroundStyle(AppPalette.muted)
                Picker("Primary priority", selection: $draft.primaryPriority) {
                    ForEach(ShoppingPriority.allCases) { priority in Text(priority.title).tag(priority) }
                }
                ForEach(model.categories, id: \.self) { category in
                    let id = PreferenceIDs.make(from: category)
                    Toggle(category, isOn: Binding(
                        get: { draft.preferredCategoryIDs.contains(id) },
                        set: { value in if value { draft.preferredCategoryIDs.insert(id) } else { draft.preferredCategoryIDs.remove(id) } }
                    ))
                }
            }
        default:
            VStack(alignment: .leading, spacing: 14) {
                Text("What’s your typical shop like?").font(.title3.bold())
                Text("We’ll use this to make budget guidance more useful.").font(.subheadline).foregroundStyle(AppPalette.muted)
                HStack {
                    Text("Trip budget")
                    Spacer()
                    Text("₹")
                    TextField("1500", value: $draft.tripBudget, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(maxWidth: 110)
                }
                Stepper(value: $draft.householdSize, in: 1...20) {
                    LabeledContent("Household size", value: "\(draft.householdSize)")
                }
                Picker("Shopping frequency", selection: $draft.shoppingFrequency) {
                    ForEach(ShoppingFrequency.allCases) { frequency in Text(frequency.title).tag(frequency) }
                }
            }
        }
    }

    private func setupChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.caption.weight(.semibold))
                .foregroundStyle(selected ? .white : AppPalette.ink)
                .padding(.horizontal, 11).padding(.vertical, 8)
                .background(selected ? AppPalette.cobalt : .white, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func toggle(_ value: String, in ids: inout Set<String>) {
        let id = PreferenceIDs.make(from: value)
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
    }
}
