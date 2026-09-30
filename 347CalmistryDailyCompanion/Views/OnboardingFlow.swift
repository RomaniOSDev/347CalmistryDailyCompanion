import SwiftUI

struct OnboardingFlow: View {
    var onFinish: () -> Void
    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        (
            "refrigerator.fill",
            "Cook from what you already have",
            "Log fridge ingredients once. Calmistry builds a full week of meals that reuse those items first."
        ),
        (
            "books.vertical.fill",
            "52 authored offline recipes",
            "Browse an original shelf of weeknight, tray-bake, bowl, and comfort recipes — no account, no cloud."
        ),
        (
            "square.and.arrow.down.on.square.fill",
            "Import any recipe you find",
            "Paste text or a web link. We parse ingredients and steps into your private kitchen book."
        )
    ]

    var body: some View {
        ZStack {
            PantryCanvas()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 24) {
                            Spacer(minLength: 36)
                            ZStack {
                                Circle()
                                    .fill(Palette.card)
                                    .frame(width: 132, height: 132)
                                    .shadow(color: Palette.glow.opacity(0.35), radius: 16, y: 8)
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Palette.primary, Palette.accent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 132, height: 132)
                                Image(systemName: item.symbol)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Palette.primary, Palette.accent],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            Text(item.title)
                                .font(.system(.title, design: .rounded).weight(.bold))
                                .foregroundColor(Palette.onPrimary)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.28), radius: 3, y: 1)
                                .padding(.horizontal, 24)
                            Text(item.body)
                                .font(.system(.body, design: .rounded).weight(.medium))
                                .foregroundColor(Palette.onPrimary.opacity(0.92))
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.black.opacity(0.18))
                                )
                                .padding(.horizontal, 20)
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    PrimaryButtonLabel(title: page < pages.count - 1 ? "Continue" : "Start cooking smarter")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 18)

                if page < pages.count - 1 {
                    Button("Skip") { onFinish() }
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(Palette.onPrimary)
                        .padding(.bottom, 22)
                } else {
                    Spacer().frame(height: 22)
                }
            }
        }
    }
}
