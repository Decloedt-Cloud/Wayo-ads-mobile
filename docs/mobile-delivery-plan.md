# Wayo Ads Go — Plan de livraison par vagues

**Date :** 2026-08-03  
**Principe :** vagues indépendantes ; pas de commit/push/deploy sans autorisation ; Creator Studio AI exclu.

---

## Vue d’ensemble

| Vague | Objectif | Dépendances | Risque |
|-------|---------|-------------|--------|
| **0** | Audit + docs | — | — |
| **1** | P0 Annonceur | Fix Bearer financial/upload | Finance / uploads |
| **2** | P0 Créateur | YouTube mobile-complete existant | OAuth linking |
| **3** | P1 Partagé | chat-service pin/archive | IDOR chat |
| **4** | P2 Compte | Auth_Wayo handoff/native | Account takeover |
| **5** | P2 Superadmin | Step-up | Secrets admin |
| **6** | Hardening | Features stables | Pinning / a11y |
| **7** | Tests + rapport | Tout | — |

---

## Vague 0 — Audit (cette livraison)

**Livrables :**

- [x] `docs/mobile-parity-audit.md`
- [x] `docs/mobile-parity-audit.json`
- [x] `docs/mobile-security-model.md`
- [x] `docs/mobile-api-contracts.md`
- [x] `docs/mobile-delivery-plan.md`

**Exit criteria :** matrice exhaustive + gaps Bearer + plan priorisé. **ATTEINT.**

---

## Vague 1 — P0 Annonceur

### Backend (Wayo-ads) — d’abord

1. ~~Bearer sur `financial-summary`, `upload-logo`, `reconcile-expiration`, `owner-live`.~~ **FAIT (2026-08-03)** + magic-bytes logo.  
2. ~~`Idempotency-Key` sur `POST /api/campaigns`~~ **FAIT** (Redis + mémoire, TTL 24h). PATCH status : non (optionnel, reporté).  
3. Tests API auth négatifs (Bearer advertiser A ≠ campagne B) — partiel (unit `normalizeIdempotencyKey`).

### Mobile

1. ~~Feature `campaign_editor` wizard~~ **FAIT** (6 steps + publish confirm).  
2. ~~Draft local~~ **FAIT** (SharedPreferences) + create `status:DRAFT` / publish.  
3. ~~Edit + pause/resume/publish/cancel~~ **FAIT** (`CampaignOwnerActionsBar` sur détail).  
4. ~~Upload logo + assetsUrl allowlist~~ **FAIT**.  
5. ~~Écrans analytics + financial health~~ **FAIT**.  
6. ~~Routes go_router~~ **FAIT**.  
7. ~~i18n FR/EN/AR~~ **FAIT** (`create` / `actions` / `insights`).  
8. ~~Tests unit domain~~ **FAIT** (`campaign_editor_domain_test.dart`). Widget wizard steps : reporté Vague 6.

**DoD Vague 1 :** créer → publier → pause → resume → analytics → financial health sans stub. **ATTEINT (2026-08-03).**

---

## Vague 2 — P0 Créateur

1. ~~YouTube OAuth in-app~~ **FAIT** (`returnApp=adsgo` + FlutterWebAuth2).  
2. ~~Remplacer gate web-only~~ **FAIT** (CTA → `/settings/youtube`).  
3. ~~Écran `/creator/analytics`~~ **FAIT**.  
4. ~~Trust score UI safe~~ **FAIT** (+ Bearer fix API).  
5. ~~Deep links documentés~~ **FAIT** (`docs/mobile-deeplinks.md`).  
6. ~~Tests~~ **FAIT** (domain + returnApp).

**DoD Vague 2 :** plus aucun CTA « Open on web » pour YouTube connect. **ATTEINT (2026-08-03).**

---

## Vague 3 — P1 Partagé / marketplace

### chat-service

1. ~~Endpoints pin/unpin + archive/unarchive~~ **FAIT** (migration participant `is_pinned` / `is_archived` + flag `CHAT_PIN_ARCHIVE_ENABLED`).  
2. ~~AuthZ participant-only~~ **FAIT**.  
3. ~~Feature flag~~ **FAIT**.

### Mobile + Wayo-ads

1. ~~Retirer `inbox_swipe_soon` ; brancher pin/archive~~ **FAIT**.  
2. ~~Annuaire `/advertiser/creators`~~ **FAIT** (route + dashboard card).  
3. ~~AI match score + YT insights~~ **FAIT** (`ApplicationCreatorInsightsPanel`).  
4. ~~Business profile go_router `/settings/business`~~ **FAIT**.  
5. ~~Conversation depuis campagne + tests IDOR~~ **FAIT**.  
6. ~~Saved cards parity AddFundsPanel~~ **FAIT** (list / pay / delete / refresh).

**DoD :** aucune string « soon » chat ; business deep-linkable. **ATTEINT (2026-08-03).**

---

## Vague 4 — P2 Compte / sécurité

1. Passkeys (native ou handoff sécurisé) + step-up delete.  
2. Connected accounts link/unlink + protection dernier facteur.  
3. Export data (demande → statut → download step-up).  
4. Préférences notifications granulaires (security non désactivable).  
5. Device approval flow complet.

**Décision produit :** si Auth_Wayo n’expose pas d’API JSON passkey, documenter handoff ASWebAuth comme MVP sécurisé.

---

## Vague 5 — P2 Superadmin

Espace admin déjà séparé — étendre :

1. Guards + session courte + step-up pour mutations.  
2. Platform / Stripe (status+write-only) / SMTP / legal.  
3. Token packages + purchases log.  
4. Payment audits, financial docs (signed URL).  
5. Broadcast, email templates (XSS-safe).  
6. Audit log, click pipeline, velocity, YT monitoring, activity, health.  
7. Manual jobs idempotents.  
8. Admin messages wiring.

**DoD :** zéro secret dans réponses/logs ; MFA/step-up sur critiques.

---

## Vague 6 — Hardening

1. Réactiver cert pinning avec rotation.  
2. Obfuscation release, scrubber audit, screenshot mask wallets.  
3. Performance : cancel tokens, pagination audit, pas d’appel YT au mount.  
4. Accessibilité WCAG AA / Semantics / textScale 200%.  
5. Observabilité : correlation ID, latence, crash sans PII.  
6. Play Integrity / App Attest (évaluation).  

---

## Vague 7 — Qualification

1. `flutter analyze` + `flutter test` + builds release.  
2. Tests backend IDOR / finance / OAuth / admin.  
3. Matrice finale vs JSON.  
4. Guides OAuth / App Links / Pay / Passkeys.  
5. Plan déploiement progressif + rollback.  
6. Rapport final (interdit d’affirmer un test non exécuté).

---

## Ordre de déploiement API / mobile

```
1. Déployer fixes Bearer (financial-summary, upload-logo, …)
2. (Vague 3) Déployer chat pin/archive derrière flag
3. Publier app store build consommant les APIs
4. Activer flags admin progressivement
```

Rollback : feature flags off ; anciennes apps restent sur endpoints additifs.

---

## Estimation relative (ingénierie)

| Vague | Effort relatif |
|-------|----------------|
| 0 | S (fait) |
| 1 | XL |
| 2 | L |
| 3 | L–XL |
| 4 | L |
| 5 | XL |
| 6 | M–L |
| 7 | M |

---

## Prochaine action immédiate

**Démarrer Vague 4** : passkeys / connected accounts / export / notif prefs / device approval.
