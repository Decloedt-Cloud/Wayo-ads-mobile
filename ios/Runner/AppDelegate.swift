import Flutter
import UIKit
import Stripe

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    StripeAPI.defaultPublishableKey = "pk_test_51TRs2WPtBHJOXslcfJ1yDKC5i9xUHMF92CTQqg9PSWhakPgq8458qQQnBpNBqrjJ12psyA8qCV1OALh5vjmQjRAL00M4qF4j1Q" // ⚠️ TON KEY

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}