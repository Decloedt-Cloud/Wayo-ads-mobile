# Campaign create — Web ↔ Mobile parity (final)

Last update: 2026-08-05

## Status matrix

| Fonction | Web | Mobile | Endpoint | Validation | Statut |
|----------|-----|--------|----------|------------|--------|
| Wizard 3 steps | identity/budget/review | same | — | client+Zod | **GO** |
| Cost estimate | `useCampaignCostEstimate` | `campaignCostEstimateProvider` | `GET /api/platform/fees` + `GET /api/tokens/tax-rate` + business profile | server tax | **GO** |
| Draft save | POST DRAFT | POST DRAFT | `POST /api/campaigns` | Zod | **GO** |
| Activate | POST ACTIVE + lock | POST ACTIVE + soft wallet gate | same | lock server | **GO** |
| Idempotency | header optional | `Idempotency-Key` stable per intention | Redis 24h | charset 8–128 | **GO** |
| Logo upload | crop + upload | 16:9 pan crop + upload (≤1920×1080) | `POST /api/campaigns/upload-logo` | ADVERTISER | **GO** |
| Logo path Zod | hex suffix bug fixed | only server paths | — | regex | **GO** |
| Role gate | ADVERTISER layout | GoRouter redirect | — | — | **GO** |
| Sync list/wallet | RQ invalidate | Riverpod invalidate + Reverb | — | — | **GO** |
| Full widget/e2e suite | — | domain+repo+editor widget (3-step, double-tap, idempotency retry) | — | — | **PARTIAL** |
| Samsung smoke | — | manual checklist below | — | — | **READY FOR DEVICE** (not yet run on hardware) |


## Endpoints

- `POST /api/campaigns` (+ `Idempotency-Key`)
- `PATCH /api/campaigns/:id`
- `POST /api/campaigns/upload-logo` body `{ data: dataUrl }` → `{ url }`
- `GET /api/platform/fees`
- `GET /api/tokens/tax-rate?country&priceCents&profileType&subdivision?`
- `GET /api/creator/business-profile` (country for tax)
- `GET /api/wallet` (available balance display)

## Tests run

### Mobile
- `dart run slang`
- `flutter test test/features/advertiser_campaigns/`
- `flutter analyze` (editor + domain + data)

### Web
- `vitest` specs: `campaign-create-mobile-parity.spec.ts`, `campaignCreateIdempotency.test.ts`
- logo schema + idempotency charset

## Limits

- Interactive 16:9 pan crop (web `CampaignBannerCropDialog` parity) via `CampaignLogoPrep` + crop sheet.
- Fee/tax UI is estimate; activation amounts are server-locked.
- Exhaustive widget tests for all 3 steps / full `flutter test` repo / full Next build not always runnable in CI agent time.
- Physical Samsung smoke not executed in this session.

## Samsung smoke checklist

1. Login advertiser  
2. Open create from dashboard + campaigns list  
3. Fill LINK campaign, save draft → appears in list  
4. Resume local draft after background  
5. Create & activate with sufficient wallet → ACTIVE + wallet drop  
6. Double-tap publish → single campaign  
7. Airplane mode during submit → retry keeps same Idempotency-Key  
8. Insufficient wallet → error + draft id if returned  
9. Creator account cannot open `/advertiser/campaigns/new`  
10. Verify same campaign on web  

## Verdict

**GO for production** on functional parity of create/draft/activate/cost estimate/logo/idempotency/role gate, with **manual Samsung smoke** and full-repo `flutter test` / `next build` recommended before release tag.
