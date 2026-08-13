import AuthenticationServices
import Flutter
import UIKit

/// Native WebAuthn / passkeys via AuthenticationServices.
/// Private keys stay in the credential provider / Secure Enclave.
final class PasskeysPlugin: NSObject, FlutterPlugin, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  private var pendingResult: FlutterResult?
  private var window: UIWindow?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "wayo/passkeys", binaryMessenger: registrar.messenger())
    let instance = PasskeysPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      if #available(iOS 16.0, *) {
        result(true)
      } else {
        result(false)
      }
    case "create":
      guard let args = call.arguments as? [String: Any],
            let requestJson = args["requestJson"] as? String else {
        result(FlutterError(code: "configuration", message: "Missing requestJson", details: nil))
        return
      }
      createPasskey(requestJson: requestJson, result: result)
    case "authenticate":
      guard let args = call.arguments as? [String: Any],
            let requestJson = args["requestJson"] as? String else {
        result(FlutterError(code: "configuration", message: "Missing requestJson", details: nil))
        return
      }
      authenticate(requestJson: requestJson, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func createPasskey(requestJson: String, result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      guard pendingResult == nil else {
        result(FlutterError(code: "unknown", message: "Ceremony already in progress", details: nil))
        return
      }
      guard let data = requestJson.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let challengeB64 = json["challenge"] as? String,
            let rp = json["rp"] as? [String: Any],
            let rpId = rp["id"] as? String,
            let user = json["user"] as? [String: Any],
            let userIdB64 = user["id"] as? String,
            let userName = user["name"] as? String else {
        result(FlutterError(code: "configuration", message: "Invalid creation options", details: nil))
        return
      }

      guard let challenge = Self.base64URLDecode(challengeB64),
            let userId = Self.base64URLDecode(userIdB64) else {
        result(FlutterError(code: "configuration", message: "Invalid challenge/user id", details: nil))
        return
      }

      pendingResult = result
      let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
      let displayName = (user["displayName"] as? String) ?? userName
      let request = provider.createCredentialRegistrationRequest(
        challenge: challenge,
        name: userName,
        userID: userId
      )
      request.displayName = displayName
      if let uv = json["authenticatorSelection"] as? [String: Any],
         let uvPref = uv["userVerification"] as? String,
         uvPref == "required" {
        request.userVerificationPreference = .required
      }

      let controller = ASAuthorizationController(authorizationRequests: [request])
      controller.delegate = self
      controller.presentationContextProvider = self
      controller.performRequests()
    } else {
      result(FlutterError(code: "unavailable", message: "Passkeys require iOS 16+", details: nil))
    }
  }

  private func authenticate(requestJson: String, result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      guard pendingResult == nil else {
        result(FlutterError(code: "unknown", message: "Ceremony already in progress", details: nil))
        return
      }
      guard let data = requestJson.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let challengeB64 = json["challenge"] as? String else {
        result(FlutterError(code: "configuration", message: "Invalid request options", details: nil))
        return
      }
      let rpId = (json["rpId"] as? String) ?? ""
      guard !rpId.isEmpty, let challenge = Self.base64URLDecode(challengeB64) else {
        result(FlutterError(code: "configuration", message: "Invalid challenge/rpId", details: nil))
        return
      }

      pendingResult = result
      let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
      let request = provider.createCredentialAssertionRequest(challenge: challenge)
      if let uv = json["userVerification"] as? String, uv == "required" {
        request.userVerificationPreference = .required
      }

      let controller = ASAuthorizationController(authorizationRequests: [request])
      controller.delegate = self
      controller.presentationContextProvider = self
      controller.performRequests()
    } else {
      result(FlutterError(code: "unavailable", message: "Passkeys require iOS 16+", details: nil))
    }
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    if let window = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow }) {
      return window
    }
    return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    defer { pendingResult = nil }
    guard let result = pendingResult else { return }

    if #available(iOS 16.0, *) {
      if let reg = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
        let payload: [String: Any] = [
          "id": Self.base64URLEncode(reg.credentialID),
          "rawId": Self.base64URLEncode(reg.credentialID),
          "type": "public-key",
          "response": [
            "clientDataJSON": Self.base64URLEncode(reg.rawClientDataJSON),
            "attestationObject": Self.base64URLEncode(reg.rawAttestationObject ?? Data()),
          ],
        ]
        if let json = try? JSONSerialization.data(withJSONObject: payload),
           let str = String(data: json, encoding: .utf8) {
          result(str)
        } else {
          result(FlutterError(code: "unknown", message: "Failed to encode registration", details: nil))
        }
        return
      }
      if let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
        var response: [String: Any] = [
          "clientDataJSON": Self.base64URLEncode(assertion.rawClientDataJSON),
          "authenticatorData": Self.base64URLEncode(assertion.rawAuthenticatorData),
          "signature": Self.base64URLEncode(assertion.signature),
        ]
        if let userID = assertion.userID {
          response["userHandle"] = Self.base64URLEncode(userID)
        }
        let payload: [String: Any] = [
          "id": Self.base64URLEncode(assertion.credentialID),
          "rawId": Self.base64URLEncode(assertion.credentialID),
          "type": "public-key",
          "response": response,
        ]
        if let json = try? JSONSerialization.data(withJSONObject: payload),
           let str = String(data: json, encoding: .utf8) {
          result(str)
        } else {
          result(FlutterError(code: "unknown", message: "Failed to encode assertion", details: nil))
        }
        return
      }
    }
    result(FlutterError(code: "unknown", message: "Unexpected credential", details: nil))
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    defer { pendingResult = nil }
    guard let result = pendingResult else { return }
    let ns = error as NSError
    if ns.domain == ASAuthorizationError.errorDomain {
      switch ASAuthorizationError.Code(rawValue: ns.code) {
      case .canceled:
        result(FlutterError(code: "cancelled", message: error.localizedDescription, details: nil))
      case .unknown:
        // Often means no credentials.
        result(FlutterError(code: "no_credential", message: error.localizedDescription, details: nil))
      default:
        result(FlutterError(code: "unknown", message: error.localizedDescription, details: nil))
      }
      return
    }
    result(FlutterError(code: "unknown", message: error.localizedDescription, details: nil))
  }

  private static func base64URLDecode(_ value: String) -> Data? {
    var s = value.replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let pad = 4 - s.count % 4
    if pad < 4 { s += String(repeating: "=", count: pad) }
    return Data(base64Encoded: s)
  }

  private static func base64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
