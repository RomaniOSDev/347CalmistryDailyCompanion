import SwiftUI
import UIKit

struct PantryCanvas: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("AppSurface").opacity(0.92),
                    Color("AppBackground")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft light pools
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: -90, y: -220)

            Circle()
                .fill(Color("AppPrimary").opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 140, y: 80)

            Circle()
                .fill(Color("AppAccent").opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 55)
                .offset(x: -40, y: 320)

            // Decorative leaf dots
            Canvas { context, size in
                var rng = SeededRandom(seed: 904_221)
                for _ in 0..<40 {
                    let x = rng.next() * size.width
                    let y = rng.next() * size.height
                    let w = 10 + rng.next() * 22
                    let h = w * (1.5 + rng.next() * 0.7)
                    var leaf = Path(ellipseIn: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
                    var t = context
                    t.translateBy(x: x, y: y)
                    t.rotate(by: .degrees(rng.next() * 360))
                    t.fill(leaf, with: .color(Color.white.opacity(0.06 + rng.next() * 0.08)))
                }
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
                PantryCanvas()
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
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func tabRootPadding() -> some View {
        padding(.bottom, 104)
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
