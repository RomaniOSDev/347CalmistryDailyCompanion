import StoreKit
import UIKit

enum AppLinks: String {
    case privacy = "https://calmistrydaily347companion.site/privacy/462"
    case terms = "https://calmistrydaily347companion.site/terms/462"

    static func rateApp() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { scene in
            scene as? UIWindowScene
        }
        let windowScene = scenes.first(where: { scene in
            scene.activationState == .foregroundActive
        }) ?? scenes.first
        if let windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
