import StoreKit
import UIKit

enum AppLinks: String {
    case privacy = "https://travalynjourney354planner.site/privacy/466"
    case terms = "https://travalynjourney354planner.site/terms/466"

    var url: URL? {
        URL(string: rawValue)
    }

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
