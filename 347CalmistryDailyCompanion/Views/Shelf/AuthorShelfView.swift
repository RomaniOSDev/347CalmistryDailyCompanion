import SwiftUI

struct AuthorShelfView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var query = ""
    @State private var selectedSection = AuthorCatalog.sectionTitles[0]
    @State private var detailDish: CatalogDish?

    private var filtered: [CatalogDish] {
        let base = AuthorCatalog.dishes(in: selectedSection)
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.title.lowercased().contains(q)
                || $0.cuisine.lowercased().contains(q)
                || $0.ingredients.joined(separator: " ").lowercased().contains(q)
                || $0.tags.contains { $0.contains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureHero(
                        title: "Author Shelf",
                        subtitle: "\(AuthorCatalog.allDishes.count) original offline recipes across six kitchen moods.",
                        symbol: "books.vertical.fill"
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AuthorCatalog.sectionTitles, id: \.self) { section in
                                SoftChip(title: section, selected: selectedSection == section) {
                                    selectedSection = section
                                    store.markActivity(category: section)
                                }
                            }
                        }
                    }

                    FieldShell {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Palette.primary)
                            TextField("Search shelf…", text: $query)
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundColor(Palette.ink)
                        }
                    }

                    if filtered.isEmpty {
                        EmptyGarden(
                            title: "No dishes in this cut",
                            systemImage: "magnifyingglass",
                            message: "Try another section or clear the search to see the full authored shelf."
                        )
                    } else {
                        ForEach(filtered) { dish in
                            Button {
                                detailDish = dish
                            } label: {
                                PaperCard {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text(dish.emoji)
                                            .font(.system(size: 34))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(dish.title)
                                                .font(.system(.headline, design: .rounded).weight(.bold))
                                                .foregroundColor(Palette.ink)
                                            Text("\(dish.cuisine) · \(dish.minutes) min")
                                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                                .foregroundColor(Palette.muted)
                                            Text(dish.blurb)
                                                .font(.system(.footnote, design: .rounded))
                                                .foregroundColor(Palette.muted)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer(minLength: 0)
                                        if store.isSavedCatalog(dish.id) {
                                            Image(systemName: "bookmark.fill")
                                                .foregroundColor(Palette.primary)
                                        }
                                    }
                                    .padding(.top, 6)
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
            .navigationTitle("Shelf")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $detailDish) { dish in
                AuthorRecipeDetailView(dish: dish)
                    .environmentObject(store)
            }
            .onAppear {
                if !store.lastVisitedCategory.isEmpty,
                   AuthorCatalog.sectionTitles.contains(store.lastVisitedCategory) {
                    selectedSection = store.lastVisitedCategory
                }
            }
        }
    }
}

struct AuthorRecipeDetailView: View {
    @EnvironmentObject private var store: CookbookStore
    @Environment(\.dismiss) private var dismiss
    let dish: CatalogDish
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PaperCard(emphasized: true) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Text(dish.emoji)
                                    .font(.system(size: 48))
                                    .padding(10)
                                    .background(Palette.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dish.title)
                                        .font(.system(.title2, design: .rounded).weight(.bold))
                                        .foregroundColor(Palette.ink)
                                    Text("\(dish.cuisine) · \(dish.minutes) minutes")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(Palette.muted)
                                }
                            }
                            Text(dish.blurb)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Palette.muted)
                        }
                    }

                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.ink)
                                .padding(.top, 6)
                            ForEach(dish.ingredients, id: \.self) { line in
                                Text("• \(line)")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(Palette.ink.opacity(0.85))
                            }
                        }
                    }

                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Method")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.ink)
                                .padding(.top, 6)
                            ForEach(Array(dish.instructions.enumerated()), id: \.offset) { index, line in
                                Text("\(index + 1). \(line)")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(Palette.ink.opacity(0.85))
                            }
                        }
                    }

                    Button {
                        _ = store.saveCatalogDish(dish)
                        notice = "Saved to Kitchen"
                    } label: {
                        PrimaryButtonLabel(title: "Save to my Kitchen")
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.toggleSavedCatalog(id: dish.id)
                    } label: {
                        Text(store.isSavedCatalog(dish.id) ? "Remove bookmark" : "Bookmark on Shelf")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Palette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Palette.hairline, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)

                    if let notice {
                        Text(notice)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.onPrimary)
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    }
                }
                .padding(16)
            }
            .gardenPage()
            .background { PantryCanvas() }
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .background { PantryCanvas() }
    }
}
