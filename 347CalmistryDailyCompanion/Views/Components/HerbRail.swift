import SwiftUI

enum DeskDestination: Int, CaseIterable {
    case book
    case notes
    case tastes
    case stats
    case desk

    var title: String {
        switch self {
        case .book: return "Book"
        case .notes: return "Notes"
        case .tastes: return "Tastes"
        case .stats: return "Stats"
        case .desk: return "Desk"
        }
    }

    var symbol: String {
        switch self {
        case .book: return "book.fill"
        case .notes: return "pencil"
        case .tastes: return "leaf.fill"
        case .stats: return "chart.bar.fill"
        case .desk: return "lamp.desk.fill"
        }
    }
}

struct HerbRail: View {
    @Binding var selection: DeskDestination

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Palette.primary)
                .frame(width: 18, height: 4)
                .padding(.top, 10)

            ForEach(DeskDestination.allCases, id: \.self) { destination in
                Button {
                    selection = destination
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: destination.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(destination.title)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(selection == destination ? Palette.primary : Palette.accent.opacity(0.72))
                    .frame(width: 58, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selection == destination ? Palette.surface : Palette.background.opacity(0.28))
                    )
                    .overlay(alignment: .leading) {
                        if selection == destination {
                            Capsule()
                                .fill(Palette.primary)
                                .frame(width: 3, height: 28)
                                .offset(x: -2)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                selection == destination ? Palette.primary.opacity(0.55) : Palette.accent.opacity(0.12),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: selection == destination ? Palette.background.opacity(0.28) : Palette.background.opacity(0),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(width: 78)
        .background(
            Palette.background.opacity(0.42)
                .overlay {
                    LinearGradient(
                        colors: [Palette.primary.opacity(0.10), Palette.background.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Palette.primary.opacity(0.28))
                .frame(width: 1)
        }
    }
}
