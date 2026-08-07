# Wayo Ads — Web ↔ Mobile parity matrix (living)

**Last updated:** 2026-08-06  
**Web source of truth:** `Wayo-ads` (branch `preprod`) — App Router `src/app`, ~132 pages, ~269 API routes, Prisma 63 models  
**Mobile target:** `Wayo-ads-mobile` (`wayoadsgo` / `ma.wayo.wayoadsgo`, branch `master`)  
**Shared auth:** `Auth_Wayo` · **Chat realtime:** `chat-service`  
**AI / Creator Studio:** Content Lab / Content Spy / `/api/creator/ai/*` / AI tokens live in **`wayo-creator-studio-mobile`** (not Ads Go) — see that app’s `docs/web-ai-mobile-parity.md`

Related: [`mobile-parity-audit.md`](./mobile-parity-audit.md), [`mobile-api-contracts.md`](./mobile-api-contracts.md), [`mobile-deeplinks.md`](./mobile-deeplinks.md), [`campaign-create-parity.md`](./campaign-create-parity.md)

---

## Status legend

| État | Meaning |
|------|---------|
| `absent` | No mobile surface |
| `partiel` | Screen/API partial or unrouted |
| `implémenté` | Routed + wired to same API |
| `testé` | + unit/widget/contract coverage |
| `bloqué` | External/policy blocker documented |

---

## Session progress (2026-08-06) — Ads Go 1A + 2B

### Done this tranche
- **A1 notification prefs:** `GET/PATCH /api/notifications/preferences` — channels × categories; `/settings/notifications`; FCM allowlist; domain + Dio tests
- **A2 export data:** `/settings/privacy` — Bearer export JSON + share sheet
- **A3 passkeys / connected accounts:** Bearer JSON handoff → in-app Auth WebView — **implémenté** (RP = Auth host; pas de WebAuthn natif)
- **B1 trust score:** dashboard card + analytics card/breakdown (`validationRatePoints` / fraud / anomaly); domain tests
- **B2 creator/advertiser ZIP invoices (and payouts zip):** wired via invoices tab + repository Dio tests
- **B3 campaign create:** widget tests 3-step / double-tap / idempotency; Samsung smoke = **READY FOR DEVICE**
- **B4 analytics density:** creator analytics + campaign financial-health / analytics empty/error/retry + key payload fields
- **C SA:** hub More + packages create/edit/activate + **Sync Stripe** catalog; secrets / SMTP / hard-delete / ZIP / send-test lifted; `syncTokenPackageStripe` Dio test added; package form now has optional Apple/Google store product ID fields (Studio IAP, see below)

### Sensitive SA ops (lifted 2026-08-06)
- Stripe secret rotation / reveal / active-mode / test-connection
- SMTP email settings (+ test-email) at `/superadmin/email-settings`
- Hard-delete users (double confirm)
- Admin financial ZIP bulk (invoices + payout statements)
- Email template send-test
- Token packages Stripe catalog sync

AI remains on **Creator Studio mobile** (product split), not Ads Go.

---

## Shared / account

| ID | Rôle | Source Web | Actions | API | Cible mobile | État | Écart |
|----|------|------------|---------|-----|--------------|------|-------|
| SH-AUTH | partagé | `/auth/*` | login, signup, Google, Apple, OTP, forgot pwd | Auth_Wayo + ads session | `/login`, `/signup/*`, `/forgot-password/*` | implémenté | Device-approval UX largely Auth; copy polish TBD |
| SH-ONB | partagé | role / verify email | onboarding gates | profile / role | `/onboarding/*` | implémenté | |
| SH-PROF | partagé | `/settings` | profile, password, devices, export | `/api/user/*`, export-data | `/settings/profile\|security\|trusted-devices\|privacy` | testé | Export wired 2026-08-06 |
| SH-PASSKEYS | partagé | PasskeysCard | list/add/remove | Auth WebAuthn via handoff | `/settings/passkeys` WebView | implémenté | Auth handoff WebView (WebAuthn host = Auth) |
| SH-CONNECTED | partagé | ConnectedAccountsCard | Google/Apple unlink | Auth handoff | `/settings/connected-accounts` WebView | implémenté | Auth handoff WebView (WebAuthn host = Auth) |
| SH-GUIDES | partagé | `/resources/*` | read | public HTML | `/resources` WebView | implémenté | Marketing guides in-app |
| SH-DEL | partagé | delete account 30d | schedule / cancel | delete-account | `/settings/delete-account` | implémenté | |
| SH-NOTIF | partagé | `/notifications` + prefs | list, read, prefs | `/api/notifications*` | `/notifications` + `/settings/notifications` | testé | Categories × inApp/email + OS push tile |
| SH-CHAT | partagé | `/dashboard/messages`, role messages | CRUD, realtime, media | chat-service via `/api/chat/token` | `/chat`, `/chat/thread/:id` | implémenté | Inbox pin/archive wired |
| SH-PUSH | partagé | FCM | register device | `/api/user/push-device` | core/push | implémenté | Settings deep-links allowlisted 2026-08-06 |
| SH-MAINT | partagé | health/503 | gate + recover | `/api/health` | MaintenanceGate | implémenté | |
| SH-LEGAL | partagé | terms/privacy/cookies | read | static | `/privacy\|terms\|cookie-policy` | implémenté | |

---

## Advertiser

| ID | Source Web | Actions | API | Cible mobile | État | Écart |
|----|------------|---------|-----|--------------|------|-------|
| AD-HOME | `/dashboard/advertiser` | KPIs | dashboard-summary | `/dashboard` | implémenté | |
| AD-CAMP-LIST | `/campaigns?mine` | list/filter/page | `/api/campaigns` | `/campaigns` | implémenté | |
| AD-CAMP-NEW | `/advertiser/campaigns/new` | create draft/activate | POST `/api/campaigns` + Idempotency-Key | `/advertiser/campaigns/new` | testé | 16:9 logo crop; Samsung smoke checklist in campaign-create-parity.md |
| AD-CAMP-EDIT | `…/[id]/edit` | update | PATCH `/api/campaigns/[id]` | `/advertiser/campaigns/:id/edit` | implémenté | Same editor |
| AD-CAMP-DETAIL | `/campaigns/[id]` | view apps, actions | campaigns/[id]* | `/campaigns/:id` | implémenté | |
| AD-CAMP-ANALYTICS | campaign analytics | read | `…/analytics` | `/advertiser/campaigns/:id/analytics` | implémenté | Field density + empty/retry 2026-08-06 |
| AD-CAMP-HEALTH | financial-health | read | financial-summary | `/advertiser/campaigns/:id/financial-health` | implémenté | Billable views/clicks + empty/retry |
| AD-STATUS | PATCH status | pause/resume/publish/cancel | PATCH status | owner actions bar | implémenté | Budget exhausted ≠ COMPLETED (server rule) |
| AD-VIDEO | `/advertiser/video-reviews` | approve/reject | posts/* | `/advertiser/video-reviews` | implémenté | |
| AD-CREATORS | `/advertiser/creators` | browse | `/api/advertiser/creators` | `/advertiser/creators` | implémenté | |
| AD-WALLET | `/advertiser/wallet` | deposit Stripe + ACH/wire + saved cards | `/api/wallet*` | `/wallet` | testé | Card/Apple/Google Pay, saved cards, ACH/wire, reconcile |
| AD-INV | `/advertiser/invoices` | list/PDF/ZIP | invoices + zip | `/invoices` | testé | ZIP download wired |
| AD-BIZ | `/advertiser/business` | business profile | business-profile GET/PUT | `/advertiser/business` | implémenté | |
| AD-MSG | messages | chat | chat | `/chat` | implémenté | |

---

## Creator (Ads marketplace — not Studio AI)

| ID | Source Web | Actions | API | Cible mobile | État | Écart |
|----|------------|---------|-----|--------------|------|-------|
| CR-HOME | `/dashboard/creator` | pipeline + trust | dashboard-summary, trust-score | `/dashboard` | implémenté | Trust card on home 2026-08-06 |
| CR-MKT | `/campaigns` | browse/apply | campaigns, apply | `/campaigns` | implémenté | |
| CR-DETAIL | `/campaigns/[id]` | apply/submit | apply, submit-post | `/creator/campaigns/:id` | implémenté | |
| CR-APP | application detail | tracking links | links | `…/application` | implémenté | |
| CR-YT | `/settings/youtube` | connect/disconnect | youtube mobile-* | `/settings/youtube` | implémenté | |
| CR-TRUST | trust score | read + breakdown | trust-score | dashboard card → `/creator/analytics` | testé | Breakdown panel when API provides fields |
| CR-ANALYTICS | `/creator/analytics` | read | `/api/creator/analytics` | `/creator/analytics` | implémenté | Density + trust card/breakdown |
| CR-WALLET | `/creator/wallet` | Connect, withdraw | stripe-connect, withdrawal | `/wallet` | implémenté | |
| CR-PAYOUTS | `/creator/payouts` | docs/history/ZIP | payouts + zip | `/creator/payouts` (+ invoices tab ZIP) | testé | Creator ZIP invoices/payouts via invoices tab |
| CR-BIZ | `/creator/business` | business info | business-profile | `/creator/business` | implémenté | |
| CR-TOKENS | `/creator/tokens` | AI credits | tokens/* | — | absent | **Intentional** → Creator Studio |

---

## Super-admin

| ID | Source Web | Cible mobile | État | Écart |
|----|------------|--------------|------|-------|
| SA-HOME | `/dashboard/admin` hub | `/superadmin` tabs + More | implémenté | All already-routed panels linked in More menu |
| SA-USERS | users / bans | users + `/superadmin/banned-users` | testé | Soft ban/unban + detail + **hard-delete** (double confirm) |
| SA-WD | `/admin/withdrawals` | tab withdrawals | implémenté | |
| SA-ANN | announcements | tab | implémenté | |
| SA-AI | ai-usage | `/superadmin/ai-usage` | implémenté | |
| SA-LEDGER | ledger | `/superadmin/ledger` | implémenté | |
| SA-TAX | tax-rates | `/superadmin/tax-rates` | implémenté | |
| SA-BROWSE | campaigns browse | `/superadmin/browse-campaigns` | implémenté | |
| SA-PAY | payment-audits (+ fees/recon) | `/superadmin/payment-audits` | testé | Transactions + By advertiser + reconcile + Stripe link |
| SA-TOK | token-packages, purchases | `/superadmin/token-purchases`, `/token-packages` | testé | Create/edit/activate + **Sync Stripe** catalog |
| SA-SET | stripe/platform/email/business settings | `/platform-settings`, `/stripe-settings`, `/email-settings` | testé | Platform R/W + Stripe secrets rotate/reveal + SMTP R/W |
| SA-MAIL | emails, notifications broadcast | `/email-logs`, `/email-templates`, `/broadcast` | testé | Logs + preview + **send-test** + broadcast |
| SA-AUDIT | audit-log (+ pipeline/velocity/YT) | audit-log, click-pipeline, creator-velocity, youtube-monitoring | implémenté | YT list/filters via existing API; richer desktop tooling web |
| SA-HEALTH | admin health/jobs | `/health`, `/jobs` | implémenté | KPIs + services + manual job runner |
| SA-ACT | recent-activity | `/superadmin/recent-activity` | implémenté | |
| SA-DOCS | financial-documents | `/superadmin/financial-documents` | testé | Browse + **ZIP bulk** invoices/payouts |

---

## API matrix (selected — Ads Go consumers)

| Method | Path | Auth | Mobile consumer | Notes |
|--------|------|------|-----------------|-------|
| POST | Auth_Wayo login/google/apple | public | auth_repository | Passport PAT |
| GET/PATCH | `/api/notifications/preferences` | Bearer | notification_prefs | Categories × channels |
| GET | `/api/user/export-data` | Bearer | privacy_export | JSON download + share |
| GET/POST | `/api/campaigns` | Bearer | advertiser + creator repos | Idempotency-Key on create |
| PATCH | `/api/campaigns/[id]` | owner | editor + status actions | |
| POST | `/api/campaigns/[id]/apply` | creator | creator_campaigns | |
| GET | `/api/creator/trust-score` | creator | creator_trust | Breakdown optional |
| GET | `/api/creator/analytics` | creator | creator_analytics | |
| POST | `…/invoices/zip`, payouts zip | Bearer | invoices | Creator + advertiser |
| GET/POST/PUT | `/api/admin/token-packages` (+ sync-stripe) | SA | superadmin_ops | Create/edit/activate + Sync Stripe |
| GET | `/api/wallet*` | advertiser | wallet | Stripe PI server-side |
| POST | `/api/creator/youtube/mobile-complete` | creator | youtube_connection | |
| GET | `/api/chat/token` | any | chat bootstrap | |
| POST/DELETE | `/api/user/push-device` | any | wayo_push_device_register | |

Full contracts: [`mobile-api-contracts.md`](./mobile-api-contracts.md).

---

## Counts (approx.)

| Domain | Web capabilities in scope | Mobile `implémenté`/`testé`/`bloqué` | Remaining in-scope |
|--------|---------------------------|--------------------------------------|--------------------|
| Shared | ~12 | ~12 | Passkeys/connected via Auth handoff WebView |
| Advertiser | ~14 | ~14 | Campaigns + wallet payment **100%** |
| Creator ads | ~11 (− AI) | ~10 | Marketplace **100%**; AI → Studio |
| Super-admin | ~16 | ~16 | Incl. Stripe package sync + payment audits |

**Produit mobile Ads Go + Studio : aligné web pour métier, paiement, SA, guides, passkeys/connected (handoff Auth).** Studio IAP : `TokenPackage.appleProductId`/`googleProductId` (Prisma, nullable) exposés par `GET /api/tokens/packages` + admin token-packages ; Stripe reste le chemin par défaut tant qu’aucun store ID n’est configuré. `POST /api/tokens/iap/confirm` vérifie le reçu Apple (`APPLE_SHARED_SECRET`) ou renvoie `501` (Android + Apple sans clé) — voir `wayo-creator-studio-mobile/docs/web-ai-mobile-parity.md`.
