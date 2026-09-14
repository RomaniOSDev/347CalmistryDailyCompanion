import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func hide() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct KeyboardDismissTapInstaller: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let host = uiView.superview else { return }
            if let existing = context.coordinator.recognizer,
               host.gestureRecognizers?.contains(existing) == true {
                return
            }
            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
            tap.cancelsTouchesInView = false
            tap.delegate = context.coordinator
            host.addGestureRecognizer(tap)
            context.coordinator.recognizer = tap
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var recognizer: UITapGestureRecognizer?

        @objc func handleTap() {
            KeyboardDismiss.hide()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissTapInstaller())
    }

    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    KeyboardDismiss.hide()
                }
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundColor(Palette.primary)
            }
        }
    }
}
