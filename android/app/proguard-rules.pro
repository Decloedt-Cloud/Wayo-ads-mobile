## Stripe SDK — React Native Stripe SDK bundled inside flutter_stripe references
## optional Push Provisioning classes. We don't use this feature, so silence
## R8's "Missing class" errors and keep Stripe internals reachable via reflection.
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }

## General Stripe keep rules (safe defaults — Stripe internals use reflection).
-keep class com.stripe.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.**
-dontwarn com.reactnativestripesdk.**

## Google Pay (Wallet) — referenced via reflection by Stripe.
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**

## Keep Flutter plugin registrants and generic Flutter embedding symbols.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
