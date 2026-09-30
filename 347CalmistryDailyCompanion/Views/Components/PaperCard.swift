import SwiftUI

struct PaperCard<Content: View>: View {
    var emphasized: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Palette.card)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: emphasized
                                ? [Palette.primary, Palette.accent]
                                : [Palette.surface, Palette.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 5)
                    .padding(.vertical, 14)
                    .padding(.leading, 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 1)
            }
            .shadow(color: Palette.glow.opacity(0.35), radius: 14, x: 0, y: 8)
            .shadow(color: Palette.primary.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(Palette.onPrimary)
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(Palette.onPrimary.opacity(0.88))
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
        }
    }
}

struct SoftChip: View {
    let title: String
    var selected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(selected ? Palette.onPrimary : Palette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(selected ? Palette.primary : Palette.card)
                )
                .overlay {
                    Capsule()
                        .stroke(selected ? Color.clear : Palette.hairline, lineWidth: 1)
                }
                .shadow(color: selected ? Palette.primary.opacity(0.35) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundColor(Palette.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Palette.primary, Palette.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Palette.primary.opacity(0.4), radius: 10, y: 5)
    }
}

struct RecipePhotoFrame: View {
    let fileName: String?
    var height: CGFloat = 118

    var body: some View {
        if let fileName, let image = PhotoDisk.load(fileName) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background {
                    Palette.cardSoft
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 1)
                }
        }
    }
}

struct FeatureHero: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Palette.primary,
                            Palette.accent,
                            Palette.background
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(minHeight: 158)
                .overlay {
                    // Shine
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .overlay(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 110, height: 110)
                            .offset(x: 16, y: -10)
                        Image(systemName: symbol)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.22))
                            .rotationEffect(.degrees(-8))
                            .offset(x: -6, y: 18)
                    }
                }
                .overlay(alignment: .bottom) {
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule()
                                .fill(Color.white.opacity(i == 0 ? 0.45 : 0.18))
                                .frame(width: i == 0 ? 22 : 8, height: 4)
                        }
                    }
                    .padding(.bottom, 12)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.onPrimary)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(Palette.onPrimary.opacity(0.94))
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            }
            .padding(20)
            .padding(.bottom, 10)
        }
        .shadow(color: Palette.primary.opacity(0.35), radius: 16, y: 8)
    }
}

struct EmptyGarden: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        PaperCard(emphasized: true) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Palette.primary.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Palette.primary)
                }
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(Palette.ink)
                Text(message)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FieldShell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .background(Palette.cardSoft)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Palette.surface.opacity(0.35), lineWidth: 1)
            }
    }
}
