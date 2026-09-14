import SwiftUI
import UIKit

struct HerbMeadow: View {
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color("AppBackground"))
            )

            let wash = Gradient(colors: [
                Color("AppSurface").opacity(0.42),
                Color("AppBackground").opacity(0.05)
            ])
            context.fill(
                Path(ellipseIn: CGRect(
                    x: -size.width * 0.18,
                    y: -size.height * 0.08,
                    width: size.width * 0.95,
                    height: size.height * 0.48
                )),
                with: .linearGradient(
                    wash,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height * 0.4)
                )
            )

            var rng = SeededRandom(seed: 347_001)
            for _ in 0..<96 {
                let x = rng.next() * size.width
                let y = rng.next() * size.height
                let leafWidth = 9 + rng.next() * 18
                let leafHeight = leafWidth * (1.7 + rng.next() * 0.8)
                let rotation = Angle.degrees(rng.next() * 360)
                let tint = rng.next()
                let color: Color = tint < 0.18
                    ? Color("AppPrimary").opacity(0.22 + rng.next() * 0.18)
                    : Color("AppSurface").opacity(0.28 + rng.next() * 0.42)

                var leaf = Path()
                leaf.addEllipse(in: CGRect(
                    x: -leafWidth / 2,
                    y: -leafHeight / 2,
                    width: leafWidth,
                    height: leafHeight
                ))

                var transformed = context
                transformed.translateBy(x: x, y: y)
                transformed.rotate(by: rotation)
                transformed.fill(leaf, with: .color(color))
            }

            var berryRng = SeededRandom(seed: 347_880)
            for _ in 0..<18 {
                let x = berryRng.next() * size.width
                let y = berryRng.next() * size.height
                let radius = 2.2 + berryRng.next() * 3.4
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                    with: .color(Color("AppAccent").opacity(0.35 + berryRng.next() * 0.25))
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                HerbMeadow()
            }
    }
}

struct NavigationBackdropClearer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.isOpaque = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            Self.clear(from: uiView)
        }
    }

    static func clear(from view: UIView) {
        var current: UIView? = view.superview
        while let node = current, !(node is UIWindow) {
            node.backgroundColor = .clear
            node.isOpaque = false
            current = node.superview
        }

        var responder: UIResponder? = view.next
        while let node = responder {
            if let controller = node as? UIViewController {
                controller.view.backgroundColor = .clear
                controller.view.isOpaque = false
                controller.navigationController?.view.backgroundColor = .clear
                controller.navigationController?.view.isOpaque = false
                controller.navigationController?.navigationBar.isTranslucent = true
            }
            responder = node.next
        }
    }
}

extension View {
    func studioBackdrop() -> some View {
        modifier(ScreenBackground())
    }

    func gardenPage() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .background(NavigationBackdropClearer())
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct SeededRandom {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return CGFloat(state % 10_000) / 10_000
    }
}
