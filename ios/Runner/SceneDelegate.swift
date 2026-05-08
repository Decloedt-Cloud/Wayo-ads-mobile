import Flutter
import GoogleSignIn
import Stripe
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  /// Under UIScene, OAuth return URLs are delivered here. `google_sign_in_ios` still
  /// registers `application:openURL:options:` on the app delegate, which is not always
  /// invoked for scene-based apps — forward Google URLs so "Continue with Google" can finish.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      let url = context.url
      if GIDSignIn.sharedInstance.handle(url) {
        continue
      }
      _ = StripeAPI.handleURLCallback(with: url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
