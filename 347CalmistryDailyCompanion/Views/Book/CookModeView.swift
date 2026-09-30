import SwiftUI
import UIKit

struct CookModeView: View {
    @EnvironmentObject private var store: CookbookStore
    @Environment(\.dismiss) private var dismiss

    let recipeID: UUID
    @State private var stepIndex = 0
    @State private var factor: Double = 1

    private var recipe: Recipe? {
        store.recipe(id: recipeID)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let recipe {
                    cookBody(recipe)
                } else {
                    EmptyGarden(
                        title: "Recipe missing",
                        systemImage: "book.closed",
                        message: "This dish is no longer in your kitchen."
                    )
                    .padding(16)
                }
            }
            .gardenPage()
            .background {
                PantryCanvas()
            }
            .navigationTitle("Cook Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .background {
            PantryCanvas()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if let recipe {
                stepIndex = nextOpenStep(in: recipe) ?? 0
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func cookBody(_ recipe: Recipe) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PaperCard(emphasized: true) {
                        HStack(spacing: 10) {
                            Text(recipe.emoji)
                                .font(.system(size: 36))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(.system(.title2, design: .rounded).weight(.bold))
                                    .foregroundColor(Palette.ink)
                                Text("Step \(min(stepIndex + 1, recipe.instructions.count)) of \(max(recipe.instructions.count, 1))")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundColor(Palette.muted)
                            }
                        }
                    }

                    ServingFactorPicker(factor: $factor)

                    PaperCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.ink)
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, item in
                                Text("• \(ServingScale.apply(item, factor: factor))")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(Palette.muted)
                            }
                        }
                    }

                    if recipe.instructions.indices.contains(stepIndex) {
                        PaperCard {
                            StepCheckRow(
                                index: stepIndex,
                                text: recipe.instructions[stepIndex],
                                isChecked: store.isStepChecked(recipeID: recipe.id, index: stepIndex),
                                large: true
                            ) {
                                store.toggleStep(recipeID: recipe.id, index: stepIndex)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                }
                .padding(16)
            }

            HStack(spacing: 10) {
                Button {
                    stepIndex = max(0, stepIndex - 1)
                } label: {
                    labelCapsule("Back", symbol: "chevron.left")
                }
                .disabled(stepIndex == 0)

                if stepIndex < recipe.instructions.count - 1 {
                    Button {
                        stepIndex += 1
                    } label: {
                        labelCapsule("Next", symbol: "chevron.right")
                    }
                } else {
                    Button {
                        store.recordCook(recipeID: recipe.id)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    } label: {
                        labelCapsule("Done cooking", symbol: "checkmark")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func labelCapsule(_ title: String, symbol: String) -> some View {
        HStack {
            Image(systemName: symbol)
            Text(title)
                .font(.system(.body, design: .rounded).weight(.bold))
        }
        .foregroundColor(Palette.onPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Palette.primary, Palette.accent],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Palette.primary.opacity(0.35), radius: 8, y: 4)
    }

    private func nextOpenStep(in recipe: Recipe) -> Int? {
        recipe.instructions.indices.first { index in
            !store.isStepChecked(recipeID: recipe.id, index: index)
        }
    }
}
