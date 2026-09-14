import Combine
import Foundation

@MainActor
final class CookbookStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var captions: [CaptionEntry] = []
    @Published var favouriteSampleIDs: [String] = []
    @Published var themeLabels: [String] = []
    @Published var lastEditedCaptionDate: Date?
    @Published var lastVisitedCategory: String = ""
    @Published var lastViewedRecipeID: String?
    @Published var cookSessions: [CookSession] = []
    @Published var ratings: [String: Int] = [:]
    @Published var checkedSteps: [String: [Int]] = [:]
    @Published var shoppingItems: [ShoppingItem] = []
    @Published var leftovers: [LeftoverNote] = []
    @Published var mealPlan: [MealPlanEntry] = WeekPlan.mondayFirst.map { MealPlanEntry(weekday: $0.weekday, recipeID: nil) }
    @Published var timers: [KitchenTimerSlot] = KitchenTimerSlot.defaults

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let recipes = "cookbook.recipes"
        static let captions = "cookbook.captions"
        static let favourites = "cookbook.favouriteSampleIDs"
        static let themeLabels = "cookbook.themeLabels"
        static let lastEditedCaptionDate = "cookbook.lastEditedCaptionDate"
        static let lastVisitedCategory = "cookbook.lastVisitedCategory"
        static let lastViewedRecipeID = "cookbook.lastViewedRecipeID"
        static let cookSessions = "cookbook.cookSessions"
        static let ratings = "cookbook.ratings"
        static let checkedSteps = "cookbook.checkedSteps"
        static let shoppingItems = "cookbook.shoppingItems"
        static let leftovers = "cookbook.leftovers"
        static let mealPlan = "cookbook.mealPlan"
        static let timers = "cookbook.timers"

        static var all: [String] {
            [
                recipes,
                captions,
                favourites,
                themeLabels,
                lastEditedCaptionDate,
                lastVisitedCategory,
                lastViewedRecipeID,
                cookSessions,
                ratings,
                checkedSteps,
                shoppingItems,
                leftovers,
                mealPlan,
                timers
            ]
        }
    }

    init() {
        loadAll()
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
        let orphaned = captions.filter { $0.recipeID == id }
        captions.removeAll { $0.recipeID == id }
        releasePhotoIfUnused(recipe.photoFileName, keeping: nil)
        for caption in orphaned {
            releasePhotoIfUnused(caption.photoFileName, keeping: nil)
        }
        if lastViewedRecipeID == id.uuidString {
            lastViewedRecipeID = nil
        }
        cookSessions.removeAll { $0.recipeID == id }
        ratings.removeValue(forKey: id.uuidString)
        checkedSteps.removeValue(forKey: id.uuidString)
        for index in mealPlan.indices where mealPlan[index].recipeID == id {
            mealPlan[index].recipeID = nil
        }
        for index in leftovers.indices where leftovers[index].recipeID == id {
            leftovers[index].recipeID = nil
        }
        refreshThemeLabels()
        persistAll()
    }

    func setRating(_ value: Int, for recipeID: UUID) {
        let clamped = max(0, min(5, value))
        if clamped == 0 {
            ratings.removeValue(forKey: recipeID.uuidString)
        } else {
            ratings[recipeID.uuidString] = clamped
        }
        persistAll()
    }

    func rating(for recipeID: UUID) -> Int {
        ratings[recipeID.uuidString] ?? 0
    }

    func toggleStep(recipeID: UUID, index: Int) {
        var current = Set(checkedSteps[recipeID.uuidString] ?? [])
        if current.contains(index) {
            current.remove(index)
        } else {
            current.insert(index)
        }
        checkedSteps[recipeID.uuidString] = Array(current).sorted()
        persistAll()
    }

    func isStepChecked(recipeID: UUID, index: Int) -> Bool {
        (checkedSteps[recipeID.uuidString] ?? []).contains(index)
    }

    func resetSteps(recipeID: UUID) {
        checkedSteps.removeValue(forKey: recipeID.uuidString)
        persistAll()
    }

    func addIngredientsToShopping(_ lines: [String], recipeID: UUID?) {
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if shoppingItems.contains(where: { $0.text.caseInsensitiveCompare(trimmed) == .orderedSame && !$0.isChecked }) {
                continue
            }
            shoppingItems.append(
                ShoppingItem(id: UUID(), text: trimmed, isChecked: false, recipeID: recipeID)
            )
        }
        persistAll()
    }

    func addShoppingItem(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        shoppingItems.append(ShoppingItem(id: UUID(), text: trimmed, isChecked: false, recipeID: nil))
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

    func addLeftover(leftover: String, idea: String, recipeID: UUID?) {
        let leftoverText = leftover.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !leftoverText.isEmpty else { return }
        leftovers.insert(
            LeftoverNote(
                id: UUID(),
                leftover: leftoverText,
                idea: idea.trimmingCharacters(in: .whitespacesAndNewlines),
                recipeID: recipeID,
                createdAt: Date()
            ),
            at: 0
        )
        persistAll()
    }

    func deleteLeftover(id: UUID) {
        leftovers.removeAll { $0.id == id }
        persistAll()
    }

    func setMeal(weekday: Int, recipeID: UUID?) {
        if let index = mealPlan.firstIndex(where: { $0.weekday == weekday }) {
            mealPlan[index].recipeID = recipeID
        } else {
            mealPlan.append(MealPlanEntry(weekday: weekday, recipeID: recipeID))
        }
        persistAll()
    }

    func startTimer(id: Int, seconds: Int) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].durationSeconds = max(30, seconds)
        timers[index].endsAt = Date().addingTimeInterval(TimeInterval(timers[index].durationSeconds)).timeIntervalSince1970
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
        guard recipes.contains(where: { $0.id == recipeID }) else { return }
        cookSessions.insert(
            CookSession(id: UUID(), recipeID: recipeID, cookedAt: Date()),
            at: 0
        )
        persistAll()
    }

    func cookCount(for recipeID: UUID) -> Int {
        cookSessions.filter { $0.recipeID == recipeID }.count
    }

    func addCaption(_ caption: CaptionEntry) {
        captions.removeAll { $0.id == caption.id }
        captions.insert(caption, at: 0)
        sortCaptions()
        markActivity(captionTouched: true)
        persistAll()
    }

    func updateCaption(_ caption: CaptionEntry) {
        if let index = captions.firstIndex(where: { $0.id == caption.id }) {
            let previous = captions[index]
            captions[index] = caption
            releasePhotoIfUnused(previous.photoFileName, keeping: caption.photoFileName)
        } else {
            captions.insert(caption, at: 0)
        }
        sortCaptions()
        markActivity(captionTouched: true)
        persistAll()
    }

    func importSample(_ dish: SampleDish) -> Recipe {
        let recipe = Recipe(
            id: UUID(),
            title: dish.title,
            emoji: dish.emoji,
            cuisine: dish.cuisine,
            ingredients: dish.ingredients,
            instructions: dish.instructions,
            photoFileName: nil,
            createdAt: Date()
        )
        addRecipe(recipe)
        markActivity(viewedRecipeID: recipe.id)
        return recipe
    }

    func toggleFavourite(sampleID: String) {
        if let index = favouriteSampleIDs.firstIndex(of: sampleID) {
            favouriteSampleIDs.remove(at: index)
        } else {
            favouriteSampleIDs.append(sampleID)
        }
        persistAll()
    }

    func isFavourite(_ sampleID: String) -> Bool {
        favouriteSampleIDs.contains(sampleID)
    }

    func recipe(id: UUID) -> Recipe? {
        recipes.first { $0.id == id }
    }

    func markActivity(viewedRecipeID: UUID? = nil, captionTouched: Bool = false, category: String? = nil) {
        if let viewedRecipeID {
            lastViewedRecipeID = viewedRecipeID.uuidString
        }
        if captionTouched {
            lastEditedCaptionDate = Date()
        }
        if let category {
            lastVisitedCategory = category
        }
        persistMeta()
    }

    func resetAllData() {
        let photoNames = referencedPhotoNames()
        recipes = []
        captions = []
        favouriteSampleIDs = []
        themeLabels = []
        lastEditedCaptionDate = nil
        lastVisitedCategory = ""
        lastViewedRecipeID = nil
        cookSessions = []
        ratings = [:]
        checkedSteps = [:]
        shoppingItems = []
        leftovers = []
        mealPlan = WeekPlan.mondayFirst.map { MealPlanEntry(weekday: $0.weekday, recipeID: nil) }
        timers = KitchenTimerSlot.defaults
        for key in Key.all {
            defaults.removeObject(forKey: key)
        }
        for name in photoNames {
            PhotoDisk.delete(name)
        }
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private func loadAll() {
        recipes = decode([Recipe].self, key: Key.recipes) ?? []
        captions = decode([CaptionEntry].self, key: Key.captions) ?? []
        favouriteSampleIDs = decode([String].self, key: Key.favourites) ?? []
        themeLabels = decode([String].self, key: Key.themeLabels) ?? []
        lastVisitedCategory = defaults.string(forKey: Key.lastVisitedCategory) ?? ""
        lastViewedRecipeID = defaults.string(forKey: Key.lastViewedRecipeID)
        cookSessions = decode([CookSession].self, key: Key.cookSessions) ?? []
        ratings = decode([String: Int].self, key: Key.ratings) ?? [:]
        checkedSteps = decode([String: [Int]].self, key: Key.checkedSteps) ?? [:]
        shoppingItems = decode([ShoppingItem].self, key: Key.shoppingItems) ?? []
        leftovers = decode([LeftoverNote].self, key: Key.leftovers) ?? []
        if let savedPlan = decode([MealPlanEntry].self, key: Key.mealPlan), !savedPlan.isEmpty {
            mealPlan = WeekPlan.mondayFirst.map { day in
                savedPlan.first(where: { $0.weekday == day.weekday })
                    ?? MealPlanEntry(weekday: day.weekday, recipeID: nil)
            }
        }
        if let savedTimers = decode([KitchenTimerSlot].self, key: Key.timers), savedTimers.count == 3 {
            timers = savedTimers
        }
        if let interval = defaults.object(forKey: Key.lastEditedCaptionDate) as? TimeInterval {
            lastEditedCaptionDate = Date(timeIntervalSince1970: interval)
        } else {
            lastEditedCaptionDate = nil
        }
        sortRecipes()
        sortCaptions()
        cookSessions.sort { $0.cookedAt > $1.cookedAt }
        refreshThemeLabels()
    }

    private func persistAll() {
        encode(recipes, key: Key.recipes)
        encode(captions, key: Key.captions)
        encode(favouriteSampleIDs, key: Key.favourites)
        encode(cookSessions, key: Key.cookSessions)
        encode(ratings, key: Key.ratings)
        encode(checkedSteps, key: Key.checkedSteps)
        encode(shoppingItems, key: Key.shoppingItems)
        encode(leftovers, key: Key.leftovers)
        encode(mealPlan, key: Key.mealPlan)
        persistTimers()
        persistMeta()
    }

    private func persistMeta() {
        encode(themeLabels, key: Key.themeLabels)
        defaults.set(lastVisitedCategory, forKey: Key.lastVisitedCategory)
        if let lastViewedRecipeID {
            defaults.set(lastViewedRecipeID, forKey: Key.lastViewedRecipeID)
        } else {
            defaults.removeObject(forKey: Key.lastViewedRecipeID)
        }
        if let lastEditedCaptionDate {
            defaults.set(lastEditedCaptionDate.timeIntervalSince1970, forKey: Key.lastEditedCaptionDate)
        } else {
            defaults.removeObject(forKey: Key.lastEditedCaptionDate)
        }
    }

    private func persistTimers() {
        encode(timers, key: Key.timers)
    }

    private func refreshThemeLabels() {
        let labels = Array(
            Set(
                recipes
                    .map { $0.cuisine.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        ).sorted()
        themeLabels = labels
        encode(themeLabels, key: Key.themeLabels)
    }

    private func sortRecipes() {
        recipes.sort { $0.createdAt > $1.createdAt }
    }

    private func sortCaptions() {
        captions.sort { $0.updatedAt > $1.updatedAt }
    }

    private func referencedPhotoNames() -> Set<String> {
        var names = Set<String>()
        for recipe in recipes {
            if let name = recipe.photoFileName, !name.isEmpty {
                names.insert(name)
            }
        }
        for caption in captions {
            if let name = caption.photoFileName, !name.isEmpty {
                names.insert(name)
            }
        }
        return names
    }

    private func isPhotoReferenced(_ fileName: String) -> Bool {
        recipes.contains { $0.photoFileName == fileName }
            || captions.contains { $0.photoFileName == fileName }
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
