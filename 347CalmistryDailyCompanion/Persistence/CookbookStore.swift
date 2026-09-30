import Combine
import Foundation

@MainActor
final class CookbookStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var fridgeItems: [FridgeItem] = []
    @Published var savedCatalogIDs: [String] = []
    @Published var themeLabels: [String] = []
    @Published var lastVisitedCategory: String = ""
    @Published var lastViewedRecipeID: String?
    @Published var cookSessions: [CookSession] = []
    @Published var ratings: [String: Int] = [:]
    @Published var checkedSteps: [String: [Int]] = [:]
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var mealPlan: [MealPlanEntry] = WeekPlan.mondayFirst.map {
        MealPlanEntry(weekday: $0.weekday)
    }
    @Published var timers: [KitchenTimerSlot] = KitchenTimerSlot.defaults
    @Published var hasCompletedOnboarding: Bool

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let recipes = "pantry.recipes"
        static let fridge = "pantry.fridgeItems"
        static let savedCatalog = "pantry.savedCatalogIDs"
        static let themeLabels = "pantry.themeLabels"
        static let lastVisitedCategory = "pantry.lastVisitedCategory"
        static let lastViewedRecipeID = "pantry.lastViewedRecipeID"
        static let cookSessions = "pantry.cookSessions"
        static let ratings = "pantry.ratings"
        static let checkedSteps = "pantry.checkedSteps"
        static let shoppingItems = "pantry.shoppingItems"
        static let mealPlan = "pantry.mealPlan"
        static let timers = "pantry.timers"
        static let onboarding = "pantry.hasCompletedOnboarding"

        static var all: [String] {
            [
                recipes, fridge, savedCatalog, themeLabels, lastVisitedCategory,
                lastViewedRecipeID, cookSessions, ratings, checkedSteps,
                shoppingItems, mealPlan, timers
            ]
        }
    }

    init() {
        hasCompletedOnboarding = defaults.bool(forKey: Key.onboarding)
        loadAll()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: Key.onboarding)
    }

    func addRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        recipes.insert(recipe, at: 0)
        sortRecipes()
        refreshThemeLabels()
        persistAll()
    }

    func updateRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            let previous = recipes[index]
            recipes[index] = recipe
            releasePhotoIfUnused(previous.photoFileName, keeping: recipe.photoFileName)
        } else {
            recipes.insert(recipe, at: 0)
        }
        sortRecipes()
        refreshThemeLabels()
        persistAll()
    }

    func deleteRecipe(id: UUID) {
        guard let recipe = recipes.first(where: { $0.id == id }) else { return }
        recipes.removeAll { $0.id == id }
        releasePhotoIfUnused(recipe.photoFileName, keeping: nil)
        if lastViewedRecipeID == id.uuidString {
            lastViewedRecipeID = nil
        }
        cookSessions.removeAll { $0.recipeID == id }
        ratings.removeValue(forKey: id.uuidString)
        checkedSteps.removeValue(forKey: id.uuidString)
        for index in mealPlan.indices where mealPlan[index].recipeID == id {
            mealPlan[index].recipeID = nil
        }
        refreshThemeLabels()
        persistAll()
    }

    func addFridgeItem(name: String, amountNote: String = "") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        fridgeItems.insert(
            FridgeItem(name: trimmed, amountNote: amountNote.trimmingCharacters(in: .whitespacesAndNewlines)),
            at: 0
        )
        persistFridge()
    }

    func removeFridgeItem(id: UUID) {
        fridgeItems.removeAll { $0.id == id }
        persistFridge()
    }

    func clearFridge() {
        fridgeItems = []
        persistFridge()
    }

    func generateWeekFromFridge() -> [RecipeMatch] {
        let matches = FridgePlanner.rankedMatches(fridgeItems: fridgeItems)
        mealPlan = FridgePlanner.buildWeekPlan(from: matches)
        persistMealPlan()
        return matches
    }

    func setMealDay(weekday: Int, match: RecipeMatch?) {
        guard let index = mealPlan.firstIndex(where: { $0.weekday == weekday }) else { return }
        if let match {
            mealPlan[index].catalogDishID = match.dish.id
            mealPlan[index].titleSnapshot = match.dish.title
            mealPlan[index].emojiSnapshot = match.dish.emoji
            mealPlan[index].recipeID = nil
        } else {
            mealPlan[index] = MealPlanEntry(weekday: weekday)
        }
        persistMealPlan()
    }

    func saveCatalogDish(_ dish: CatalogDish) -> Recipe {
        let recipe = Recipe(
            title: dish.title,
            emoji: dish.emoji,
            cuisine: dish.cuisine,
            ingredients: dish.ingredients,
            instructions: dish.instructions,
            sourceTag: "shelf:\(dish.id)"
        )
        addRecipe(recipe)
        if !savedCatalogIDs.contains(dish.id) {
            savedCatalogIDs.append(dish.id)
            persistCatalog()
        }
        markActivity(viewedRecipeID: recipe.id, category: AuthorCatalog.section(for: dish.id))
        return recipe
    }

    func toggleSavedCatalog(id: String) {
        if let index = savedCatalogIDs.firstIndex(of: id) {
            savedCatalogIDs.remove(at: index)
        } else {
            savedCatalogIDs.append(id)
        }
        persistCatalog()
    }

    func isSavedCatalog(_ id: String) -> Bool {
        savedCatalogIDs.contains(id)
    }

    func importDraft(_ draft: ImportedRecipeDraft) -> Recipe {
        let recipe = Recipe(
            title: draft.title,
            emoji: draft.emoji,
            cuisine: draft.cuisine,
            ingredients: draft.ingredients,
            instructions: draft.instructions,
            sourceTag: draft.sourceNote
        )
        addRecipe(recipe)
        return recipe
    }

    func setRating(_ value: Int, for recipeID: UUID) {
        if value <= 0 {
            ratings.removeValue(forKey: recipeID.uuidString)
        } else {
            ratings[recipeID.uuidString] = min(5, value)
        }
        persistAll()
    }

    func rating(for recipeID: UUID) -> Int {
        ratings[recipeID.uuidString] ?? 0
    }

    func toggleStep(recipeID: UUID, index: Int) {
        var steps = checkedSteps[recipeID.uuidString] ?? []
        if let existing = steps.firstIndex(of: index) {
            steps.remove(at: existing)
        } else {
            steps.append(index)
        }
        checkedSteps[recipeID.uuidString] = steps
        persistAll()
    }

    func isStepChecked(recipeID: UUID, index: Int) -> Bool {
        checkedSteps[recipeID.uuidString]?.contains(index) == true
    }

    func resetSteps(recipeID: UUID) {
        checkedSteps.removeValue(forKey: recipeID.uuidString)
        persistAll()
    }

    func addIngredientsToShopping(_ lines: [String], recipeID: UUID?) {
        for line in lines {
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            shoppingItems.append(ShoppingItem(id: UUID(), text: text, isChecked: false, recipeID: recipeID))
        }
        persistAll()
    }

    func addShoppingItem(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        shoppingItems.insert(ShoppingItem(id: UUID(), text: trimmed, isChecked: false, recipeID: nil), at: 0)
        persistAll()
    }

    func toggleShoppingItem(id: UUID) {
        guard let index = shoppingItems.firstIndex(where: { $0.id == id }) else { return }
        shoppingItems[index].isChecked.toggle()
        persistAll()
    }

    func clearCheckedShopping() {
        shoppingItems.removeAll { $0.isChecked }
        persistAll()
    }

    func startTimer(id: Int, seconds: Int) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].durationSeconds = seconds
        timers[index].endsAt = Date().addingTimeInterval(TimeInterval(seconds)).timeIntervalSince1970
        timers[index].alarmConsumed = false
        persistTimers()
    }

    func stopTimer(id: Int) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].endsAt = nil
        timers[index].alarmConsumed = true
        persistTimers()
    }

    func consumeTimerAlarms() -> [KitchenTimerSlot] {
        var finished: [KitchenTimerSlot] = []
        for index in timers.indices {
            if timers[index].isFinished && !timers[index].alarmConsumed {
                timers[index].alarmConsumed = true
                finished.append(timers[index])
            }
        }
        if !finished.isEmpty {
            persistTimers()
        }
        return finished
    }

    func recordCook(recipeID: UUID) {
        cookSessions.insert(CookSession(id: UUID(), recipeID: recipeID, cookedAt: Date()), at: 0)
        persistAll()
    }

    func cookCount(for recipeID: UUID) -> Int {
        cookSessions.filter { $0.recipeID == recipeID }.count
    }

    func recipe(id: UUID) -> Recipe? {
        recipes.first { $0.id == id }
    }

    func markActivity(viewedRecipeID: UUID? = nil, category: String? = nil) {
        if let viewedRecipeID {
            lastViewedRecipeID = viewedRecipeID.uuidString
        }
        if let category {
            lastVisitedCategory = category
        }
        persistMeta()
    }

    func resetAllData() {
        let photoNames = referencedPhotoNames()
        recipes = []
        fridgeItems = []
        savedCatalogIDs = []
        themeLabels = []
        lastVisitedCategory = ""
        lastViewedRecipeID = nil
        cookSessions = []
        ratings = [:]
        checkedSteps = [:]
        shoppingItems = []
        mealPlan = WeekPlan.mondayFirst.map { MealPlanEntry(weekday: $0.weekday) }
        timers = KitchenTimerSlot.defaults
        for key in Key.all {
            defaults.removeObject(forKey: key)
        }
        for name in photoNames {
            PhotoDisk.delete(name)
        }
    }

    private func loadAll() {
        recipes = decode([Recipe].self, key: Key.recipes) ?? []
        fridgeItems = decode([FridgeItem].self, key: Key.fridge) ?? []
        savedCatalogIDs = decode([String].self, key: Key.savedCatalog) ?? []
        themeLabels = decode([String].self, key: Key.themeLabels) ?? []
        lastVisitedCategory = defaults.string(forKey: Key.lastVisitedCategory) ?? ""
        lastViewedRecipeID = defaults.string(forKey: Key.lastViewedRecipeID)
        cookSessions = decode([CookSession].self, key: Key.cookSessions) ?? []
        ratings = decode([String: Int].self, key: Key.ratings) ?? [:]
        checkedSteps = decode([String: [Int]].self, key: Key.checkedSteps) ?? [:]
        shoppingItems = decode([ShoppingItem].self, key: Key.shoppingItems) ?? []
        if let savedPlan = decode([MealPlanEntry].self, key: Key.mealPlan), !savedPlan.isEmpty {
            mealPlan = WeekPlan.mondayFirst.map { day in
                savedPlan.first(where: { $0.weekday == day.weekday })
                    ?? MealPlanEntry(weekday: day.weekday)
            }
        }
        if let savedTimers = decode([KitchenTimerSlot].self, key: Key.timers), savedTimers.count == 3 {
            timers = savedTimers
        }
        sortRecipes()
        cookSessions.sort { $0.cookedAt > $1.cookedAt }
        refreshThemeLabels()
    }

    private func persistAll() {
        encode(recipes, key: Key.recipes)
        encode(cookSessions, key: Key.cookSessions)
        encode(ratings, key: Key.ratings)
        encode(checkedSteps, key: Key.checkedSteps)
        encode(shoppingItems, key: Key.shoppingItems)
        persistFridge()
        persistCatalog()
        persistMealPlan()
        persistTimers()
        persistMeta()
    }

    private func persistFridge() {
        encode(fridgeItems, key: Key.fridge)
    }

    private func persistCatalog() {
        encode(savedCatalogIDs, key: Key.savedCatalog)
    }

    private func persistMealPlan() {
        encode(mealPlan, key: Key.mealPlan)
    }

    private func persistMeta() {
        encode(themeLabels, key: Key.themeLabels)
        defaults.set(lastVisitedCategory, forKey: Key.lastVisitedCategory)
        if let lastViewedRecipeID {
            defaults.set(lastViewedRecipeID, forKey: Key.lastViewedRecipeID)
        } else {
            defaults.removeObject(forKey: Key.lastViewedRecipeID)
        }
    }

    private func persistTimers() {
        encode(timers, key: Key.timers)
    }

    private func refreshThemeLabels() {
        themeLabels = Array(
            Set(
                recipes
                    .map { $0.cuisine.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        ).sorted()
        encode(themeLabels, key: Key.themeLabels)
    }

    private func sortRecipes() {
        recipes.sort { $0.createdAt > $1.createdAt }
    }

    private func referencedPhotoNames() -> Set<String> {
        Set(recipes.compactMap { $0.photoFileName }.filter { !$0.isEmpty })
    }

    private func isPhotoReferenced(_ fileName: String) -> Bool {
        recipes.contains { $0.photoFileName == fileName }
    }

    private func releasePhotoIfUnused(_ oldName: String?, keeping newName: String?) {
        guard let oldName, !oldName.isEmpty else { return }
        if let newName, oldName == newName { return }
        if !isPhotoReferenced(oldName) {
            PhotoDisk.delete(oldName)
        }
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            defaults.removeObject(forKey: key)
            return nil
        }
    }
}
