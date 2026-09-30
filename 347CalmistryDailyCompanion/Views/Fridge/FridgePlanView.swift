import SwiftUI

struct FridgePlanView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var ingredientDraft = ""
    @State private var amountDraft = ""
    @State private var matches: [RecipeMatch] = []
    @State private var showTools = false
    @State private var detailDish: CatalogDish?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureHero(
                        title: "Fridge → Week",
                        subtitle: "List what is already home. We rank catalog dishes and fill Mon–Sun.",
                        symbol: "refrigerator.fill"
                    )

                    PaperCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add to fridge")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.ink)
                                .padding(.top, 6)
                            FieldShell {
                                TextField("Ingredient (e.g. chickpeas)", text: $ingredientDraft)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundColor(Palette.ink)
                            }
                            FieldShell {
                                TextField("Amount note (optional)", text: $amountDraft)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundColor(Palette.ink)
                            }
                            Button {
                                store.addFridgeItem(name: ingredientDraft, amountNote: amountDraft)
                                ingredientDraft = ""
                                amountDraft = ""
                            } label: {
                                PrimaryButtonLabel(title: "Save ingredient")
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if store.fridgeItems.isEmpty {
                        EmptyGarden(
                            title: "Fridge is empty",
                            systemImage: "carrot.fill",
                            message: "Add produce, proteins, and pantry staples you already own. Matching begins after the first item."
                        )
                    } else {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("In the fridge")
                                        .font(.system(.headline, design: .rounded).weight(.bold))
                                        .foregroundColor(Palette.ink)
                                    Spacer()
                                    Button("Clear") { store.clearFridge() }
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                        .foregroundColor(Palette.muted)
                                }
                                .padding(.top, 6)
                                ForEach(store.fridgeItems) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.system(.body, design: .rounded).weight(.semibold))
                                                .foregroundColor(Palette.ink)
                                            if !item.amountNote.isEmpty {
                                                Text(item.amountNote)
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(Palette.muted)
                                            }
                                        }
                                        Spacer()
                                        Button {
                                            store.removeFridgeItem(id: item.id)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(Palette.muted.opacity(0.75))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        Button {
                            matches = store.generateWeekFromFridge()
                        } label: {
                            PrimaryButtonLabel(title: "Build smart week plan")
                        }
                        .buttonStyle(.plain)
                    }

                    weekSection

                    if !matches.isEmpty {
                        SectionTitle(title: "Top matches", subtitle: "Best fits from the authored shelf")
                        ForEach(matches.prefix(8)) { match in
                            Button {
                                detailDish = match.dish
                            } label: {
                                PaperCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(match.dish.emoji)
                                                .font(.system(size: 28))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(match.dish.title)
                                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                                    .foregroundColor(Palette.ink)
                                                Text("\(Int(match.score * 100))% fridge fit · \(match.matchedIngredients.count) matched")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(Palette.muted)
                                            }
                                            Spacer()
                                        }
                                        .padding(.top, 6)
                                        if !match.missingIngredients.isEmpty {
                                            Text("Still need: " + match.missingIngredients.prefix(3).joined(separator: ", "))
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(Palette.muted)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .tabRootPadding()
            }
            .gardenPage()
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle("Fridge Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showTools = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showTools) {
                ToolsHubView()
                    .environmentObject(store)
            }
            .sheet(item: $detailDish) { dish in
                AuthorRecipeDetailView(dish: dish)
                    .environmentObject(store)
            }
            .onAppear {
                if matches.isEmpty && !store.fridgeItems.isEmpty {
                    matches = FridgePlanner.rankedMatches(fridgeItems: store.fridgeItems)
                }
            }
        }
    }

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "This week", subtitle: "Meals matched to your fridge")
            ForEach(WeekPlan.mondayFirst, id: \.weekday) { day in
                let entry = store.mealPlan.first { $0.weekday == day.weekday }
                PaperCard {
                    HStack(spacing: 12) {
                        Text(day.title)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.onPrimary)
                            .frame(width: 44, height: 44)
                            .background(Palette.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text((entry?.emojiSnapshot ?? "🗓️") + " " + (entry?.titleSnapshot ?? "Open slot"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundColor(Palette.ink)
                            Text(entry?.catalogDishID == nil ? "Generate a plan to fill this day" : "From your fridge match")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Palette.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 6)
                }
            }
        }
    }
}
