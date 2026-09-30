import SwiftUI
import UIKit

struct KitchenTimerBoard: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var tick = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Timers")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.ink)
                    .padding(.top, 6)
                ForEach(store.timers) { slot in
                    timerRow(slot)
                }
            }
        }
        .onReceive(timer) { value in
            tick = value
            let finished = store.consumeTimerAlarms()
            if !finished.isEmpty {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func timerRow(_ slot: KitchenTimerSlot) -> some View {
        let _ = tick
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.label)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.ink)
                Text(slot.isRunning ? ServingScale.formatClock(slot.remaining) : ServingScale.formatClock(TimeInterval(slot.durationSeconds)))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.muted)
            }
            Spacer()
            if slot.isRunning {
                Button("Stop") { store.stopTimer(id: slot.id) }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.primary)
            } else {
                Button("Start") { store.startTimer(id: slot.id, seconds: slot.durationSeconds) }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.onPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Palette.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(Palette.cardSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ShoppingListCard: View {
    @EnvironmentObject private var store: CookbookStore
    @State private var draft = ""

    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Shopping list")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.ink)
                    Spacer()
                    if store.shoppingItems.contains(where: \.isChecked) {
                        Button("Clear checked") { store.clearCheckedShopping() }
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(Palette.muted)
                    }
                }
                .padding(.top, 6)

                FieldShell {
                    HStack {
                        TextField("Add item", text: $draft)
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(Palette.ink)
                        Button("Add") {
                            store.addShoppingItem(draft)
                            draft = ""
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.primary)
                    }
                }

                if store.shoppingItems.isEmpty {
                    Text("Pull ingredients from a dish, or type them here.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(Palette.muted)
                } else {
                    ForEach(store.shoppingItems) { item in
                        Button {
                            store.toggleShoppingItem(id: item.id)
                        } label: {
                            HStack {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(Palette.primary)
                                Text(item.text)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundColor(item.isChecked ? Palette.muted.opacity(0.65) : Palette.ink)
                                    .strikethrough(item.isChecked)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
