import SwiftUI

struct MainTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: .bold))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(selection == tab ? Palette.onPrimary : Palette.ink.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                selection == tab
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [Palette.primary, Palette.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    : AnyShapeStyle(Color.clear)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Palette.glow.opacity(0.45), radius: 18, y: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }
}

enum AppTab: Int, CaseIterable {
    case fridge
    case shelf
    case kitchen
    case capture

    var title: String {
        switch self {
        case .fridge: return "Fridge"
        case .shelf: return "Shelf"
        case .kitchen: return "Kitchen"
        case .capture: return "Import"
        }
    }

    var symbol: String {
        switch self {
        case .fridge: return "refrigerator.fill"
        case .shelf: return "books.vertical.fill"
        case .kitchen: return "fork.knife"
        case .capture: return "square.and.arrow.down.on.square.fill"
        }
    }
}
