# Wayo Ads Go — Vague 0 · Audit de parité web/mobile

**Date :** 2026-08-03  
**Dépôts inspectés :** `Wayo-ads`, `Wayo-ads-mobile`, `Auth_Wayo`, `chat-service`  
**Périmètre :** marketplace Ads (annonceur, créateur ads, chat, compte, superadmin)  
**Exclu :** Content Lab, Content Spy, outils Creator Studio / `/api/creator/ai/*` (hors match-score campagne)

Machine-readable : [`mobile-parity-audit.json`](./mobile-parity-audit.json)

---

## 1. Architecture réellement trouvée

```
┌──────────────────────┐  ┌──────────────────────┐
│  Wayo Ads Go (Flutter)│  │  Web Wayo-ads (Next) │
│  Dio Auth + Dio Ads  │  │  NextAuth session    │
└─────────┬────────────┘  └──────────┬───────────┘
          │ Bearer Passport          │ Cookie / Bearer
          ▼                          ▼
┌──────────────────── Auth_Wayo (Laravel Passport) ────────────────────┐
│  Identité, OAuth Google/Apple, refresh /oauth/token, device gate,    │
│  passkeys (web), connected accounts (web), internal/* pour Wayo-ads  │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │ introspection Bearer + sync profil
                                   ▼
┌────────────────────────── Wayo-ads (Next.js API) ────────────────────┐
│  Campagnes, wallets, Stripe, tracking, matching AI campagne, admin,  │
│  pont chat (/api/chat/token), YouTube OAuth (mobile-complete),       │
│  notifications FCM, invoices, business profiles                      │
└──────────────┬───────────────────────────────┬───────────────────────┘
               │ X-Internal-Secret             │ Stripe webhooks
               ▼                               ▼
        chat-service (Reverb)            Stripe / Connect
```

### Responsabilités

| Service | Autorité | Ne doit pas |
|---------|----------|-------------|
| **Auth_Wayo** | Identité, tokens OAuth2, device approval gate, passkeys/web handoff | Métier campagnes / wallets |
| **Wayo-ads** | Métier Ads, finance, RBAC app, YouTube tokens chiffrés, pont chat | Stocker client secrets OAuth Google dans le mobile |
| **chat-service** | Conversations, messages, unread, broadcasting | Auth identité Ads (reçoit token via internal) |
| **Wayo-ads-mobile** | UX native, Bearer clients, secure storage | Contourner RBAC, créditer wallet client-side |

### Rôles (`UserRole` Wayo-ads)

`USER` | `ADVERTISER` | `CREATOR` | `SUPERADMIN`  
Guards : `requireAuth` / `requireRole` / `requireSuperAdmin` — **deny by default côté serveur**.

### Machine d’états campagne (vérifiée Prisma + API)

```
DRAFT ──PATCH status:ACTIVE──► ACTIVE ◄──► PAUSED
         (lock budget)            │
                                  ├──► CANCELLED (release budget)
                                  └──► COMPLETED (expiration / reconcile)
UNDER_REVIEW : système / hors Zod mobile create-update
ARCHIVED : n’existe pas
```

Pas d’endpoints dédiés pause/resume/publish — uniquement `PATCH /api/campaigns/[id] { status }`.

---

## 2. Inventaire routes web IN SCOPE (Ads Go)

### Annonceur

| Route web | Fonction |
|-----------|----------|
| `/dashboard/advertiser` | Home KPIs |
| `/advertiser/campaigns/new` | Création wizard |
| `/advertiser/campaigns/[id]/edit` | Édition |
| `/campaigns?mine=true` | Liste owner |
| `/advertiser/campaigns/[id]/financial-health` | Pacing / health |
| `/campaigns/[id]` (+ analytics) | Détail + visitor insights |
| `/advertiser/video-reviews` | Review posts |
| `/advertiser/creators` | Annuaire |
| `/advertiser/wallet` | Dépôts / saved cards |
| `/advertiser/invoices` | Factures |
| `/advertiser/business` | Business profile |
| `/advertiser/messages` | Chat |

### Créateur ads

| Route web | Fonction |
|-----------|----------|
| `/dashboard/creator` | Pipeline ads |
| `/campaigns`, `/campaigns/[id]` | Browse / apply |
| `/creator/analytics` | Analytics créateur |
| `/creator/wallet` | Connect + withdraw |
| `/creator/payouts` | Docs payouts |
| `/creator/business` | Business profile |
| `/settings/youtube` | OAuth YouTube |
| `/creator/messages` | Chat |

**Exclu (desktop AI / Studio) :** `/creator/content-spy`, `/content-lab/*`, `/creator/title-thumbnail`, CTR/retention/viral/*, `/creator/tokens` (économie IA Studio).

### Compte / partagé

`/settings` (profile, security, notifications, privacy/export, danger), `/notifications`, `/auth/*` (device-approval, banned, verify).

### Superadmin

`/dashboard/admin`, users, bans, withdrawals, announcements, AI usage, ledger, tax-rates, stripe/platform/email/business settings, token-packages, token-purchases, payment-audits, financial-documents, broadcast notifications, emails, audit-log, click-pipeline, creator-velocity, youtube-monitoring, recent-activity, health, jobs, messages.

---

## 3. Inventaire mobile actuel (Wayo-ads-mobile)

### Routes go_router (extrait)

Auth/legal : `/splash`, `/login`, `/signup/*`, `/forgot-password/*`, `/onboarding/*`, `/privacy|terms|cookie-policy`  
Shell : `/dashboard`, `/campaigns`, `/campaigns/:id`, `/wallet`, `/invoices`, `/chat`  
Créateur : `/creator/campaigns/:id`, `.../application`  
Adv : `/advertiser/video-reviews`  
Compte : `/settings/profile|security|trusted-devices|delete-account`, `/notifications`  
Chat : `/chat/thread/:conversationId`  
Admin : `/superadmin`, `?tab=`, ai-usage, ledger, banned-users, browse-campaigns, tax-rates(+subdivisions), campaigns/:id  

**Hors go_router :** `BusinessInfoScreen` (Navigator.push).

### Clients réseau

- `dioProvider` → Auth_Wayo (`AUTH_WAYO_BASE_URL`)
- `wayoAdsDioProvider` → Wayo-ads (`WAYO_ADS_API_BASE_URL`)
- Chat Dio dédié → chat-service (token via `/api/chat/token`)

---

## 4. Matrice de parité (synthèse)

Légende état : `COMPLETE` | `PARTIAL` | `STUB` | `ABSENT` | `BLOCKED_API` | `OUT_OF_SCOPE`

| Domaine | Fonction web | Route web | Endpoint principal | État mobile | Écart | Priorité | Effort | Dépendance | Risque sécurité | Tests |
|---------|--------------|-----------|-------------------|-------------|-------|----------|--------|------------|-----------------|-------|
| Auth | Login/signup/OAuth | `/auth/signin` | Auth `/api/auth/*` + `/oauth/token` | COMPLETE | — | — | — | Auth_Wayo | Moyen | Partiel |
| Auth | Device approval | `/auth/device-approval` | Ads `/api/auth/device-approval` + Auth gate | PARTIAL | UX gate login 403 ; flow approve web-centric | P2 | M | Auth_Wayo | Élevé | À écrire |
| Auth | Passkeys | Settings security | Ads handoff → Auth web | ABSENT | Pas d’API JSON passkey | P2 | L | Auth_Wayo web/native | Élevé | À écrire |
| Auth | Connected accounts | Settings | handoff Auth | ABSENT | Link/unlink mobile | P2 | M | Auth_Wayo | Élevé | À écrire |
| Compte | Profile | `/settings?tab=profile` | `/api/user/profile` | COMPLETE | — | — | — | — | Faible | Partiel |
| Compte | Sessions/devices | Settings security | `/api/user/sessions`, `/devices` | COMPLETE | — | — | — | — | Moyen | Partiel |
| Compte | Delete account | Danger | `/api/user/delete-account` | COMPLETE | — | — | — | — | Moyen | — |
| Compte | Export data | Privacy | `/api/user/export-data` | ABSENT | Pas d’UI/API client | P2 | M | — | Élevé (IDOR) | À écrire |
| Compte | Notif preferences | Settings | `/api/notifications/preferences` | PARTIAL | Toggle push basique | P2 | S | — | Faible | — |
| Adv | Dashboard | `/dashboard/advertiser` | `/api/advertiser/dashboard-summary` | COMPLETE | — | — | — | — | Faible | Partiel |
| Adv | Create campaign | `/campaigns/new` | `POST /api/campaigns` | ABSENT | Wizard + assets + geo | P0 | XL | Bearer OK | Élevé (finance) | À écrire |
| Adv | Edit campaign | `/campaigns/[id]/edit` | `PATCH /api/campaigns/[id]` | ABSENT | Budget lock ACTIVE/PAUSED | P0 | L | — | Élevé | À écrire |
| Adv | Pause/resume/cancel | List actions | `PATCH status` | ABSENT | Pas de machine d’états UI | P0 | M | — | Moyen | À écrire |
| Adv | Archive | — | — | OUT_OF_SCOPE | Statut inexistant | — | — | — | — | — |
| Adv | Geo targeting | Editor | champs geo create/PATCH | ABSENT | Inclus dans wizard | P0 | L | — | Moyen (GPS) | À écrire |
| Adv | Upload logo | Editor | `POST /api/campaigns/upload-logo` | ABSENT | Base64 2MB PNG/JPEG/WEBP ; `requireRole` sans request = gap Bearer | P0 | M | **Fix auth Bearer** | Élevé | À écrire |
| Adv | Brand assets URLs | Editor | `assetsUrl` HTTPS allowlist | ABSENT | Pas d’upload fichier guidelines | P0 | S | — | Moyen | — |
| Adv | Campaign analytics | Detail | `GET .../analytics` | ABSENT | Bearer OK | P0 | L | — | Moyen (PII agg) | À écrire |
| Adv | Owner live SSE | Detail | `.../owner-live` | BLOCKED_API | Session-only | P0 | M | **Bearer fix** | Moyen | — |
| Adv | Financial health | `/.../financial-health` | `GET .../financial-summary` | BLOCKED_API | Session-only | P0 | M | **Bearer fix** | Élevé | À écrire |
| Adv | Applications review | Detail | approve/reject | COMPLETE | — | — | — | — | Moyen | — |
| Adv | AI match score | Application | `.../ai-match-score` (+refresh) | ABSENT | Matching Ads (pas Spy) | P1 | M | — | Moyen | À écrire |
| Adv | Creator YT insights | Application | `.../insights` (+refresh) | ABSENT | Quotas | P1 | M | — | Moyen | — |
| Adv | Video reviews | `/advertiser/video-reviews` | `/api/advertiser/videos` | COMPLETE | — | — | — | — | Moyen | — |
| Adv | Creators directory | `/advertiser/creators` | `GET /api/advertiser/creators` | ABSENT | Privacy filters | P1 | M | — | Moyen | À écrire |
| Adv | Wallet deposits | `/advertiser/wallet` | deposit-intent/confirm | COMPLETE | PaymentSheet + Apple/Google Pay | — | — | Stripe | Élevé | Partiel |
| Adv | Saved cards | AddFundsPanel | `/api/wallet/saved-cards` | ABSENT | API existe | P1 | M | Stripe | Élevé | À écrire |
| Adv | Invoices | `/advertiser/invoices` | invoices PDF | COMPLETE | — | — | — | — | Moyen | — |
| Adv | Business profile | `/advertiser/business` | business-profile | PARTIAL | Navigator only, pas go_router | P1 | S | — | Faible | — |
| Adv | Chat from campaign | Messages | `.../advertiser-conversation` | PARTIAL | À vérifier wiring | P1 | S | chat | Élevé (IDOR) | À écrire |
| Creator | Dashboard | `/dashboard/creator` | dashboard-summary | COMPLETE | — | — | — | — | Faible | — |
| Creator | Browse/apply | `/campaigns` | GET/POST apply | COMPLETE | — | — | — | — | Moyen | — |
| Creator | Submit post | Detail | submit-post | COMPLETE | — | — | — | — | Moyen | — |
| Creator | Tracking links | Detail | links | COMPLETE | — | — | — | — | Moyen | — |
| Creator | YouTube OAuth | `/settings/youtube` | connect + mobile-complete | STUB | **Web-only launchUrl** | P0 | L | Studio pattern | Élevé | À écrire |
| Creator | Analytics page | `/creator/analytics` | `GET /api/creator/analytics` | ABSENT | Dashboard KPIs ≠ page analytics | P0 | M | — | Faible | À écrire |
| Creator | Trust score | Dashboard/analytics | `GET /api/creator/trust-score` | ABSENT | Ne pas exposer règles fraude | P0 | S | — | Élevé | À écrire |
| Creator | Wallet/Connect | `/creator/wallet` | stripe-connect, withdraw | COMPLETE | — | — | — | — | Élevé | Partiel |
| Creator | Payouts/invoices | `/creator/payouts` | invoices role-aware | COMPLETE | — | — | — | — | Moyen | — |
| Chat | Inbox/thread | Messages | chat-service v1 + token | COMPLETE | — | — | — | chat | Moyen | Partiel |
| Chat | Pin/archive | Inbox swipe + filter | chat-service pin/archive | DONE | Wired 2026-08-05 | — | — | chat-service | — | — |
| Chat | Unread/read | — | unread-count, read | COMPLETE | Backend OK | — | — | — | Faible | Partiel |
| Notif | Center | `/notifications` | `/api/notifications` | COMPLETE | — | — | — | FCM | Faible | Partiel |
| Admin | Users/bans | admin/users | admin/users, app-bans | COMPLETE | — | — | — | — | Élevé | — |
| Admin | Withdrawals | admin/withdrawals | admin/withdrawals | COMPLETE | — | — | — | — | Élevé | — |
| Admin | Announcements | admin/announcements | admin/announcements | COMPLETE | — | — | — | — | Moyen | — |
| Admin | AI usage | admin/ai-usage | admin/ai/usage | COMPLETE | — | — | — | — | Moyen | — |
| Admin | Ledger | admin ledger | admin/ledger | COMPLETE | — | — | — | — | Élevé | — |
| Admin | Tax rates | tax-rates | admin/tax-rates | COMPLETE | — | — | — | — | Moyen | — |
| Admin | Browse campaigns | — | campaigns GET | COMPLETE | Read-only | — | — | — | Faible | — |
| Admin | Platform settings | admin/settings/platform | admin/platform-settings | ABSENT | Secrets/branding | P2 | L | Step-up | Critique | À écrire |
| Admin | Stripe settings | admin/settings/stripe | admin/stripe-settings | ABSENT | **Write-only secrets** | P2 | L | Step-up MFA | Critique | À écrire |
| Admin | Email/SMTP | admin/settings/email | admin/email-settings | ABSENT | Write-only password | P2 | M | Step-up | Critique | À écrire |
| Admin | Company legal | admin/settings/business | company-business-info | ABSENT | — | P2 | M | — | Moyen | — |
| Admin | Token packages | settings/token-packages | admin/token-packages | ABSENT | Stripe sync | P2 | M | — | Élevé | — |
| Admin | Token purchases log | token-purchases | admin/token-purchases | ABSENT | — | P2 | S | — | Moyen | — |
| Admin | Payment audits | payment-audits | admin/payment-audits | ABSENT | Idempotence | P2 | L | — | Critique | À écrire |
| Admin | Financial docs | financial-documents | admin/invoices, statements | ABSENT | URLs signées | P2 | M | Step-up | Élevé | — |
| Admin | Broadcast notif | admin/notifications | admin/notifications/broadcast | ABSENT | — | P2 | M | Rate limit | Élevé | — |
| Admin | Email templates | admin/emails | admin/emails | ABSENT | XSS templates | P2 | M | — | Élevé | — |
| Admin | Audit log | audit-log | admin/audit-log | ABSENT | Read-only | P2 | M | — | Moyen | — |
| Admin | Click pipeline | click-pipeline | admin/click-pipeline | ABSENT | No mutate billed events | P2 | M | — | Élevé | — |
| Admin | Creator velocity | creator-velocity | admin/creator-velocity | ABSENT | Aggregates | P2 | M | — | Moyen | — |
| Admin | YT monitoring | youtube-monitoring | jobs/refresh | ABSENT | Quota | P2 | M | — | Moyen | — |
| Admin | Recent activity | recent-activity | admin/recent-activity | ABSENT | — | P2 | S | — | Faible | — |
| Admin | Health probes | admin health | admin/health | ABSENT | No secrets in payload | P2 | S | — | Moyen | — |
| Admin | Manual jobs | — | admin/jobs/* | ABSENT | Idempotency + lock | P2 | M | — | Critique | À écrire |
| Admin | Admin chat | admin/messages | chat | PARTIAL | Deep-link possible | P2 | S | — | Moyen | — |
| Studio | Content Lab/Spy | desktop AI | `/api/creator/ai/*` | OUT_OF_SCOPE | Ne pas importer | — | — | — | — | — |
| Web | Marketing/PWA/blog | public | — | OUT_OF_SCOPE | — | — | — | — | — | — |

---

## 5. Endpoints manquants ou inadaptés (action backend)

| Endpoint | Problème | Action Vague |
|----------|----------|--------------|
| `GET /api/advertiser/campaigns/[id]/financial-summary` | `getServerSession` only | V1 — accepter Bearer via `getCurrentUser(request)` |
| `GET /api/campaigns/[id]/owner-live` | Session-only SSE | V1 — Bearer ou remplacer par polling Bearer |
| `POST /api/campaigns/upload-logo` | `requireRole('ADVERTISER')` **sans** `request` | V1 — passer `request` pour Bearer |
| `POST /api/campaigns/[id]/reconcile-expiration` | `getCurrentUser()` sans request | V1 — aligner Bearer |
| Chat pin/archive | **N’existent pas** | V3 — ajouter routes chat-service + colonnes si besoin |
| Passkeys / connected accounts | Handoff web only | V4 — native WebAuthn **ou** ASWebAuthenticationSession handoff sécurisé |
| Idempotency-Key campagnes | Absent | V1 — header optionnel create/status |

Endpoints **déjà prêts** (Bearer) pour P0/P1 mobile :  
`POST/PATCH /api/campaigns`, `GET .../analytics`, `GET /api/creator/analytics`, `trust-score`, `youtube/connect?mobile=1`, `youtube/mobile-complete`, `advertiser/creators`, `ai-match-score`, `wallet/saved-cards`, `user/export-data`, admin/*.

---

## 6. Décisions produit non bloquantes (documentées)

| Sujet | Options | Choix retenu |
|-------|---------|--------------|
| Brand guidelines fichiers | Upload multipart vs URLs allowlist web | **URLs allowlist** (parité web réelle) + logo upload séparé |
| Archive campagne | Inventer ARCHIVED | **Non** — COMPLETED/CANCELLED seulement |
| Pin/archive chat | UI-only vs API | **API chat-service obligatoire** avant UI |
| Admin Stripe secrets sur mobile | Full parity vs status-only | **Status + write-only** ; jamais lecture de secrets |
| Passkeys | Native vs handoff navigateur | Préférer **native** si Auth_Wayo expose options JSON ; sinon handoff ASWebAuth temporaire |
| SSE analytics | Porter SSE vs polling | **Polling borné** tant que SSE n’est pas Bearer-safe |

---

## 7. Références code

- Campagne Prisma : `Wayo-ads/prisma/schema.prisma` (~608–680, enums ~1326+)
- Create/update : `Wayo-ads/src/app/api/campaigns/route.ts`, `[id]/route.ts`
- Mobile routes : `Wayo-ads-mobile/lib/router/app_router.dart`
- YouTube web-only : `Wayo-ads-mobile/lib/core/network/wayo_ads_public_url.dart`
- Chat pin/archive : wired (`chat_inbox_screen.dart` swipe + Inbox/Archived filter)
- Chat routes : `chat-service/routes/api.php` (pas de pin/archive)
