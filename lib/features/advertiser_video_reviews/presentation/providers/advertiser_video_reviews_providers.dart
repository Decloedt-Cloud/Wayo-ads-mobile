import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/advertiser_video_reviews_repository.dart';
import '../../domain/advertiser_submitted_video.dart';

typedef AdvertiserVideoReviewsQuery = ({
  AdvertiserVideoReviewFilter filter,
  int page,
});

/// Dashboard summary counts (single lightweight request).
final advertiserVideoReviewCountsProvider =
    FutureProvider.autoDispose<AdvertiserVideoStatusCounts>((ref) async {
      return ref
          .read(advertiserVideoReviewsRepositoryProvider)
          .loadStatusCounts();
    });

final advertiserVideoReviewFilterProvider =
    StateProvider<AdvertiserVideoReviewFilter>(
      (ref) => AdvertiserVideoReviewFilter.pending,
    );

final advertiserVideoReviewsPageProvider = StateProvider<int>((ref) => 1);

final advertiserVideoReviewsProvider = FutureProvider.autoDispose
    .family<AdvertiserVideosPageResult, AdvertiserVideoReviewsQuery>((
      ref,
      query,
    ) async {
      try {
        return await ref
            .read(advertiserVideoReviewsRepositoryProvider)
            .loadVideos(
              status: query.filter,
              page: query.page,
            );
      } catch (e, st) {
        Error.throwWithStackTrace(
          AdvertiserVideoReviewsRepository.mapError(e),
          st,
        );
      }
    });

/// Reverb invalidation + foreground polling (uses [Ref], not [WidgetRef]).
void invalidateAdvertiserVideoReviewsProviders(Ref ref) {
  ref.invalidate(advertiserVideoReviewCountsProvider);
  ref.invalidate(advertiserVideoReviewsProvider);
}

void invalidateAdvertiserVideoReviews(WidgetRef ref) {
  ref.invalidate(advertiserVideoReviewCountsProvider);
  ref.invalidate(advertiserVideoReviewsProvider);
}
