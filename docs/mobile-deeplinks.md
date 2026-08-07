# Deep links — Wayo Ads Go (Vague 2)

## Custom URL schemes (registered)

| Scheme | Host / path | Purpose |
|--------|-------------|---------|
| `com.wayo.wayoadsgo` | `oauthredirect` | Auth_Wayo OAuth / Google sign-in |
| `com.wayo.wayoadsgo` | `youtube-oauth` | YouTube OAuth return after HTTPS `mobile-callback` |
| `wayo` | (Stripe) | Stripe Connect / PaymentSheet return |

iOS: `CFBundleURLSchemes` includes `com.wayo.wayoadsgo` (covers both hosts).  
Android: separate `intent-filter` entries for `oauthredirect` and `youtube-oauth`.

## YouTube OAuth flow

1. App: `GET /api/creator/youtube/connect?mobile=1&returnApp=adsgo` (+ optional `reconnect=1`) with Bearer.
2. System browser (`FlutterWebAuth2`) opens Google; Google redirects to HTTPS  
   `/api/creator/youtube/mobile-callback` (Web OAuth client).
3. Server completes OAuth, then redirects to  
   `com.wayo.wayoadsgo:/youtube-oauth?success=youtube_connected&channelName=…`
4. App captures deep link — **no tokens on device**.

Env override: `YOUTUBE_ADS_GO_MOBILE_REDIRECT_URI` (default `com.wayo.wayoadsgo:/youtube-oauth`).

## App navigation targets

| Deep link / push | In-app route |
|------------------|--------------|
| YouTube connect FCM / `/settings/youtube` | `/settings/youtube` |
| Creator analytics | `/creator/analytics` |

## Universal Links / App Links (HTTPS)

Not required for YouTube OAuth (custom scheme after HTTPS callback).  
Auth and marketing HTTPS App Links remain separate (Digital Asset Links / apple-app-site-association) when product enables them.
