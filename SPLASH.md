# Wayo Ads Go — Splash (“Signal Ignition”)

## Overview

Cold start uses a **native splash** (`#0A0A0A` + orange dot asset) then a **Flutter splash** at route `/splash` with a single master `AnimationController` (0→1). A separate looping controller drives radar ripples and the liquid-metal shader time. After the sequence, the app navigates to `/` and the existing `go_router` redirect sends users to `/login` or `/dashboard`.

## Timeline (master 0 → 1 over 2500 ms)

| Phase | Master interval | Effect |
|--------|-----------------|--------|
| Dot | 0.00–0.12 | Orange glow dot |
| Scan | 0.12–0.28 | Horizontal laser line |
| Burst | 0.28–0.44 | ~80 particles explode |
| Assembly | 0.44–0.64 | Magnetic gather to ring |
| Snap | 0.64–0.72 | Elastic scale + white flash window 0.68–0.72 |
| Wordmark | 0.72–0.88 | “wayo ads” laser reveal |
| Shockwave | 0.88–1.00 | Expanding rings, then `context.go('/')` |

Haptics (master fractions): **0.12** selection, **0.44** light, **0.68** medium, **0.88** heavy.

## Second launch (1 s)

If `AppPrefs` key `splash.v1.completed_once` is `'1'`, the same intervals run on a **1000 ms** master duration (faster “Signal Ignition”). Skip is allowed after **400 ms** wall time on this variant (still tap anywhere).

## Reduced motion

When `MediaQuery.disableAnimations` is true, a **400 ms** simplified fade shows the canvas logo + wordmark; haptics still follow the same fractional beats if the controller runs.

## Parallax

On Android and iOS only, the splash subscribes to the `sensors_plus` accelerometer stream **after the first frame** for a subtle **3D tilt** (`Matrix4` perspective + rotate). If the native plugin is not linked (common after **hot restart** without a full rebuild), the stream errors are handled: subscription is cancelled and a light **ambient** tilt (sine/cosine from the master timeline) is used instead — no crash, no red screen.

To get real sensor tilt again: **stop the app** and run `flutter run` (or `flutter clean` then run) so Gradle/Xcode embed the plugin.

iOS includes `NSMotionUsageDescription` for motion APIs.

## Liquid metal shader

Asset: `shaders/liquid_metal.frag`. Loaded with `FragmentProgram.fromAsset`. If load/compile fails, the splash falls back to solid `#0A0A0A`.

## Native splash

Configured in `pubspec.yaml` under `flutter_native_splash`. Regenerate after asset changes:

```bash
dart run flutter_native_splash:create
```

Regenerate the dot PNG (192×192, transparent, orange circle):

```bash
dart tool/generate_splash_dot.dart
```

## Colours & tuning

- Brand colours: `lib/core/theme/app_colors.dart` (`AppColors.primary`, `black`, etc.).
- Intervals: `lib/features/splash/controllers/splash_sequence.dart`.
- Painters: `lib/features/splash/painters/`.

## Dependencies added for this feature

- `flutter_native_splash` (dev) — native launch screen.
- `sensors_plus` — accelerometer parallax.
