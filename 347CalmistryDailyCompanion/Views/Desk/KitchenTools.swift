import AudioToolbox
import SwiftUI
import UIKit

struct KitchenTimerBoard: View {
    @EnvironmentObject private var store: CookbookStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            PaperCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kitchen timers")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.primary)
                    Text("Three clocks for pasta, oven, and resting.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Palette.accent)

                    ForEach(store.timers) { slot in
                        timerRow(slot)
                    }
                }
            }
            .onChange(of: context.date) { _ in
                ringFinishedTimers()
            }
        }
    }

    private func timerRow(_ slot: KitchenTimerSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(slot.label)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                Spacer()
                Text(ServingScale.formatClock(slot.isRunning ? slot.remaining : TimeInterval(slot.durationSeconds)))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                ForEach([1, 3, 5, 10, 15, 20], id: \.self) { minutes in
                    Button {
                        store.startTimer(id: slot.id, seconds: minutes * 60)
                    } label: {
                        Text("\(minutes)m")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Palette.background.opacity(0.35))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(slot.isRunning)
                }
            }

            HStack {
                if slot.isRunning {
                    Button("Stop") {
                        store.stopTimer(id: slot.id)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.accent)
                } else {
                    Button("Start \(slot.durationSeconds / 60)m") {
                        store.startTimer(id: slot.id, seconds: slot.durationSeconds)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                }
                Spacer()
            }
        }
    }

    private func ringFinishedTimers() {
        let finished = store.consumeTimerAlarms()
        guard !finished.isEmpty else { return }
        AudioServicesPlaySystemSound(1005)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct ShoppingListCard: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var draft = ""

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Shopping list")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.primary)
                    Spacer()
                    if store.shoppingItems.contains(where: \.isChecked) {
                        Button("Clear checked") {
                            store.clearCheckedShopping()
                        }
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.accent)
                    }
                }

                HStack(spacing: 8) {
                    TextField("Add an item", text: $draft)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Palette.primary)
                    Button("Add") {
                        store.addShoppingItem(draft)
                        draft = ""
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(10)
                .background(Palette.background.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if store.shoppingItems.isEmpty {
                    Text("Add from a recipe in Book, or type a stray item here.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Palette.accent)
                } else {
                    ForEach(store.shoppingItems) { item in
                        Button {
                            store.toggleShoppingItem(id: item.id)
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(Palette.primary)
                                Text(item.text)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(item.isChecked ? Palette.accent.opacity(0.7) : Palette.primary)
                                    .strikethrough(item.isChecked, color: Palette.accent.opacity(0.5))
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct MealPlanCard: View {
    @EnvironmentObject private var store: CookbookStore

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Week on the table")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                Text("Pick a dish from your book for each evening.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Palette.accent)

                if store.recipes.isEmpty {
                    Text("Add a recipe before you can plan the week.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Palette.accent)
                } else {
                    ForEach(WeekPlan.mondayFirst, id: \.weekday) { day in
                        HStack {
                            Text(day.title)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.primary)
                                .frame(width: 40, alignment: .leading)
                            Picker(
                                day.title,
                                selection: Binding(
                                    get: { store.mealPlan.first(where: { $0.weekday == day.weekday })?.recipeID },
                                    set: { store.setMeal(weekday: day.weekday, recipeID: $0) }
                                )
                            ) {
                                Text("—").tag(Optional<UUID>.none)
                                ForEach(store.recipes) { recipe in
                                    Text("\(recipe.emoji) \(recipe.title)").tag(Optional(recipe.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Palette.primary)
                        }
                    }
                }
            }
        }
    }
}

struct LeftoversCard: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var leftover = ""
    @State private var idea = ""
    @State private var linkedID: UUID?

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Leftovers")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
                Text("What is in the fridge, and what it becomes tomorrow.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Palette.accent)

                field("What's left", text: $leftover, placeholder: "Half a roast chicken…")
                field("Tomorrow's idea", text: $idea, placeholder: "Soup, sandwich, fried rice…")

                if !store.recipes.isEmpty {
                    Picker(
                        "From a dish",
                        selection: $linkedID
                    ) {
                        Text("No dish").tag(Optional<UUID>.none)
                        ForEach(store.recipes) { recipe in
                            Text("\(recipe.emoji) \(recipe.title)").tag(Optional(recipe.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Palette.primary)
                }

                Button {
                    store.addLeftover(leftover: leftover, idea: idea, recipeID: linkedID)
                    leftover = ""
                    idea = ""
                    linkedID = nil
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Save leftover")
                            .font(.system(.body, design: .rounded).weight(.bold))
                        Spacer()
                    }
                    .foregroundColor(Palette.primary)
                }
                .buttonStyle(.plain)
                .disabled(leftover.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                ForEach(store.leftovers) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(note.leftover)
                                .font(.system(.body, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.primary)
                            Spacer()
                            Button {
                                store.deleteLeftover(id: note.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        if !note.idea.isEmpty {
                            Text(note.idea)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(Palette.accent)
                        }
                        if let recipeID = note.recipeID, let recipe = store.recipe(id: recipeID) {
                            Text("From \(recipe.emoji) \(recipe.title)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Palette.accent)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(Palette.primary)
            TextField(placeholder, text: text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Palette.primary)
                .padding(10)
                .background(Palette.background.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
