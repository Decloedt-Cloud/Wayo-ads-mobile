import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notifications_page_result.dart';
import '../providers/dashboard_state_providers.dart';

enum NotificationsListTab { all, important, archived }

final notificationsListTabProvider = StateProvider<NotificationsListTab>(
  (_) => NotificationsListTab.all,
);

final notificationsSearchQueryProvider = StateProvider<String>((_) => '');

final notificationsTypeFilterProvider = StateProvider<String?>((_) => null);

final notificationsPriorityFilterProvider = StateProvider<String?>((_) => null);

@immutable
class NotificationsFeedState {
  const NotificationsFeedState({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<NotificationItem> items;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore =>
      nextCursor != null && nextCursor!.isNotEmpty && !isLoadingMore;

  NotificationsFeedState copyWith({
    List<NotificationItem>? items,
    String? nextCursor,
    bool? isLoadingMore,
    bool clearCursor = false,
  }) => NotificationsFeedState(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class NotificationsFeedController extends AutoDisposeAsyncNotifier<NotificationsFeedState> {
  @override
  Future<NotificationsFeedState> build() async {
    ref.watch(notificationsListTabProvider);
    ref.watch(notificationsSearchQueryProvider);
    ref.watch(notificationsTypeFilterProvider);
    ref.watch(notificationsPriorityFilterProvider);
    return _loadFirstPage();
  }

  Future<NotificationsFeedState> _loadFirstPage() async {
    final page = await _fetchPage(cursor: null);
    return NotificationsFeedState(
      items: page.notifications,
      nextCursor: page.nextCursor,
    );
  }

  Future<NotificationsPageResult> _fetchPage({required String? cursor}) {
    final tab = ref.read(notificationsListTabProvider);
    final repo = ref.read(notificationsRepositoryProvider);
    return repo.fetchPage(
      limit: 20,
      cursor: cursor,
      status: tab == NotificationsListTab.archived ? 'ARCHIVED' : null,
      importantOnly: tab == NotificationsListTab.important,
      type: ref.read(notificationsTypeFilterProvider),
      priority: ref.read(notificationsPriorityFilterProvider),
      search: ref.read(notificationsSearchQueryProvider),
    );
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = const AsyncLoading<NotificationsFeedState>();
    try {
      final next = await _loadFirstPage();
      state = AsyncData(next);
    } catch (e, st) {
      state = AsyncError(e, st);
      if (previous != null) {
        state = AsyncData(previous);
      }
    }
    ref.invalidate(notificationsUnreadCountsProvider);
    ref.invalidate(notificationsListProvider);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _fetchPage(cursor: current.nextCursor);
      state = AsyncData(
        NotificationsFeedState(
          items: [...current.items, ...page.notifications],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (e, st) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      state = AsyncError(e, st);
    }
  }
}

final notificationsFeedProvider =
    AutoDisposeAsyncNotifierProvider<NotificationsFeedController,
        NotificationsFeedState>(NotificationsFeedController.new);

void invalidateAllNotifications(WidgetRef ref) {
  ref.invalidate(notificationsFeedProvider);
  ref.invalidate(notificationsListProvider);
  ref.invalidate(notificationsUnreadCountsProvider);
  ref.invalidate(dashboardStreamProvider);
}
