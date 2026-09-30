import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var emoji: String
    var cuisine: String
    var ingredients: [String]
    var instructions: [String]
    var photoFileName: String?
    var createdAt: Date
    var sourceTag: String?

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        cuisine: String,
        ingredients: [String],
        instructions: [String],
        photoFileName: String? = nil,
        createdAt: Date = Date(),
        sourceTag: String? = nil
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.cuisine = cuisine
        self.ingredients = ingredients
        self.instructions = instructions
        self.photoFileName = photoFileName
        self.createdAt = createdAt
        self.sourceTag = sourceTag
    }
}

struct CatalogDish: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    let cuisine: String
    let minutes: Int
    let blurb: String
    let ingredients: [String]
    let instructions: [String]
    let tags: [String]
}

struct FridgeItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var amountNote: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, amountNote: String = "", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.amountNote = amountNote
        self.createdAt = createdAt
    }
}

struct CookSession: Identifiable, Codable, Hashable {
    var id: UUID
    var recipeID: UUID
    var cookedAt: Date
}

struct ShoppingItem: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var isChecked: Bool
    var recipeID: UUID?
}

struct MealPlanEntry: Identifiable, Codable, Hashable {
    var weekday: Int
    var recipeID: UUID?
    var catalogDishID: String?
    var titleSnapshot: String?
    var emojiSnapshot: String?

    var id: Int { weekday }

    var displayTitle: String {
        titleSnapshot ?? "Open slot"
    }
}

struct KitchenTimerSlot: Identifiable, Codable, Hashable {
    var id: Int
    var label: String
    var durationSeconds: Int
    var endsAt: TimeInterval?
    var alarmConsumed: Bool

    var remaining: TimeInterval {
        guard let endsAt else { return 0 }
        return max(0, Date(timeIntervalSince1970: endsAt).timeIntervalSinceNow)
    }

    var isRunning: Bool {
        endsAt != nil && remaining > 0
    }

    var isFinished: Bool {
        endsAt != nil && remaining == 0
    }

    static var defaults: [KitchenTimerSlot] {
        [
            KitchenTimerSlot(id: 0, label: "Boil", durationSeconds: 8 * 60, endsAt: nil, alarmConsumed: true),
            KitchenTimerSlot(id: 1, label: "Roast", durationSeconds: 20 * 60, endsAt: nil, alarmConsumed: true),
            KitchenTimerSlot(id: 2, label: "Rest", durationSeconds: 5 * 60, endsAt: nil, alarmConsumed: true)
        ]
    }
}

enum RatingFilter: String, CaseIterable, Identifiable {
    case all
    case threePlus
    case five
    case unrated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .threePlus: return "3+ leaves"
        case .five: return "Top"
        case .unrated: return "Unrated"
        }
    }
}

enum WeekPlan {
    static let mondayFirst: [(weekday: Int, title: String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]
}

struct RecipeMatch: Identifiable, Hashable {
    let id: String
    let dish: CatalogDish
    let score: Double
    let matchedIngredients: [String]
    let missingIngredients: [String]
}
