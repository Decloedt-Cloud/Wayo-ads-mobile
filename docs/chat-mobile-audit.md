# Audit Chat Mobile (Flutter) — Wayo Ads Go

Document de synthèse pour performances, réseau et robustesse du module chat sur **Android / iOS**. Date indicative : snapshot au moment des derniers changements dans `lib/features/chat/`.

---

## 1. Résumé exécutif

| Zone | État | Commentaire |
|------|------|-------------|
| Liste inbox | Virtualisée (`ListView.builder`) | Déjà correct ; optimisations ajoutées : debounce refresh realtime, limite animations d’entrée, `RepaintBoundary`, `cacheExtent`, `addAutomaticKeepAlives: false`. |
| Fil de discussion | Virtualisé (`SliverList` + segments) | Les bulles sont construites à la demande ; `RepaintBoundary` par bulle pour isoler les repeints. |
| Images | `CachedNetworkImage` + `memCacheWidth/Height` | Avatars inbox / bulles / pièces jointes dimensionnées pour limiter la RAM decode. |
| Temps réel | `ChatRealtimeService` + Riverpod | Canal présence `presence-chat.{appId}` aligné Laravel (éviter `presence-global`). Payloads WS : champ racine `sender` fusionné en `user` pour `message.sent` / `message.edited`. Debounce inbox + coalescence binding. |
| Données | `fetchMessagesPage` (`page`, `per_page`) + tri client | Premier écran : page 1 (`ChatThreadScreen`) ; historique : scroll vers le haut déclenche les pages suivantes ; fusion + dédoublonnage par `id`. |

---

## 2. Architecture Riverpod

- **`chatBootstrapProvider`** — JWT chat Wayo Ads ; `keepAlive`.
- **`chatConversationsProvider`** — liste conversations HTTP ; retries sur 401 avec ré-bootstrap ; `keepAlive`.
- **`chatRealtimeBindingProvider`** — souscription Pusher/Reverb ; dépend bootstrap + liste → éviter invalidations gratuites en boucle.
- **`chatRealtimeServiceProvider`** — `autoDispose` mais `keepAlive` sur l’instance ; dispose explicite au logout (`invalidateChatProviders`).
- **`chatMessagesFamilyProvider`** — prévu pour prefetch ; le fil actuel charge les messages dans **`ChatThreadScreen`** via `_bootstrap` local — à documenter pour éviter double source de vérité.

**Recommandation** : après stabilisation backend, envisager **une seule source** pour les messages du fil (family provider ou notifier) pour simplifier les tests et le cache.

---

## 3. Réseau & latence

- Retry Dio global (`502`/`503`/`504`/timeouts) — évite les faux « hors ligne » courts.
- Conversations / messages : boucles de retry avec backoff léger après 401 (token JWT chat).

**Recommandation** : instrumentation **Sentry** ou logs structurés sur durée `fetchConversations` / `fetchMessages` / `fetchBootstrap` pour corréler avec incidents **502** en production.

---

## 4. Liste inbox — détails techniques

- **`ChatInboxRefreshEvent`** : plusieurs canaux realtime peuvent invalider la liste quasi simultanément → **debounce ~550 ms** avant `invalidate(chatConversationsProvider)` pour réduire les rafales HTTP.
- **Animations** : entrées décalées (`flutter_animate`) limitées aux **premiers indices** (`_maxStaggeredInboxIndices`) pour éviter centaines de timers lors du scroll sur très longues listes.
- **`addAutomaticKeepAlives: false`** : les lignes hors viewport peuvent être démontées plus agressivement → moindre empreinte mémoire ; les images restent en cache disque thanks à `cached_network_image`.
- **`RepaintBoundary`** par ligne : limite la propagation des repeints (typing, pulse, présence).

---

## 5. Fil de discussion

- Segments `_ThreadSegment` : date + index message → **`SliverChildBuilderDelegate`** ne construit que ce qui est visible.
- **`RepaintBoundary`** autour de chaque bulle : scroll et sélection touchent moins tout le viewport.

**Points restants**

- Composer / pièces jointes : garder les uploads **hors isolate principal** si fichiers lourds (actuellement synchrone avec indicateur `_uploading` — acceptable pour MVP).

---

## 6. Accessibilité & motion

- **`MediaQuery.disableAnimationsOf`** respecté sur inbox (animations d’entrée coupées avec « réduire les animations » système).
- Le fil utilise **`reduce`** pour cinématiques bulles — à vérifier systématiquement sur tous les effets `flutter_animate` restants dans les bulles.

---

## 7. Sécurité mobile (rappel)

- TLS pinning release (`CertificatePinning`) — les builds prod doivent rester alignés avec les certificats présentés par **Auth**, **Wayo Ads** et **chat-service**.
- Tokens JWT chat : courte durée ; refresh via Wayo Ads — pas stocker en clair hors secure storage si étendu.

---

## 8. Checklist QA mobile rapide

1. Ouvrir inbox avec **50+** conversations : scroll fluide, pas de freeze au premier rendu.
2. Réduire animations (Android/iOS) : pas d’animations d’entrée inbox agressives.
3. Réception rapide de nombreux événements realtime : **une** vague de refresh liste après debounce (pas N appels `/conversations`).
4. Fil avec **beaucoup de messages** : scroll vers le haut puis retour bas — pas de pic mémoire anormal (profiler DevTools si besoin).
5. Mode avion / reconnexion : message d’erreur ou retry cohérent.

---

## 9. Prochaines étapes suggérées (priorité)

1. ~~**Pagination messages**~~ — livré : `ChatRepository.fetchMessagesPage`, prepend dans `ChatThreadScreen` avec conservation du scroll.
2. ~~**Coalescence `chatRealtimeBindingProvider`**~~ — `scheduleInvalidateChatRealtimeBinding` / `invalidateChatRealtimeBindingImmediate` dans `chat_providers.dart` (overlay reconnect + retry inbox ; invalidation immédiate après création de conversation / logout).
3. **Tests** — métadonnées pagination : `test/features/chat/chat_messages_pagination_test.dart` ; envisager tests widget debounce inbox / fil si besoin.
