import SwiftUI
import UIKit

struct ToolsHubView: View {
    @EnvironmentObject private var store: CookbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureHero(
                        title: "Kitchen Tools",
                        subtitle: "Timers, shopping list, and legal links — kept out of the main flow.",
                        symbol: "slider.horizontal.3"
                    )

                    KitchenTimerBoard()
                    ShoppingListCard()

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
                                Text("Reset all local data")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.ink)
                                Spacer()
                            }
                            .padding(.top, 6)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .gardenPage()
            .background { PantryCanvas() }
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog("Erase fridge, recipes, and plans?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) {
                    store.resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .background { PantryCanvas() }
        .tint(Palette.primary)
    }

    private func deskButton(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PaperCard {
                HStack {
                    Image(systemName: symbol)
                        .foregroundColor(Palette.primary)
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Palette.muted.opacity(0.7))
                }
                .padding(.top, 6)
            }
        }
        .buttonStyle(.plain)
    }

    private func openLink(_ link: AppLinks) {
        guard let url = URL(string: link.rawValue) else { return }
        UIApplication.shared.open(url)
    }
}
