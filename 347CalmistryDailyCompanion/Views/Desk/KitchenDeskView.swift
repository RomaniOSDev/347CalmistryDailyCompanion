import SwiftUI
import UIKit

struct KitchenDeskView: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TasteBanner(assetName: "BannerCaption")
                        .clipShape(TornPaperShape())
                        .shadow(color: Palette.background.opacity(0.32), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kitchen Desk")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                        Text("Timers, shopping, the week’s meals, leftovers, and a clean slate.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Palette.accent)
                    }

                    KitchenTimerBoard()
                    ShoppingListCard()
                    MealPlanCard()
                    LeftoversCard()

                    if !store.favouriteSampleIDs.isEmpty {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Saved tastes")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                Text("\(favouriteItems.count) marked in the explorer")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(Palette.accent)
                            }
                        }
                    }

                    if !store.themeLabels.isEmpty {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cuisines in your book")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                FlowLabels(labels: store.themeLabels)
                            }
                        }
                    }

                    if let lastEdited = store.lastEditedCaptionDate {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Last caption")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                Text(lastEdited, style: .date)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(Palette.accent)
                            }
                        }
                    }

                    deskButton(title: "Rate Us", symbol: "star.fill") {
                        AppLinks.rateApp()
                    }

                    deskButton(title: "Privacy", symbol: "hand.raised.fill") {
                        openLink(AppLinks.privacy)
                    }

                    deskButton(title: "Terms", symbol: "doc.text.fill") {
                        openLink(AppLinks.terms)
                    }

                    Button {
                        showResetConfirm = true
                    } label: {
                        PaperCard {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(Palette.primary)
                                Text("Reset All Data")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.primary)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .gardenPage()
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle("Desk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Reset All Data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                }
            } message: {
                Text("Recipes, captions, cook history, shopping, leftovers, and saved photos will be removed.")
            }
        }
    }

    private var favouriteItems: [Favourite] {
        store.favouriteSampleIDs.map { Favourite(id: $0) }
    }

    private func deskButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PaperCard {
                HStack {
                    Image(systemName: symbol)
                        .foregroundColor(Palette.primary)
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Palette.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func openLink(_ link: AppLinks) {
        guard let url = URL(string: link.rawValue) else { return }
        UIApplication.shared.open(url)
    }
}

struct FlowLabels: View {
    let labels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Palette.background.opacity(0.35))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Palette.primary.opacity(0.28), lineWidth: 1)
                    }
            }
        }
    }
}
