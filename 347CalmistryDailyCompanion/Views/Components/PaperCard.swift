import SwiftUI

struct TornPaperShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 16, y: 0))
        path.addLine(to: CGPoint(x: width * 0.20, y: 3))
        path.addLine(to: CGPoint(x: width * 0.36, y: 0))
        path.addLine(to: CGPoint(x: width * 0.54, y: 5))
        path.addLine(to: CGPoint(x: width * 0.73, y: 0))
        path.addLine(to: CGPoint(x: width - 20, y: 2))
        path.addQuadCurve(
            to: CGPoint(x: width, y: 22),
            control: CGPoint(x: width, y: 3)
        )
        path.addLine(to: CGPoint(x: width, y: height - 14))
        path.addQuadCurve(
            to: CGPoint(x: width - 14, y: height),
            control: CGPoint(x: width, y: height)
        )
        path.addLine(to: CGPoint(x: 22, y: height - 4))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height - 24),
            control: CGPoint(x: 0, y: height)
        )
        path.addLine(to: CGPoint(x: 0, y: 18))
        path.addQuadCurve(
            to: CGPoint(x: 16, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        path.closeSubpath()
        return path
    }
}

struct PaperCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [Palette.primary, Palette.accent],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 7)

            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.surface)
        .clipShape(TornPaperShape())
        .overlay {
            TornPaperShape()
                .stroke(Palette.primary.opacity(0.22), lineWidth: 1)
        }
        .overlay {
            LinearGradient(
                colors: [Palette.primary.opacity(0.10), Palette.background.opacity(0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(TornPaperShape())
            .allowsHitTesting(false)
        }
        .shadow(color: Palette.background.opacity(0.38), radius: 8, x: 0, y: 4)
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
                    Palette.surface
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                }
        }
    }
}
