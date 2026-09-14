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
}

struct CaptionEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var recipeID: UUID
    var text: String
    var photoFileName: String?
    var updatedAt: Date
}

struct SampleDish: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var emoji: String
    var cuisine: String
    var blurb: String
    var ingredients: [String]
    var instructions: [String]
}

struct Favourite: Identifiable, Codable, Hashable {
    var id: String
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

struct LeftoverNote: Identifiable, Codable, Hashable {
    var id: UUID
    var leftover: String
    var idea: String
    var recipeID: UUID?
    var createdAt: Date
}

struct MealPlanEntry: Identifiable, Codable, Hashable {
    var weekday: Int
    var recipeID: UUID?

    var id: Int { weekday }
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
            KitchenTimerSlot(id: 0, label: "Pasta", durationSeconds: 8 * 60, endsAt: nil, alarmConsumed: true),
            KitchenTimerSlot(id: 1, label: "Oven", durationSeconds: 20 * 60, endsAt: nil, alarmConsumed: true),
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
        case .five: return "Best"
        case .unrated: return "Unrated"
        }
    }
}

enum WeekPlan {
    static let mondayFirst: [(weekday: Int, title: String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]
}

enum TasteLibrary {
    static let themeTitles = [
        "Italian Classics",
        "Quick Weeknight",
        "Market Bowl"
    ]

    static let dishesByTheme: [String: [SampleDish]] = [
        "Italian Classics": [
            SampleDish(
                id: "sun-basil-tagliatelle",
                title: "Sun Basil Tagliatelle",
                emoji: "🍝",
                cuisine: "Italian",
                blurb: "Silky ribbons tossed with blistered tomatoes and a handful of torn basil.",
                ingredients: [
                    "280g tagliatelle",
                    "3 ripe tomatoes",
                    "2 garlic cloves",
                    "A bunch of basil",
                    "Olive oil",
                    "Sea salt"
                ],
                instructions: [
                    "Boil the pasta until just tender, then keep a cup of the cooking water.",
                    "Warm oil and garlic, then tumble in chopped tomatoes until they slump.",
                    "Toss pasta through the sauce with basil and a splash of cooking water."
                ]
            ),
            SampleDish(
                id: "charred-lemon-risotto",
                title: "Charred Lemon Risotto",
                emoji: "🍋",
                cuisine: "Italian",
                blurb: "Creamy rice finished with lemon that has seen a hot pan.",
                ingredients: [
                    "200g arborio rice",
                    "1 lemon",
                    "1 small onion",
                    "700ml warm stock",
                    "Parmesan",
                    "Butter"
                ],
                instructions: [
                    "Char lemon halves in a dry pan until fragrant, then set aside.",
                    "Soften onion in butter, stir in rice, and add stock a ladle at a time.",
                    "Finish with squeezed charred lemon, cheese, and a last knob of butter."
                ]
            ),
            SampleDish(
                id: "roasted-pepper-bruschetta",
                title: "Roasted Pepper Bruschetta",
                emoji: "🫑",
                cuisine: "Italian",
                blurb: "Toasted bread piled with sweet peppers, capers, and olive oil.",
                ingredients: [
                    "1 ciabatta loaf",
                    "2 red peppers",
                    "1 tbsp capers",
                    "Garlic clove",
                    "Olive oil",
                    "Parsley"
                ],
                instructions: [
                    "Roast peppers until the skins wrinkle, then peel and slice.",
                    "Toast thick bread slices and rub with the cut garlic.",
                    "Pile on peppers, capers, parsley, and a thread of oil."
                ]
            )
        ],
        "Quick Weeknight": [
            SampleDish(
                id: "skillet-garlic-prawns",
                title: "Skillet Garlic Prawns",
                emoji: "🍤",
                cuisine: "Coastal",
                blurb: "A one-pan supper ready before the table is even set.",
                ingredients: [
                    "300g prawns",
                    "4 garlic cloves",
                    "Chili flakes",
                    "Lemon",
                    "Parsley",
                    "Olive oil"
                ],
                instructions: [
                    "Heat oil until it shimmers, then add sliced garlic and chili.",
                    "Tip in prawns and cook until they just curl and turn pink.",
                    "Finish with lemon and parsley, and serve straight from the skillet."
                ]
            ),
            SampleDish(
                id: "sesame-ginger-noodles",
                title: "Sesame Ginger Noodles",
                emoji: "🍜",
                cuisine: "Pantry",
                blurb: "Cold-start sauce, hot noodles, dinner in a single bowl.",
                ingredients: [
                    "200g wheat noodles",
                    "2 tbsp sesame paste",
                    "1 tbsp grated ginger",
                    "Soy sauce",
                    "Cucumber",
                    "Toasted sesame"
                ],
                instructions: [
                    "Whisk sesame paste, ginger, and soy with a splash of warm water.",
                    "Boil noodles, drain, and rinse briefly so they stay springy.",
                    "Toss with the sauce, then add cucumber ribbons and sesame."
                ]
            ),
            SampleDish(
                id: "herb-omelette-toast",
                title: "Herb Omelette Toast",
                emoji: "🍳",
                cuisine: "Home",
                blurb: "Eggs folded over garden herbs and slipped onto crisp toast.",
                ingredients: [
                    "3 eggs",
                    "Mixed soft herbs",
                    "Butter",
                    "Sourdough slices",
                    "Black pepper",
                    "Chives"
                ],
                instructions: [
                    "Beat eggs with chopped herbs and a pinch of pepper.",
                    "Cook gently in butter, folding once the centre is just set.",
                    "Slide onto toasted sourdough and finish with chives."
                ]
            )
        ],
        "Market Bowl": [
            SampleDish(
                id: "harvest-grain-bowl",
                title: "Harvest Grain Bowl",
                emoji: "🥗",
                cuisine: "Market",
                blurb: "Roasted roots, warm grains, and a sharp herb dressing.",
                ingredients: [
                    "150g cooked farro",
                    "1 beetroot",
                    "1 carrot",
                    "Leafy greens",
                    "Yogurt",
                    "Dill"
                ],
                instructions: [
                    "Roast cubed beetroot and carrot until the edges caramelise.",
                    "Stir dill through yogurt with a squeeze of lemon.",
                    "Layer grains, greens, and roast vegetables, then spoon on the dressing."
                ]
            ),
            SampleDish(
                id: "citrus-chickpea-bowl",
                title: "Citrus Chickpea Bowl",
                emoji: "🍊",
                cuisine: "Market",
                blurb: "Bright segments, crisp chickpeas, and a maple mustard drizzle.",
                ingredients: [
                    "1 tin chickpeas",
                    "1 orange",
                    "Radishes",
                    "Baby spinach",
                    "Maple syrup",
                    "Mustard"
                ],
                instructions: [
                    "Pat chickpeas dry and roast until they rattle and crisp.",
                    "Segment the orange and slice radishes thinly.",
                    "Toss spinach with maple mustard, then top with chickpeas and fruit."
                ]
            )
        ]
    ]

    static var allDishes: [SampleDish] {
        themeTitles.flatMap { title in
            dishesByTheme[title] ?? []
        }
    }

    static func theme(for dishID: String) -> String? {
        for title in themeTitles {
            if dishesByTheme[title]?.contains(where: { $0.id == dishID }) == true {
                return title
            }
        }
        return nil
    }

    static func dish(id: String) -> SampleDish? {
        allDishes.first { $0.id == id }
    }
}
