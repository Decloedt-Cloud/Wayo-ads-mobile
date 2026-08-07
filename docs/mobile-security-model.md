# Wayo Ads Go — Modèle de sécurité (Vague 0)

**Date :** 2026-08-03  
**Audience :** Mobile + Backend + Security review

---

## 1. Trust boundaries

| Zone | Confiance | Contrôles |
|------|-----------|-----------|
| Flutter UI | Non trusted | Validation UX seulement |
| Mobile secure storage | Semi-trusted device | Keychain/Keystore ; jamais SharedPreferences pour tokens |
| Wayo-ads API | Trusted métier | AuthN Bearer + AuthZ RBAC + ownership |
| Auth_Wayo | Trusted identité | Passport tokens, device gate, internal IP+app key |
| chat-service | Trusted messaging | Sanctum via token minté par Wayo-ads (secret serveur) |
| Stripe | Trusted PSP | Webhooks signés = source de vérité wallet |

**Règle d’or :** le mobile ne décide jamais d’un crédit wallet, d’un budget, d’un CPM effectif, d’un rôle, ou d’une transition de statut non autorisée.

---

## 2. Authentification actuelle

### Flux mobile observé

1. Login Auth_Wayo (`POST /api/auth/login|google|apple`) → access + refresh.
2. Refresh via Passport `POST /oauth/token` (`grant_type=refresh_token`) — **pas** `/api/auth/refresh`.
3. Appels métier : `Authorization: Bearer` sur Wayo-ads (`getCurrentUser(request)`).
4. CSRF web **skippé** si Bearer présent (`api-security.ts`) — correct pour mobile.
5. Chat : `GET/POST /api/chat/token` (Wayo-ads) → Sanctum token chat-service.

### Stockage

- Tokens : `flutter_secure_storage` (tests `secure_token_storage_test.dart`).
- Scrubber Sentry/logs : redaction tokens/cookies/passwords/`x-app-key` (`SECURITY.md`).

### Risques auth actuels

| Risque | Sévérité | Preuve | Mitigation prévue |
|--------|----------|--------|-------------------|
| `AUTH_OAUTH_CLIENT_SECRET` dans dart-defines | Critique si leak binaire | Config mobile | Évaluer PKCE public client / secret non embarqué ; rotation |
| `WAYO_ADS_APP_KEY` embarqué | Élevé | dart-defines | Restreindre scopes serveur ; pin device ; rate limit |
| Cert pinning | — | Non utilisé (décision produit) — TLS plateforme uniquement |
| Device approval partiel | Élevé | Gate 403 login | Porter flow approve/deny complet (Vague 4) |
| Passkeys/web handoff only | Moyen | Auth routes web | Native ou ASWebAuth (Vague 4) |
| TODO token expiration formats | Moyen | auth_response.dart | Aligner Auth_Wayo (Vague 4/6) |

---

## 3. Autorisation (RBAC)

| Rôle | Capacités Ads |
|------|----------------|
| ADVERTISER | Campagnes owner, wallet dépôt, video reviews, creators dir |
| CREATOR | Apply, submit, wallet withdraw/Connect, analytics, trust, YouTube |
| SUPERADMIN | Override + `/api/admin/*` |
| USER | Pré-rôle ; onboarding |

**IDOR à tester systématiquement (Vague 6–7) :** campagne B, conversation B, facture B, export B, insights créateur hors relation, admin sans permission.

---

## 4. Gaps auth Bearer (bloquants P0)

Ces handlers **ne passent pas** `request` à l’auth et cassent le mobile :

1. `GET /api/advertiser/campaigns/[id]/financial-summary` — session only  
2. `GET /api/campaigns/[id]/owner-live` — session only  
3. `POST /api/campaigns/upload-logo` — `requireRole('ADVERTISER')` sans request  
4. `POST /api/campaigns/[id]/reconcile-expiration` — `getCurrentUser()` sans request  

**Politique :** toute route consommée par Ads Go doit utiliser `getCurrentUser(request)` / `requireRole(..., request)`.

---

## 5. Finance & Stripe

### Règles absolues (déjà partiellement respectées côté dépôt mobile)

- Pas de PAN/CVC dans l’app (PaymentSheet).
- Pas de clé secrète Stripe dans le binaire.
- Crédit wallet uniquement après webhook + reconcile serveur.
- Montants affichés = strings/decimal serveur ; Flutter ne recalcule pas l’autorité.

### Saved cards (à venir P1)

- Utiliser `/api/wallet/saved-cards` existant.
- Afficher last4/brand seulement.
- Suppression = API serveur ; jamais local-only.

### Admin Stripe settings (P2)

- Lecture : mode, health, publishable indicators — **jamais** secret key.
- Écriture : write-only + step-up MFA + audit sans valeur secrète.

---

## 6. YouTube OAuth (P0)

Pattern cible (déjà côté Wayo-ads + Creator Studio) :

- `GET /api/creator/youtube/connect?mobile=1` → auth URL + PKCE/state  
- Navigateur système (Custom Tabs / ASWebAuthenticationSession)  
- `POST /api/creator/youtube/mobile-complete` avec code + state  
- Refresh token **chiffré serveur** ; jamais dans le mobile  

Interdit : WebView embarquée pour credentials Google ; client secret Google dans l’app.

Risque account-linking hijack : vérifier ownership serveur (déjà attendu sur mobile-complete).

---

## 7. Chat

| Contrôle | État |
|----------|------|
| Token minté serveur (secret interne) | OK |
| Sanctum sur v1 | OK |
| Unread / read | OK |
| Pin / archive | **Absent backend** — ne pas fake côté client |
| Media download | Via pont Wayo-ads ; URLs non permanentes |
| IDOR conversation | À retester + advertiser-conversation |

---

## 8. Uploads

Logo campagne :

- Allowlist MIME : png/jpeg/webp  
- Max 2 MB  
- Nom généré serveur `logo-{ts}.ext`  
- Path sous `/uploads/campaign-logos/`  
- Pas d’upload brand guidelines fichier — URLs HTTPS allowlist (`creative-assets-url.ts`)

À ajouter côté serveur si manquant : vérification magic bytes (pas seulement Content-Type client).

---

## 9. Step-up authentication (P2 admin / compte)

Actions exigeant reauth récente (± MFA) :

- Stripe/SMTP/platform fee changes  
- Passkey delete, unlink dernier provider  
- Export data download  
- Financial docs ZIP  
- Manual jobs, broadcast, payment reconcile  
- Device revoke remote  

Biométrie locale = confort UX, **jamais** autorité unique.

---

## 10. Confidentialité & observabilité

- Analytics agrégées + seuils ; pas de datasets bruts visiteurs  
- Geo device : consentement OS, pas de background tracking  
- Trust score : facteurs publics seulement ; pas de seuils antifraude  
- Sentry : scrubber actif ; désactiver verbose Dio en release  
- Correlation ID : à généraliser Vague 6  

---

## 11. Threat model résumé (STRIDE light)

| Menace | Exemple | Contrôle |
|--------|---------|----------|
| Spoofing | Fake Bearer | Passport introspection + short TTL |
| Tampering | amountCents client | Serveur ignore / revalide |
| Repudiation | Admin job | Audit log |
| Info disclosure | Secret in log | Scrubber + write-only settings |
| DoS | Upload/spam create | Rate limits existants + idempotency |
| Elevation | Creator → admin API | requireSuperAdmin |

---

## 12. Checklist sécurité par feature livrée

- [ ] AuthN Bearer  
- [ ] AuthZ rôle + ownership  
- [ ] Validation Zod/serveur  
- [ ] Rate limit  
- [ ] Pas de secret dans réponse  
- [ ] Audit si sensible  
- [ ] Tests positifs + IDOR négatifs  
- [ ] Pas de stub « soon »  
