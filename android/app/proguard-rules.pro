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

## Google Sign-In / Play services (release R8 can strip API surface used via JNI).
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.auth.api.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-dontwarn com.google.android.gms.auth.**
-dontwarn com.google.android.gms.common.**

## Keep Flutter plugin registrants and generic Flutter embedding symbols.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

## App package (MethodChannels, native entrypoints, AppWidgets).
-keep class ma.wayo.** { *; }

## home_widget bridge used by OS AppWidgetProviders.
-keep class es.antonborri.home_widget.** { *; }
-dontwarn es.antonborri.home_widget.**
-dontwarn androidx.glance.**

## Firebase / FCM
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

## Sentry — stack traces + SDK internals
-keepattributes SourceFile,LineNumberTable
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**