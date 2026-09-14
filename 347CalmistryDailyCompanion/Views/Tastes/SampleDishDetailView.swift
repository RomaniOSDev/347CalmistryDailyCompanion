import SwiftUI
import UIKit

struct SampleDishDetailView: View {
    @EnvironmentObject private var store: CookbookStore
    let dish: SampleDish
    @State private var addedNotice: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                TasteBanner(assetName: "BannerDiscover")
                    .clipShape(TornPaperShape())
                    .shadow(color: Palette.background.opacity(0.32), radius: 8, x: 0, y: 4)

                PaperCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Text(dish.emoji)
                                .font(.system(size: 36))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dish.title)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                Text(dish.cuisine)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Palette.accent)
                            }
                            Spacer()
                            Button {
                                store.toggleFavourite(sampleID: dish.id)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Image(systemName: store.isFavourite(dish.id) ? "heart.fill" : "heart")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Palette.primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Favourite")
                        }

                        Text(dish.blurb)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Palette.accent)
                    }
                }

                PaperCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        ForEach(Array(dish.ingredients.enumerated()), id: \.offset) { _, item in
                            Text("• \(item)")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Palette.accent)
                        }
                    }
                }

                PaperCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        ForEach(Array(dish.instructions.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Palette.accent)
                        }
                    }
                }

                Button {
                    _ = store.importSample(dish)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    addedNotice = "Added to your book."
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Add to Book")
                            .font(.system(.body, design: .rounded).weight(.bold))
                        Spacer()
                    }
                    .foregroundColor(Palette.primary)
                    .padding(14)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Palette.primary.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: Palette.background.opacity(0.28), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)

                if let addedNotice {
                    Text(addedNotice)
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .gardenPage()
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            if let theme = TasteLibrary.theme(for: dish.id) {
                store.markActivity(category: theme)
            }
        }
    }
}
