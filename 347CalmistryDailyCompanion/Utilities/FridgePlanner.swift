import Foundation

enum FridgePlanner {
    static func normalize(_ raw: String) -> String {
        raw
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func tokens(from raw: String) -> Set<String> {
        let stop: Set<String> = [
            "a", "an", "the", "of", "and", "or", "to", "with", "fresh", "large", "small",
            "cup", "cups", "tbsp", "tsp", "g", "kg", "ml", "l", "oz", "lb", "tin", "tins",
            "clove", "cloves", "bunch", "slice", "slices", "optional"
        ]
        let parts = normalize(raw).split(separator: " ").map(String.init)
        return Set(parts.filter { $0.count > 2 && !stop.contains($0) })
    }

    static func fridgeTokens(_ items: [FridgeItem]) -> Set<String> {
        items.reduce(into: Set<String>()) { result, item in
            result.formUnion(tokens(from: item.name))
            if !item.amountNote.isEmpty {
                result.formUnion(tokens(from: item.amountNote))
            }
        }
    }

    static func matchScore(dish: CatalogDish, fridge: Set<String>) -> RecipeMatch {
        var matched: [String] = []
        var missing: [String] = []
        for line in dish.ingredients {
            let lineTokens = tokens(from: line)
            if lineTokens.isEmpty {
                continue
            }
            if !lineTokens.isDisjoint(with: fridge) {
                matched.append(line)
            } else {
                missing.append(line)
            }
        }
        let total = max(matched.count + missing.count, 1)
        let score = Double(matched.count) / Double(total)
        return RecipeMatch(
            id: dish.id,
            dish: dish,
            score: score,
            matchedIngredients: matched,
            missingIngredients: missing
        )
    }

    static func rankedMatches(fridgeItems: [FridgeItem], limit: Int = 20) -> [RecipeMatch] {
        let fridge = fridgeTokens(fridgeItems)
        guard !fridge.isEmpty else { return [] }
        return AuthorCatalog.allDishes
            .map { matchScore(dish: $0, fridge: fridge) }
            .filter { $0.matchedIngredients.count > 0 }
            .sorted {
                if $0.score == $1.score {
                    return $0.matchedIngredients.count > $1.matchedIngredients.count
                }
                return $0.score > $1.score
            }
            .prefix(limit)
            .map { $0 }
    }

    static func buildWeekPlan(from matches: [RecipeMatch]) -> [MealPlanEntry] {
        var used = Set<String>()
        var plan: [MealPlanEntry] = []
        var index = 0
        for day in WeekPlan.mondayFirst {
            var chosen: RecipeMatch?
            while index < matches.count {
                let candidate = matches[index]
                index += 1
                if !used.contains(candidate.id) {
                    chosen = candidate
                    used.insert(candidate.id)
                    break
                }
            }
            if let chosen {
                plan.append(
                    MealPlanEntry(
                        weekday: day.weekday,
                        recipeID: nil,
                        catalogDishID: chosen.dish.id,
                        titleSnapshot: chosen.dish.title,
                        emojiSnapshot: chosen.dish.emoji
                    )
                )
            } else {
                plan.append(MealPlanEntry(weekday: day.weekday, recipeID: nil, catalogDishID: nil, titleSnapshot: nil, emojiSnapshot: nil))
            }
        }
        return plan
    }
}
