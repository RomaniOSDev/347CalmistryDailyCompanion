import SwiftUI

struct TasteBanner: View {
    let assetName: String

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .background {
                BotanicalStrip()
                    .overlay {
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Palette.background.opacity(0), Palette.background.opacity(0.42)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}

private struct BotanicalStrip: View {
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [
                        Color("AppSurface"),
                        Color("AppBackground")
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            var rng = BannerRandom(seed: 88_214)
            for _ in 0..<28 {
                let x = rng.next() * size.width
                let y = rng.next() * size.height
                let leafWidth = 14 + rng.next() * 26
                let leafHeight = leafWidth * 1.8
                var leaf = Path()
                leaf.addEllipse(in: CGRect(
                    x: -leafWidth / 2,
                    y: -leafHeight / 2,
                    width: leafWidth,
                    height: leafHeight
                ))
                var transformed = context
                transformed.translateBy(x: x, y: y)
                transformed.rotate(by: .degrees(rng.next() * 360))
                transformed.fill(
                    leaf,
                    with: .color(Color("AppSurface").opacity(0.35 + rng.next() * 0.4))
                )
            }
        }
    }
}

private struct BannerRandom {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return CGFloat(state % 10_000) / 10_000
    }
}
