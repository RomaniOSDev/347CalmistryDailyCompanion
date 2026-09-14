import Charts
import SwiftUI
import UIKit

struct KitchenStatsView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var surprise: Recipe?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TasteBanner(assetName: "BannerJournal")
                        .clipShape(TornPaperShape())
                        .shadow(color: Palette.background.opacity(0.32), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kitchen Stats")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        Text("How your book, notes, and cooked meals grow over time.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Palette.accent)
                    }

                    summaryGrid

                    if hasChartData {
                        activityCard
                        cuisineCard
                        mixCard
                        ratingCard
                        topCooksCard
                        topRatedCard
                    } else {
                        EmptyGarden(
                            title: "No kitchen rhythm yet",
                            systemImage: "chart.bar",
                            message: "Add a recipe, write a caption, or mark a dish as cooked to see graphs here."
                        )
                    }

                    surpriseCard
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .gardenPage()
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var hasChartData: Bool {
        !store.recipes.isEmpty || !store.captions.isEmpty || !store.cookSessions.isEmpty
    }

    private var summaryGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                statTile(title: "Recipes", value: "\(store.recipes.count)", symbol: "book.fill")
                statTile(title: "Notes", value: "\(store.captions.count)", symbol: "pencil")
            }
            HStack(spacing: 10) {
                statTile(title: "Cooked", value: "\(store.cookSessions.count)", symbol: "fork.knife")
                statTile(title: "Saved", value: "\(store.favouriteSampleIDs.count)", symbol: "heart.fill")
            }
        }
    }

    private func statTile(title: String, value: String, symbol: String) -> some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Palette.primary)
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.accent)
            }
        }
    }

    private var activityCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Last 14 days")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                Text("New recipes, captions, and cooked meals.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Palette.accent)

                Chart(activityBars) { bar in
                    BarMark(
                        x: .value("Day", bar.day, unit: .day),
                        y: .value("Count", bar.value)
                    )
                    .foregroundStyle(by: .value("Kind", bar.kind))
                    .cornerRadius(3)
                }
                .chartForegroundStyleScale([
                    "Recipes": Palette.primary,
                    "Notes": Color(red: 0.95, green: 0.78, blue: 0.38),
                    "Cooked": Color.white.opacity(0.92)
                ])
                .chartLegend(position: .bottom, alignment: .leading)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Palette.primary.opacity(0.18))
                        AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                            .foregroundStyle(Palette.accent)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Palette.primary.opacity(0.12))
                        AxisValueLabel()
                            .foregroundStyle(Palette.accent)
                    }
                }
                .frame(height: 180)
            }
        }
    }

    private var cuisineCard: some View {
        let rows = cuisineRows
        return Group {
            if !rows.isEmpty {
                PaperCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cuisines in your book")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)

                        Chart(rows) { row in
                            BarMark(
                                x: .value("Dishes", row.count),
                                y: .value("Cuisine", row.name)
                            )
                            .foregroundStyle(Palette.primary)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Palette.primary.opacity(0.12))
                                AxisValueLabel()
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Palette.primary)
                            }
                        }
                        .frame(height: CGFloat(max(120, rows.count * 36)))
                    }
                }
            }
        }
    }

    private var mixCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Kitchen mix")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)

                Chart(mixSlices) { slice in
                    BarMark(
                        x: .value("Count", slice.value)
                    )
                    .foregroundStyle(by: .value("Kind", slice.name))
                    .cornerRadius(6)
                }
                .chartForegroundStyleScale([
                    "Recipes": Palette.primary,
                    "Notes": Color(red: 0.95, green: 0.78, blue: 0.38),
                    "Cooked": Color.white.opacity(0.92)
                ])
                .chartLegend(position: .bottom, alignment: .leading)
                .chartXAxis(.hidden)
                .frame(height: 44)
            }
        }
    }

    private var ratingCard: some View {
        let rows = ratingRows
        return Group {
            if !rows.isEmpty {
                PaperCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Taste scores")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        Chart(rows) { row in
                            BarMark(
                                x: .value("Leaves", row.label),
                                y: .value("Dishes", row.count)
                            )
                            .foregroundStyle(Palette.primary)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Palette.primary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Palette.primary.opacity(0.12))
                                AxisValueLabel()
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        .frame(height: 140)
                    }
                }
            }
        }
    }

    private var topRatedCard: some View {
        let rows = topRatedRecipes
        return Group {
            if !rows.isEmpty {
                PaperCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What turned out best")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        ForEach(rows) { row in
                            HStack {
                                Text(row.emoji)
                                Text(row.title)
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                Spacer()
                                HStack(spacing: 2) {
                                    ForEach(0..<row.rating, id: \.self) { _ in
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Palette.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var topCooksCard: some View {
        let rows = topCookedRecipes
        return Group {
            if !rows.isEmpty {
                PaperCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Most cooked")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        ForEach(rows) { row in
                            HStack {
                                Text(row.emoji)
                                Text(row.title)
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                Spacer()
                                Text("\(row.count)×")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.accent)
                            }
                        }
                    }
                }
            }
        }
    }

    private var surpriseCard: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("What should I cook?")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                if store.recipes.isEmpty {
                    Text("Add a dish to your book first, then pick a surprise supper.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Palette.accent)
                } else {
                    if let surprise {
                        HStack(spacing: 8) {
                            Text(surprise.emoji)
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(surprise.title)
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                if !surprise.cuisine.isEmpty {
                                    Text(surprise.cuisine)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(Palette.accent)
                                }
                            }
                        }
                    } else {
                        Text("Draw a dish from your own book.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Palette.accent)
                    }

                    Button {
                        surprise = store.recipes.randomElement()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(surprise == nil ? "Pick a dish" : "Pick another")
                                .font(.system(.body, design: .rounded).weight(.bold))
                            Spacer()
                        }
                        .foregroundColor(Palette.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var activityBars: [ActivityBar] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var bars: [ActivityBar] = []
        for offset in (0..<14).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let next = calendar.date(byAdding: .day, value: 1, to: day)
            else { continue }
            let range = day..<next
            let recipes = store.recipes.filter { range.contains($0.createdAt) }.count
            let notes = store.captions.filter { range.contains($0.updatedAt) }.count
            let cooked = store.cookSessions.filter { range.contains($0.cookedAt) }.count
            bars.append(ActivityBar(day: day, kind: "Recipes", value: recipes))
            bars.append(ActivityBar(day: day, kind: "Notes", value: notes))
            bars.append(ActivityBar(day: day, kind: "Cooked", value: cooked))
        }
        return bars
    }

    private var cuisineRows: [CuisineRow] {
        var counts: [String: Int] = [:]
        for recipe in store.recipes {
            let name = recipe.cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
            let label = name.isEmpty ? "Unlabeled" : name
            counts[label, default: 0] += 1
        }
        return counts
            .map { CuisineRow(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    private var mixSlices: [MixSlice] {
        [
            MixSlice(name: "Recipes", value: store.recipes.count),
            MixSlice(name: "Notes", value: store.captions.count),
            MixSlice(name: "Cooked", value: store.cookSessions.count)
        ].filter { $0.value > 0 }
    }

    private var topCookedRecipes: [CookedRow] {
        var counts: [UUID: Int] = [:]
        for session in store.cookSessions {
            counts[session.recipeID, default: 0] += 1
        }
        return counts
            .compactMap { id, count -> CookedRow? in
                guard let recipe = store.recipe(id: id) else { return nil }
                return CookedRow(
                    id: id,
                    title: recipe.title,
                    emoji: recipe.emoji,
                    count: count
                )
            }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    private var ratingRows: [RatingRow] {
        var counts = [Int: Int]()
        for recipe in store.recipes {
            let value = store.rating(for: recipe.id)
            if value > 0 {
                counts[value, default: 0] += 1
            }
        }
        return (1...5).compactMap { value in
            guard let count = counts[value] else { return nil }
            return RatingRow(label: "\(value)", count: count)
        }
    }

    private var topRatedRecipes: [RatedRow] {
        store.recipes
            .map { recipe in
                RatedRow(
                    id: recipe.id,
                    title: recipe.title,
                    emoji: recipe.emoji,
                    rating: store.rating(for: recipe.id)
                )
            }
            .filter { $0.rating > 0 }
            .sorted { $0.rating > $1.rating }
            .prefix(5)
            .map { $0 }
    }
}

private struct ActivityBar: Identifiable {
    var id: String { "\(day.timeIntervalSince1970)-\(kind)" }
    let day: Date
    let kind: String
    let value: Int
}

private struct CuisineRow: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

private struct MixSlice: Identifiable {
    var id: String { name }
    let name: String
    let value: Int
}

private struct CookedRow: Identifiable {
    let id: UUID
    let title: String
    let emoji: String
    let count: Int
}

private struct RatingRow: Identifiable {
    var id: String { label }
    let label: String
    let count: Int
}

private struct RatedRow: Identifiable {
    let id: UUID
    let title: String
    let emoji: String
    let rating: Int
}

