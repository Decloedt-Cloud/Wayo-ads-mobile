# Home Screen Widgets

Production OS home-screen widgets for **Wayo Ads Mobile** and **Wayo Creator Studio Mobile**.

Native widgets render cached snapshots only. Flutter owns auth, API calls, sanitization, and deep-link routing.

## Architecture

```
Flutter app (authenticated)
  ├─ WidgetDataService        → fetch existing APIs, build snapshot
  ├─ WidgetPreferencesRepository → write sanitized keys (no tokens)
  ├─ WidgetRefreshService     → refresh + HomeWidget.updateWidget
  └─ WidgetDeepLinkService    → wayoads:// / wayocreator:// → go_router

Native widgets (Android AppWidget / iOS WidgetKit)
  └─ read SharedPreferences / App Group UserDefaults → RemoteViews / SwiftUI
```

### Flutter services (both apps)

| Service | Responsibility |
|---------|----------------|
| `WidgetDataService` | Role-aware snapshot from existing repos/providers |
| `WidgetPreferencesRepository` | Persist flat keys + JSON snapshot via `home_widget` |
| `WidgetRefreshService` | Debounced refresh, logout clear, account-switch clear, native update |
| `WidgetDeepLinkService` | URI → in-app route; pending URI for cold start |
| `HomeWidgetHost` | Lifecycle resume, auth listen, click stream |

### Security decisions

- **Never** store access/refresh tokens, Stripe secrets, bank details, or API keys in widget storage.
- Store only presentation fields (formatted balances, counts, labels, `accountIdHash`, empty-state copy).
- Logout / force-logout → `clearForLogout()` writes logged-out shell (no previous private metrics).
- Account switch → `onAccountSwitch(newHash)` clears A before publishing B.
- `TOKEN_EXPIRED` may keep last safe metrics + “Open Wayo to refresh”.

## Design system (native)

| Token | Value |
|-------|--------|
| Background | near-black `#0A0A0A`, 22dp corners |
| Accent | Wayo orange `#F47A1F` (title / CTA / icons only) |
| Primary text | `#FAFAFA` ~26–28sp KPI |
| Secondary | `#8B90A0` ~11–12sp |
| Quick actions | 2×2 icon + short label grid (no stacked web buttons) |

## Wayo Ads widgets

| Widget | Size | Picker name | Android provider |
|--------|------|-------------|------------------|
| Performance | 2×2 | Performance | `PerformanceWidgetProvider` |
| Wallet | 2×1 | Wallet | `WalletWidgetProvider` |
| Quick Actions | 2×2 | Quick Actions | `QuickActionsWidgetProvider` |

### Role behavior

| Role | Performance primary | Wallet | Quick Actions |
|------|---------------------|--------|---------------|
| Advertiser | Spend (or active count) + Active / Views + CTR | Available budget + Reserved | New Campaign, Campaigns, Analytics, Wallet |
| Creator | Earnings + Collabs / Views | Available + Pending | Opportunities, Collabs, Earnings, Analytics |
| SuperAdmin | Platform volume + transactions (no PII) | Volume label | Same advertiser set |

### Snapshot schema (safe)

```json
{
  "accountIdHash": "…",
  "role": "creator",
  "updatedAt": "…",
  "authState": "logged_in",
  "currency": "EUR",
  "balance": 1240.8,
  "pendingBalance": 320,
  "balanceFormatted": "€1,240.80",
  "pendingFormatted": "€320.00",
  "primaryMetricValue": "€1,240.80",
  "primaryMetricLabel": "Earnings",
  "secondaryLeftLabel": "Collabs",
  "secondaryLeftValue": "4",
  "secondaryRightLabel": "Views",
  "secondaryRightValue": "128.4K",
  "emptyHeadline": "",
  "emptyCta": "",
  "localeCode": "en"
}
```

### Deep links

- `wayoads://dashboard`
- `wayoads://campaigns`
- `wayoads://campaigns/create`
- `wayoads://analytics`
- `wayoads://wallet`

App Group: `group.ma.wayo.wayoadsgo`

## Creator Studio widgets

| Widget | Size | Picker name | Android provider |
|--------|------|-------------|------------------|
| AI Credits | 2×1 | AI Credits | `AiCreditsWidgetProvider` |
| Performance | 2×2 | Performance | `ChannelPerformanceWidgetProvider` |
| Quick AI | 2×2 | Quick AI | `AiQuickActionsWidgetProvider` |

### Notes

- Channel “Performance” uses **analysis history** latest video views (existing API) — does **not** fabricate CTR / subscriber deltas.
- Low balance hint when credits ≤ `200` (`CreatorStudioHomeWidgetConstants.lowCreditsThreshold`).
- Quick AI opens Content Lab flows — never runs inference in the widget.

### Deep links

- `wayocreator://dashboard`
- `wayocreator://analytics`
- `wayocreator://ai`
- `wayocreator://ai/title`
- `wayocreator://ai/thumbnail`
- `wayocreator://ai/ctr`
- `wayocreator://ai/retention`

App Group: `group.ma.wayo.wayo_creator_studio`

## Empty / auth states

| State | UI |
|-------|----|
| Logged out | Sign-in headline + Open app CTA |
| Token expired | Cached metrics + refresh message |
| Zero wallet / earnings | Action CTA (opportunities / add funds) — not a wall of zeros |
| No campaigns / generations | Action-oriented empty copy |
| No YouTube | Connect YouTube → analytics |
| Stale / offline | Keep cache + “Updated Xm ago” |
| First install | Logged-out shell |

## Refresh rules

| Trigger | Behavior |
|---------|----------|
| Login | `onAccountSwitch` then force refresh |
| Logout / force logout | Clear → logged-out shell |
| App resume | Debounced refresh (≥45s) |
| Wallet / campaign / AI changes | Prefer calling `WidgetRefreshService.refresh` from existing app events |
| OS period | ~30min (actions: daily) |

## Android widget picker previews

Realistic `previewLayout` resources (demo data only):

- Ads: `widget_*_preview.xml`
- Studio: `widget_ai_credits_preview.xml`, `widget_channel_preview.xml`, `widget_ai_actions_preview.xml`

## Localization

- Flutter writes locale-aware labels / stale hints (`en` / `fr`) into the snapshot.
- Android `values` + `values-fr` cover picker names, QA labels, sign-in strings.

## Test matrix (manual)

**Wayo Ads:** creator/advertiser normal + zero + offline + logout + account switch; SuperAdmin authorized only.

**Creator Studio:** credits / zero / low / YouTube missing / no generations / logout / account switch.

**UI:** small/standard grids, dark wallpaper, font scale, FR/EN.

## Native files

### Wayo Ads (`Wayo-ads-mobile`)

- Flutter: `lib/features/home_widgets/**`
- Android: `widgets/WayoAdsWidgets.kt`, `res/layout/widget_*.xml`, `res/xml/widget_*_info.xml`, `drawable/ic_widget_action_*.xml`
- iOS: `ios/WayoAdsWidgets/`
- Tests: `test/features/home_widgets/widget_snapshot_test.dart`

### Creator Studio (`wayo-creator-studio-mobile`)

- Flutter: `lib/features/home_widgets/**`
- Android: `widgets/StudioWidgets.kt`, layouts/xml/previews
- iOS: `ios/WayoCreatorWidgets/`
- Tests: `test/features/home_widgets/widget_snapshot_test.dart`

## Package

Both apps depend on [`home_widget`](https://pub.dev/packages/home_widget) `^0.7.0`.
