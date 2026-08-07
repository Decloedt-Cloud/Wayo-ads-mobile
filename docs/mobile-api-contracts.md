# Wayo Ads Go — Contrats API (Vague 0)

Contrats **vérifiés dans le code** pour les features IN SCOPE.  
Auth mobile : `Authorization: Bearer <access_token>` (Auth_Wayo Passport).

---

## 1. Identité

| Action | Service | Méthode / path | Notes |
|--------|---------|----------------|-------|
| Login | Auth_Wayo | `POST /api/auth/login` | Device gate → 403 `device_approval_required` |
| Google/Apple | Auth_Wayo | `POST /api/auth/google\|apple` | |
| Refresh | Auth_Wayo | `POST /oauth/token` | `grant_type=refresh_token` |
| Logout | Auth_Wayo | `POST /api/auth/logout` | |
| User | Auth_Wayo | `GET /api/auth/user` | |
| Change password | Auth_Wayo / Ads | `PATCH /api/auth/change-password` ou `/api/user/password` | |
| Passkeys handoff | Wayo-ads | `GET /api/settings/passkeys-handoff` | URL Auth web |
| Connected accounts handoff | Wayo-ads | `GET /api/settings/connected-accounts-handoff` | |
| Device approval | Wayo-ads | `/api/auth/device-approval` | |

---

## 2. Campagnes (annonceur)

### `POST /api/campaigns`

Création / brouillon. Bearer OK.

Champs clés (Zod `createCampaignSchema`) :

- `title` (1–200), `description` ≤2000  
- `type`: `LINK|VIDEO|SHORTS`  
- `campaignObjective`: `AWARENESS|TRAFFIC`  
- `niche`: enum `CampaignNiche`  
- `landingUrl` requis si LINK  
- `assetsUrl` : 1–5 URLs HTTPS allowlist si VIDEO/SHORTS  
- `brandLogoUrl` : path `/uploads/campaign-logos/logo-*.{png,jpg,webp}`  
- `totalBudgetCents` : 1000…100_000_000  
- `cpmCents` / `cpcCents` bornés anti-abus  
- `campaignEndDate` : `YYYY-MM-DD` futur **requis**  
- Geo : `isGeoTargeted`, `targetCountryCode` (requis si geo), `targetCity`, lat/lng, `targetRadiusKm` 1–1000  
- `status` optionnel → défaut `DRAFT`  
- ACTIVE à la création : create DRAFT → lock budget → ACTIVE  

**Pas d’Idempotency-Key aujourd’hui** (à ajouter Vague 1).

### `PATCH /api/campaigns/[id]`

Owner ADVERTISER. Budget **verrouillé** si ACTIVE/PAUSED (`BUDGET_LOCKED`).  
Status via body `{ status }` — transitions côté `handleStatusChange`.

### `POST /api/campaigns/upload-logo`

Body JSON `{ data: "data:image/...;base64,..." }`  
MIME : png/jpeg/webp · max 2MB  
**Gap :** `requireRole('ADVERTISER')` sans `request` → corriger pour Bearer.

### `GET /api/campaigns/[id]/analytics`

Bearer OK. Agrégats trafic/submissions + séries quotidiennes.

### `GET /api/advertiser/campaigns/[id]/financial-summary`

**Gap session-only.** Réponse : budgets, spent, reserved, effectiveCPM, validation/fraud rates, confidenceBadge, dailySpend[7].

### Applications / posts / insights / match

| Path | Méthode |
|------|---------|
| `/api/campaigns/[id]/applications` | GET |
| `.../applications/[id]/approve\|reject` | POST |
| `.../posts/[postId]/approve\|reject` | POST |
| `.../creators/[creatorId]/insights` | GET |
| `.../insights/refresh` | POST |
| `.../ai-match-score` | GET |
| `.../ai-match-score/refresh` | POST |
| `.../advertiser-conversation` | GET |

---

## 3. Marketplace créateur

| Path | Méthode | Usage |
|------|---------|-------|
| `/api/campaigns` | GET | Browse (filters) |
| `/api/campaigns/[id]/apply` | POST | Candidature |
| `/api/creator/campaigns/[id]/submit-post` | POST | Soumettre URL |
| `/api/campaigns/[id]/links` | GET/POST | Tracking links |
| `/api/creator/analytics` | GET | Page analytics |
| `/api/creator/trust-score` | GET | Score public |
| `/api/creator/dashboard-summary` | GET | Home |
| `/api/creator/youtube/connect?mobile=1` | GET | PKCE payload |
| `/api/creator/youtube/mobile-complete` | POST | Échange code |
| `/api/creator/youtube/channel` | GET | Statut |
| `/api/creator/youtube/disconnect` | POST | Révocation |
| `/api/creator/youtube/refresh` | POST | Refresh données |

---

## 4. Wallet & paiements

| Path | Méthode | Notes |
|------|---------|-------|
| `/api/wallet` | GET | Solde |
| `/api/wallet/config` | GET | PSP publishable / mode |
| `/api/wallet/deposit-intent` | POST/GET/DELETE | Create/resume/cancel |
| `/api/wallet/confirm-deposit` | POST | Post-PaymentSheet |
| `/api/wallet/deposits/[intentId]/reconcile` | POST | |
| `/api/wallet/saved-cards` | GET/DELETE | **Non branché mobile** |
| `/api/wallet/saved-cards/refresh` | POST | |
| `/api/creator/withdrawal` | POST | |
| `/api/creator/stripe-connect/*` | * | onboard/status/refresh/login |
| `/api/webhooks/psp` | POST | Serveur only |

---

## 5. Compte & notifications

| Path | Méthode |
|------|---------|
| `/api/user/profile` | GET/PATCH |
| `/api/user/export-data` | GET |
| `/api/user/delete-account` | * |
| `/api/user/sessions` | GET/POST |
| `/api/user/devices` | GET/POST |
| `/api/notifications` | GET |
| `/api/notifications/preferences` | GET/PATCH |
| `/api/notifications/read` | POST |
| `/api/creator/business-profile` | GET/PUT |

---

## 6. Chat

### Wayo-ads bridge

- `/api/chat/token`  
- `/api/chat/user-profiles`  
- `/api/chat/user-roles`  
- `/api/chat/media-download`  
- `/api/chat/link-preview`  

### chat-service (Sanctum)

Préfixe `/api/v1` :

- `conversations` CRUD subset (index/store/show/destroy)  
- `conversations/unread-count`  
- `conversations/{id}/read`  
- messages, participants, typing, broadcasting  

**Absents :** `pin`, `unpin`, `archive`, `unarchive`.

---

## 7. Admin (`requireSuperAdmin`)

Préfixes `/api/admin/` (inventaire) :

`users`, `app-bans`, `withdrawals`, `payouts`, `announcements`, `ai`, `ledger`, `tax-rates`, `transactions`, `platform-settings`, `stripe-settings`, `email-settings`, `company-business-info`, `token-packages`, `token-purchases`, `payment-audits`, `payment-reconciliation`, `invoices`, `payment-statements`, `notifications`, `emails`, `audit-log`, `click-pipeline`, `creator-velocity`, `recent-activity`, `health`, `jobs`, `platform-branding`, `cache-metrics`, `debug`, …

Mobile consomme aujourd’hui un **sous-ensemble** (users, bans, withdrawals, announcements, AI usage, ledger, tax, browse).

---

## 8. Erreurs structurées attendues (mobile)

Mapper au minimum :

| HTTP | Signification UX |
|------|------------------|
| 400 | Validation field errors |
| 401 | Session expirée → refresh puis logout |
| 403 | Forbidden / device_approval_required / rôle |
| 404 | Ressource absente **ou** masquée (anti-énumération) |
| 409 | Conflit / budget lock |
| 422 | Métier (BUDGET_LOCKED, CAMPAIGN_ENDED, …) |
| 429 | Rate limited — backoff |
| 5xx | Retryable borné |

Ne jamais afficher stack traces / messages internes Prisma.

---

## 9. Compatibilité versions

- Nouveaux champs réponse : additive only.  
- Feature flags serveur recommandés pour admin P2 et pin/archive chat.  
- Ordre déploiement : **fix Bearer endpoints → mobile release**.  
