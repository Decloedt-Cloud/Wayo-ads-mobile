import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let chatActiveConversationPrefsKey = "flutter.chat.active_conversation_id"

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

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WayoPushDismissChannel") {
      let channel = FlutterMethodChannel(
        name: "ma.wayo.wayoadsgo/push_dismiss",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "dismissChatNotification",
              let convId = call.arguments as? String,
              !convId.isEmpty else {
          result(FlutterMethodNotImplemented)
          return
        }
        let threadId = "wayo_chat_\(convId)"
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let ids = notifications
              .filter { $0.request.content.threadIdentifier == threadId }
              .map(\.request.identifier)
            if !ids.isEmpty {
              UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
            }
            result(nil)
          }
        } else {
          result(nil)
        }
      }
    }
  }

  private func fcmConversationId(from userInfo: [AnyHashable: Any]) -> String? {
    if let conv = userInfo["conversationId"] as? String, !conv.isEmpty {
      return conv
    }
    if let conv = userInfo["conversation_id"] as? String, !conv.isEmpty {
      return conv
    }
    if let data = userInfo["data"] as? [String: Any] {
      if let conv = data["conversationId"] as? String, !conv.isEmpty { return conv }
      if let conv = data["conversation_id"] as? String, !conv.isEmpty { return conv }
    }
    return nil
  }

  private func isViewingChatConversation(_ conversationId: String) -> Bool {
    guard let active = UserDefaults.standard.string(forKey: chatActiveConversationPrefsKey),
          !active.isEmpty else {
      return false
    }
    return active == conversationId
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    if let convId = fcmConversationId(from: userInfo), isViewingChatConversation(convId) {
      completionHandler([])
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }
}
