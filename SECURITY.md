# Wayo Ads Go — security notes (mobile)

## TLS certificate pins (release only)

Pins are **SHA-256 hashes of the server certificate DER**, encoded as **Base64** (same format the app compares in `CertificatePinning`).

### Extract a pin (OpenSSL)

Replace `HOST` with your API hostname (e.g. `auth.wayo.com`):

```bash
openssl s_client -servername HOST -connect HOST:443 </dev/null 2>/dev/null \
  | openssl x509 -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl base64 -A
```

Use the single-line Base64 output as `CERT_PIN_PRIMARY`, `CERT_PIN_BACKUP`,
`CERT_PIN_EXTRA`, or `CERT_PIN_ALT` in `dart_defines.json` / `--dart-define-from-file`
when you have multiple API origins or **two valid leaf certs for the same host**
(e.g. CDN/Cloudflare edge vs **origin** on the VPS — `openssl` on the server often shows the origin cert while mobile clients see the edge cert).

### Rotation (two pins)

1. Add the **new** certificate hash as `CERT_PIN_BACKUP` (or `CERT_PIN_ALT`) while keeping the current `CERT_PIN_PRIMARY`.
2. Ship the app; confirm traffic works.
3. Swap: move backup to primary, generate a new backup for the next rotation.

If both pins are empty in a **release** build, pinning stays off and a **warning** is printed once at adapter setup (see app logs).

## Sentry debug symbols

After a release build with `--split-debug-info=build/symbols`, upload symbols so stack traces are readable:

```bash
sentry-cli upload-dif build/symbols
```

Configure `sentry-cli` with your org/project and auth token per [Sentry docs](https://docs.sentry.io/product/cli/).

## Scrubbed fields (logs + Sentry)

The following keys are replaced with `***REDACTED***` anywhere they appear in structured maps (case-insensitive), including nested maps and lists:

- `authorization`
- `cookie`, `set-cookie`
- `password`, `password_confirmation`
- `access_token`, `refresh_token`, `reset_token`
- `otp`
- `token`, `secret`
- `x-app-key`

Debug Dio logs always pass headers and bodies through this scrubber. Sentry `beforeSend` scrubs `request.headers`, `request.data`, and `extra`.

## Android cleartext / local HTTP

- **Release / `main` manifest**: `android:usesCleartextTraffic` is **false** (HTTPS-only policy).
- **Debug builds** (`android/app/src/debug/AndroidManifest.xml`): cleartext is **allowed** so `http://…` vers une machine de dev fonctionne.

### `localhost` vs émulateur Android

Sur un **émulateur ou téléphone Android**, `http://localhost:8000` désigne **l’appareil**, pas ton PC : la connexion échoue en général avec *Connection refused*.

- **Émulateur Android → serveur sur le PC** : utilise `http://10.0.2.2:8000` dans `dart_defines.json` (`AUTH_WAYO_BASE_URL` / `AUTH_BASE_URL`).
- **Appareil physique** : utilise l’**adresse IP LAN** de ton PC (ex. `http://192.168.1.10:8000`), même Wi‑Fi.
- **Simulateur iOS** : `http://127.0.0.1:8000` ou `localhost` pointe en général vers le Mac hôte — OK pour du dev local.

## iOS App Transport Security

The project does **not** set `NSAllowsArbitraryLoads`; only HTTPS endpoints should be used for production auth/API bases.
