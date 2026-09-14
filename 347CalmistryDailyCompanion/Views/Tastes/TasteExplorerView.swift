import SwiftUI
import UIKit

struct TasteExplorerView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var openTheme = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TasteBanner(assetName: "BannerDiscover")
                        .clipShape(TornPaperShape())
                        .shadow(color: Palette.background.opacity(0.32), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Taste Explorer")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        Text("Open a theme, then add a dish to your book.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Palette.accent)
                    }

                    seasonalCard

                    if TasteLibrary.allDishes.isEmpty {
                        EmptyGarden(
                            title: "Discover new flavours",
                            systemImage: "magnifyingglass.circle",
                            message: "Sample dishes will appear here when the pantry is stocked."
                        )
                    } else {
                        ForEach(TasteLibrary.themeTitles, id: \.self) { theme in
                            themeCard(theme)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .gardenPage()
            .navigationTitle("Tastes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if openTheme.isEmpty {
                    openTheme = store.lastVisitedCategory
                }
            }
        }
    }

    private var seasonalCard: some View {
        let month = Calendar.current.component(.month, from: Date())
        let herbs = SeasonalGarden.herbs(for: month)
        let title = Date.now.formatted(.dateTime.month(.wide))
        return PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("In season · \(title)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                Text("Herbs that belong in the kitchen this month.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Palette.accent)
                ForEach(herbs, id: \.name) { herb in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(herb.name)
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        Text(herb.note)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Palette.accent)
                    }
                }
            }
        }
    }

    private func themeCard(_ theme: String) -> some View {
        let dishes = TasteLibrary.dishesByTheme[theme] ?? []
        let isOpen = openTheme == theme

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                if openTheme == theme {
                    openTheme = ""
                    store.markActivity(category: "")
                } else {
                    openTheme = theme
                    store.markActivity(category: theme)
                }
            } label: {
                PaperCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.primary)
                            Text("\(dishes.count) dishes")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Palette.accent)
                        }
                        Spacer()
                        Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Palette.primary)
                    }
                }
            }
            .buttonStyle(.plain)

            if isOpen {
                ForEach(dishes) { dish in
                    dishRow(dish)
                }
            }
        }
    }

    private func dishRow(_ dish: SampleDish) -> some View {
        PaperCard {
            HStack(alignment: .center, spacing: 10) {
                NavigationLink {
                    SampleDishDetailView(dish: dish)
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Text(dish.emoji)
                            .font(.system(size: 26))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(dish.title)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.primary)
                            Text(dish.blurb)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Palette.accent)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 6)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    store.toggleFavourite(sampleID: dish.id)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: store.isFavourite(dish.id) ? "heart.fill" : "heart")
                        .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Favourite")
            }
        }
    }
}
