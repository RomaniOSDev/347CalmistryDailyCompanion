import SwiftUI
import UIKit

struct RecipeBookView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var ingredientQuery = ""
    @State private var expandedID: UUID?
    @State private var editorRecipe: Recipe?
    @State private var showEditor = false
    @State private var pendingDelete: Recipe?
    @State private var showDeleteConfirm = false
    @State private var cookRecipe: Recipe?
    @State private var ratingFilter: RatingFilter = .all
    @State private var servingFactor: Double = 1
    @State private var shopNotice: String?
    @State private var showTools = false

    private var filteredRecipes: [Recipe] {
        let query = ingredientQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.recipes.filter { recipe in
            switch ratingFilter {
            case .all:
                break
            case .threePlus:
                if store.rating(for: recipe.id) < 3 { return false }
            case .five:
                if store.rating(for: recipe.id) < 5 { return false }
            case .unrated:
                if store.rating(for: recipe.id) != 0 { return false }
            }
            if query.isEmpty { return true }
            return recipe.title.lowercased().contains(query)
                || recipe.cuisine.lowercased().contains(query)
                || recipe.ingredients.contains { $0.lowercased().contains(query) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureHero(
                        title: "My Kitchen",
                        subtitle: "Saved shelf dishes, imports, and recipes you wrote yourself.",
                        symbol: "fork.knife"
                    )

                    ratingChips
                    searchField

                    if store.recipes.isEmpty {
                        EmptyGarden(
                            title: "Kitchen is waiting",
                            systemImage: "fork.knife",
                            message: "Save a dish from the Shelf, import one, or tap + to write your own. Everything stays on this device."
                        )
                    } else if filteredRecipes.isEmpty {
                        EmptyGarden(
                            title: "No matches",
                            systemImage: "line.3.horizontal.decrease.circle",
                            message: "Nothing in your kitchen matches that filter or search."
                        )
                    } else {
                        ForEach(filteredRecipes) { recipe in
                            recipeRow(recipe)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .tabRootPadding()
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .gardenPage()
            .navigationTitle("Kitchen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showTools = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editorRecipe = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Palette.onPrimary)
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    }
                    .accessibilityLabel("Add recipe")
                }
            }
            .sheet(isPresented: $showEditor) {
                RecipeEditorSheet(recipe: editorRecipe)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showTools) {
                ToolsHubView()
                    .environmentObject(store)
            }
            .fullScreenCover(item: $cookRecipe) { recipe in
                CookModeView(recipeID: recipe.id)
                    .environmentObject(store)
            }
            .alert("Delete this recipe?", isPresented: $showDeleteConfirm, presenting: pendingDelete) { recipe in
                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    store.deleteRecipe(id: recipe.id)
                    if expandedID == recipe.id {
                        expandedID = nil
                    }
                    pendingDelete = nil
                }
            } message: { recipe in
                Text("“\(recipe.title)” will leave your kitchen.")
            }
        }
    }

    private var ratingChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RatingFilter.allCases) { filter in
                    SoftChip(title: filter.title, selected: ratingFilter == filter) {
                        ratingFilter = filter
                    }
                }
            }
        }
    }

    private var searchField: some View {
        FieldShell {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Palette.primary)
                TextField("Search your kitchen", text: $ingredientQuery)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(Palette.ink)
            }
        }
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        let isExpanded = expandedID == recipe.id
        return PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Text(recipe.emoji)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.title)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.ink)
                        HStack(spacing: 6) {
                            if !recipe.cuisine.isEmpty {
                                Text(recipe.cuisine)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Palette.muted)
                            }
                            if let source = recipe.sourceTag, !source.isEmpty {
                                Text(source.hasPrefix("shelf:") ? "From Shelf" : source)
                                    .font(.system(.caption2, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary.opacity(0.8))
                            }
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Palette.primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if expandedID == recipe.id {
                        expandedID = nil
                    } else {
                        expandedID = recipe.id
                        servingFactor = 1
                        shopNotice = nil
                        store.markActivity(viewedRecipeID: recipe.id)
                    }
                }

                if isExpanded {
                    RecipePhotoFrame(fileName: recipe.photoFileName)

                    let cooked = store.cookCount(for: recipe.id)
                    Button {
                        store.recordCook(recipeID: recipe.id)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Image(systemName: "fork.knife.circle.fill")
                            Text(cooked == 0 ? "Mark as cooked" : "Cooked \(cooked)× · again")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                            Spacer()
                        }
                        .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        cookRecipe = recipe
                    } label: {
                        HStack {
                            Image(systemName: "text.book.closed.fill")
                            Text("Open cook mode")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                            Spacer()
                        }
                        .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)

                    Text("Rating")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.ink)
                    LeafRatingRow(value: store.rating(for: recipe.id)) { value in
                        store.setRating(value, for: recipe.id)
                    }

                    ServingFactorPicker(factor: $servingFactor)

                    HStack {
                        Text("Ingredients")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.ink)
                        Spacer()
                        Button {
                            store.addIngredientsToShopping(
                                recipe.ingredients.map { ServingScale.apply($0, factor: servingFactor) },
                                recipeID: recipe.id
                            )
                            shopNotice = "Added to shopping list"
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text("Add to list")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, item in
                        Text("• \(ServingScale.apply(item, factor: servingFactor))")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Palette.muted)
                    }
                    if let shopNotice {
                        Text(shopNotice)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                    }

                    HStack {
                        Text("Steps")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.ink)
                        Spacer()
                        if !(store.checkedSteps[recipe.id.uuidString] ?? []).isEmpty {
                            Button("Reset checks") {
                                store.resetSteps(recipeID: recipe.id)
                            }
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.muted)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                        StepCheckRow(
                            index: index,
                            text: step,
                            isChecked: store.isStepChecked(recipeID: recipe.id, index: index)
                        ) {
                            store.toggleStep(recipeID: recipe.id, index: index)
                        }
                    }
                }
            }
            .padding(.top, 6)
        }
        .contextMenu {
            Button {
                editorRecipe = recipe
                showEditor = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                pendingDelete = recipe
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
