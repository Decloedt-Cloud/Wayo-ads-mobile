package ma.wayo.wayoadsgo

import android.app.Activity
import android.os.Build
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Native WebAuthn / passkeys via AndroidX Credential Manager.
 * Private keys never leave the credential provider.
 */
object PasskeysPlugin {
    private const val CHANNEL = "wayo/passkeys"
    private val executor = Executors.newSingleThreadExecutor()

    fun register(activity: Activity, flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(isAvailable())
                "create" -> handleCreate(activity, call, result)
                "authenticate" -> handleAuthenticate(activity, call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun isAvailable(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
    }

    private fun handleCreate(
        activity: Activity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (!isAvailable()) {
            result.error("unavailable", "Passkeys require Android 9+", null)
            return
        }
        val requestJson = call.argument<String>("requestJson")
        if (requestJson.isNullOrBlank()) {
            result.error("configuration", "Missing requestJson", null)
            return
        }
        val cm = CredentialManager.create(activity)
        val request = CreatePublicKeyCredentialRequest(requestJson)
        cm.createCredentialAsync(
            activity,
            request,
            null,
            executor,
            object : CredentialManagerCallback<
                androidx.credentials.CreateCredentialResponse,
                CreateCredentialException,
                > {
                override fun onResult(response: androidx.credentials.CreateCredentialResponse) {
                    activity.runOnUiThread {
                        val typed = response as? CreatePublicKeyCredentialResponse
                        val json = typed?.registrationResponseJson
                        if (json.isNullOrBlank()) {
                            result.error("unknown", "Empty registration response", null)
                        } else {
                            result.success(json)
                        }
                    }
                }

                override fun onError(e: CreateCredentialException) {
                    activity.runOnUiThread {
                        when (e) {
                            is CreateCredentialCancellationException ->
                                result.error("cancelled", e.message, null)
                            else -> result.error(mapCreateError(e), e.message, null)
                        }
                    }
                }
            },
        )
    }

    private fun handleAuthenticate(
        activity: Activity,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        if (!isAvailable()) {
            result.error("unavailable", "Passkeys require Android 9+", null)
            return
        }
        val requestJson = call.argument<String>("requestJson")
        if (requestJson.isNullOrBlank()) {
            result.error("configuration", "Missing requestJson", null)
            return
        }
        val cm = CredentialManager.create(activity)
        val option = GetPublicKeyCredentialOption(requestJson)
        // Prefer local/synced credentials only. When the user revoked the last
        // passkey (or none exist on this device), fail with NoCredentialException
        // instead of showing the OS "scan QR / other device" empty sheet.
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(option)
            .setPreferImmediatelyAvailableCredentials(true)
            .build()
        cm.getCredentialAsync(
            activity,
            request,
            null,
            executor,
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(response: GetCredentialResponse) {
                    activity.runOnUiThread {
                        val credential = response.credential
                        if (credential is PublicKeyCredential) {
                            result.success(credential.authenticationResponseJson)
                        } else {
                            result.error("unknown", "Unexpected credential type", null)
                        }
                    }
                }

                override fun onError(e: GetCredentialException) {
                    activity.runOnUiThread {
                        when (e) {
                            is GetCredentialCancellationException ->
                                result.error("cancelled", e.message, null)
                            is NoCredentialException ->
                                result.error("no_credential", e.message, null)
                            else -> {
                                val name = e.javaClass.simpleName
                                if (name.contains("Interrupted", ignoreCase = true)) {
                                    result.error("interrupted", e.message, null)
                                } else {
                                    result.error(mapGetError(e), e.message, null)
                                }
                            }
                        }
                    }
                }
            },
        )
    }

    private fun mapCreateError(e: CreateCredentialException): String {
        val name = e.javaClass.simpleName
        val msg = (e.message ?: "").lowercase()
        // Credential Manager / Samsung Pass / GPM when excludeCredentials matches
        // or the provider already has a passkey for this RP.
        if (
            name.contains("NoCreateOption", ignoreCase = true) ||
            name.contains("Duplicate", ignoreCase = true) ||
            msg.contains("already") ||
            msg.contains("déjà") ||
            msg.contains("dejà") ||
            msg.contains("exist")
        ) {
            return "already_exists"
        }
        return when {
            name.contains("Cancellation", ignoreCase = true) -> "cancelled"
            name.contains("Unsupported", ignoreCase = true) -> "unavailable"
            else -> "unknown"
        }
    }

    private fun mapGetError(e: GetCredentialException): String {
        val name = e.javaClass.simpleName
        return when {
            name.contains("Cancellation", ignoreCase = true) -> "cancelled"
            name.contains("NoCredential", ignoreCase = true) -> "no_credential"
            name.contains("Interrupted", ignoreCase = true) -> "interrupted"
            name.contains("Unsupported", ignoreCase = true) -> "unavailable"
            else -> "unknown"
        }
    }
}
