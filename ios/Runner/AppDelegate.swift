import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required so notification action isolates (Répondre sans ouvrir l’app, etc.)
    // can register plugins (SecureStorage, Dio/cert pinning, …).
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // Foreground banners + FCM/APNs delegate chain (firebase_messaging + local notifs).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    // Firebase is initialized from Dart (`initializeFirebaseForPush` in lib/main.dart)
    // with `DefaultFirebaseOptions` — do not call FirebaseApp.configure() here.
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // APNs device token registration (FCM getToken/getAPNSToken on iOS depends on this).
    application.registerForRemoteNotifications()
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
