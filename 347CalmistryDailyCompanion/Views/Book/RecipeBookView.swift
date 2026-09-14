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
                VStack(alignment: .leading, spacing: 14) {
                    TasteBanner(assetName: "BannerJournal")
                        .clipShape(TornPaperShape())
                        .shadow(color: Palette.background.opacity(0.32), radius: 8, x: 0, y: 4)

                    header

                    ratingChips

                    searchField

                    if store.recipes.isEmpty {
                        EmptyGarden(
                            title: "No Recipes Yet",
                            systemImage: "book",
                            message: "Start a page for a dish you love. Add a title, at least one ingredient, and one step."
                        )
                    } else if filteredRecipes.isEmpty {
                        EmptyGarden(
                            title: "Nothing Matches",
                            systemImage: "leaf.circle",
                            message: "No dish title, cuisine, or ingredient matches that search."
                        )
                    } else {
                        ForEach(filteredRecipes) { recipe in
                            recipeRow(recipe)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .gardenPage()
            .navigationTitle("Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editorRecipe = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Palette.primary)
                    }
                    .accessibilityLabel("Add recipe")
                }
            }
            .sheet(isPresented: $showEditor) {
                RecipeEditorSheet(recipe: editorRecipe)
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
                Text("“\(recipe.title)” will be removed from your book.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recipe Book")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(Palette.primary)
            Text("Tap a card to unfold ingredients and steps.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Palette.accent)
        }
    }

    private var ratingChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RatingFilter.allCases) { filter in
                    Button {
                        ratingFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(ratingFilter == filter ? Palette.surface : Palette.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ratingFilter == filter ? Palette.primary : Palette.surface)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf")
                .foregroundColor(Palette.primary)
            TextField("Search title, cuisine, ingredient", text: $ingredientQuery)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Palette.primary)
        }
        .padding(11)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.primary.opacity(0.22), lineWidth: 1)
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
                            .foregroundColor(Palette.primary)
                        HStack(spacing: 6) {
                            if !recipe.cuisine.isEmpty {
                                Text(recipe.cuisine)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Palette.accent)
                            }
                            if store.rating(for: recipe.id) > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<store.rating(for: recipe.id), id: \.self) { _ in
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(Palette.primary)
                                    }
                                }
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
                            Text(cooked == 0 ? "I cooked this" : "Cooked \(cooked)× · again")
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
                            Text("Cook Mode")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                            Spacer()
                        }
                        .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)

                    Text("Taste")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.primary)
                    LeafRatingRow(value: store.rating(for: recipe.id)) { value in
                        store.setRating(value, for: recipe.id)
                    }

                    ServingFactorPicker(factor: $servingFactor)

                    HStack {
                        Text("Ingredients")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
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
                            .foregroundColor(Palette.accent)
                    }
                    if let shopNotice {
                        Text(shopNotice)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                    }

                    HStack {
                        Text("Steps")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        Spacer()
                        if !(store.checkedSteps[recipe.id.uuidString] ?? []).isEmpty {
                            Button("Reset checks") {
                                store.resetSteps(recipeID: recipe.id)
                            }
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.accent)
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
