import Flutter
import Stripe
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  /// Ensures Stripe receives redirect URLs (3DS, etc.) under the UIScene lifecycle.
  /// Flutter forwards these in most cases; handling here avoids rare gaps with plugin order.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      _ = StripeAPI.handleURLCallback(with: context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
