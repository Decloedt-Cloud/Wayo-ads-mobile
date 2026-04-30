# Design system — typography (Wayo Ads Go)

## Page title — H1

**Token:** `AppTextStyles.pageTitle(BuildContext)`  
**Theme mirror:** `Theme.of(context).appBarTheme.titleTextStyle` / `AppTextStyles.pageTitleForTheme(Color)` in `AppTheme`

| Attribute | Value |
|-----------|--------|
| Font | Inter (`GoogleFonts.inter`) |
| Size | 32 |
| Weight | 800 |
| Height | 1.1 |
| Letter spacing | -0.85 |
| Color | `AppColors.textPrimaryOf(context)` (body); AppBar uses theme `onSurface` |

**Usage**

- **One H1 per screen or tab**: dashboard headers, wallet tab titles, campaigns browse header, modal sheet titles that act as a “page”, detail hero titles where the main subject is the screen focus, etc.
- **Do not use** for section labels (“Campaigns”, “History”), card titles, list section headers, or KPI numbers — use `headlineMedium`, `labelLarge`, or `caption` instead.
- **Marketing / auth heroes** (e.g. login wordmark) keep `AppTextStyles.displayLarge` (42 / 800) — not interchangeable with `pageTitle`.

## Section title — H2

**Token:** `AppTextStyles.headlineMedium(BuildContext)`

| Attribute | Value |
|-----------|--------|
| Size | 24 |
| Weight | 700 |
| Letter spacing | -0.4 |

Use for in-page sections and secondary lines under an H1 (e.g. welcome subtitle blocks).

## Other tokens

Defined in `app_text_styles.dart`: `bodyLarge`, `labelLarge`, `caption`.

When adding a new full-screen route, prefer the default `AppBar` title (inherits H1) or an explicit `AppTextStyles.pageTitle(context)` on the first heading in a custom layout.
