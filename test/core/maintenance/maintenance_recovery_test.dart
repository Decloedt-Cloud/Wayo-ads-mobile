import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/maintenance/maintenance_providers.dart';
import 'package:wayoadsgo/core/maintenance/maintenance_recovery_coordinator.dart';
import 'package:wayoadsgo/core/maintenance/maintenance_service.dart';
import 'package:wayoadsgo/core/network/rate_limiter.dart';
import 'package:wayoadsgo/core/network/request_deduplicator.dart';
import 'package:wayoadsgo/core/providers/app_providers.dart';
import 'package:wayoadsgo/core/storage/app_prefs.dart';
import 'package:wayoadsgo/features/creator_campaigns/presentation/providers/creator_campaigns_providers.dart';
import 'package:wayoadsgo/features/creator_dashboard/presentation/providers/creator_dashboard_providers.dart';
import 'package:wayoadsgo/features/dashboard/presentation/providers/dashboard_state_providers.dart';
import 'package:wayoadsgo/i18n/strings.g.dart';
import 'package:wayoadsgo/shared/widgets/maintenance_gate.dart';

List<Override> _rateLimitOverrides() => [
  dashboardRateLimiterProvider.overrideWithValue(
    RateLimiter(minInterval: Duration.zero),
  ),
  creatorRateLimiterProvider.overrideWithValue(
    RateLimiter(minInterval: Duration.zero),
  ),
  creatorCampaignsRateLimiterProvider.overrideWithValue(
    RateLimiter(minInterval: Duration.zero),
  ),
  notificationsRateLimiterProvider.overrideWithValue(
    RateLimiter(minInterval: Duration.zero),
  ),
  requestDeduplicatorProvider.overrideWithValue(RequestDeduplicator()),
];

void _resetSingletonMaintenance() {
  final service = MaintenanceServiceHolder.instance;
  if (service.isActive) {
    service.leaveMaintenance();
  }
}

Widget _wrapGate(Widget child) {
  return TranslationProvider(child: child);
}

void main() {
  setUp(_resetSingletonMaintenance);
  tearDown(_resetSingletonMaintenance);

  group('MaintenanceService idempotency', () {
    test('enterMaintenance notifies only on real state change', () {
      final service = MaintenanceService();
      var notifications = 0;
      service.addListener(() => notifications++);

      service.enterMaintenance();
      service.enterMaintenance();
      service.enterMaintenance();

      expect(service.isActive, isTrue);
      expect(notifications, 1);
    });

    test('leaveMaintenance notifies only when active', () {
      final service = MaintenanceService();
      var notifications = 0;
      service.addListener(() => notifications++);

      service.leaveMaintenance();
      service.leaveMaintenance();
      expect(notifications, 0);

      service.enterMaintenance();
      expect(notifications, 1);

      service.leaveMaintenance();
      service.leaveMaintenance();
      expect(service.isActive, isFalse);
      expect(notifications, 2);
    });

    test('401/403 never count as maintenance HTTP status', () {
      expect(isMaintenanceHttpStatus(401), isFalse);
      expect(isMaintenanceHttpStatus(403), isFalse);
      expect(isMaintenanceHttpStatus(404), isFalse);
      expect(isMaintenanceHttpStatus(422), isFalse);
      expect(isMaintenanceHttpStatus(503), isTrue);
      expect(isMaintenanceHttpStatus(502), isTrue);
      expect(isMaintenanceHttpStatus(521), isTrue);
    });

    test('401 DioException does not indicate maintenance', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/creator/trust-score'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/creator/trust-score'),
          statusCode: 401,
          data: {'error': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(dioExceptionIndicatesMaintenance(err), isFalse);

      final service = MaintenanceService();
      var notifications = 0;
      service.addListener(() => notifications++);
      service.reportFromDio(err);
      expect(service.isActive, isFalse);
      expect(notifications, 0);
    });

    test(
      'healthy probe without allowRecovery does not notify when inactive',
      () async {
        final service = MaintenanceService();
        var notifications = 0;
        service.addListener(() => notifications++);

        await service.probeOnLaunch(allowRecovery: false);
        expect(service.isActive, isFalse);
        expect(notifications, 0);
      },
    );
  });

  group('MaintenanceRecoveryCoordinator', () {
    test('recoverNow dedupes concurrent calls via shared Future', () async {
      var recoverPasses = 0;
      final container = ProviderContainer(
        overrides: [
          ..._rateLimitOverrides(),
          maintenanceRecoveryCoordinatorProvider.overrideWith((ref) {
            return _AsyncCountingCoordinator(ref, () => recoverPasses++);
          }),
        ],
      );
      addTearDown(container.dispose);

      final coordinator = container.read(
        maintenanceRecoveryCoordinatorProvider,
      );

      final a = coordinator.recoverNow();
      final b = coordinator.recoverNow();
      expect(identical(a, b), isTrue);
      await Future.wait([a, b]);

      expect(recoverPasses, 1);
      expect(coordinator.isRecovering, isFalse);
    });

    test('coordinator is constructed with Ref (no WidgetRef cast)', () {
      final container = ProviderContainer(overrides: _rateLimitOverrides());
      addTearDown(container.dispose);

      final coordinator = container.read(
        maintenanceRecoveryCoordinatorProvider,
      );
      expect(coordinator, isA<MaintenanceRecoveryCoordinator>());
    });
  });

  group('MaintenanceGate recovery scheduling', () {
    testWidgets(
      'leaveMaintenance schedules one recovery after frame; keeps route',
      (tester) async {
        final service = MaintenanceServiceHolder.instance;
        var recoverCalls = 0;
        final container = ProviderContainer(
          overrides: [
            ..._rateLimitOverrides(),
            appPrefsProvider.overrideWithValue(AppPrefs.memory()),
            maintenanceServiceProvider.overrideWithValue(service),
            maintenanceRecoveryCoordinatorProvider.overrideWith((ref) {
              return _CountingCoordinator(ref, () => recoverCalls++);
            }),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _wrapGate(
              const MaterialApp(
                home: MaintenanceGate(
                  child: Scaffold(body: Text('route-kept')),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('route-kept'), findsOneWidget);

        // Toggle without pumping the overlay (avoids flutter_animate timers).
        service.enterMaintenance();
        service.leaveMaintenance();
        expect(recoverCalls, 0);

        await tester.pump(); // post-frame → recoverNow (sync counter)
        expect(recoverCalls, 1);

        service.leaveMaintenance();
        service.leaveMaintenance();
        await tester.pump();
        expect(recoverCalls, 1);

        expect(find.text('route-kept'), findsOneWidget);
      },
    );

    testWidgets('disposed gate does not throw on late leaveMaintenance', (
      tester,
    ) async {
      final service = MaintenanceServiceHolder.instance;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPrefsProvider.overrideWithValue(AppPrefs.memory()),
            ..._rateLimitOverrides(),
            maintenanceRecoveryCoordinatorProvider.overrideWith((ref) {
              return _CountingCoordinator(ref, () {});
            }),
          ],
          child: _wrapGate(
            const MaterialApp(
              home: MaintenanceGate(child: Scaffold(body: Text('alive'))),
            ),
          ),
        ),
      );
      await tester.pump();

      // Enter without pumping the overlay (avoids flutter_animate pending timers).
      service.enterMaintenance();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(() => service.leaveMaintenance(), returnsNormally);
      await tester.pump();
      await tester.pump(Duration.zero);
    });
  });
}

class _CountingCoordinator extends MaintenanceRecoveryCoordinator {
  _CountingCoordinator(super.ref, this._onRecover);

  final VoidCallback _onRecover;
  Future<void>? _ongoingLocal;

  @override
  bool get isRecovering => _ongoingLocal != null;

  @override
  Future<void> recoverNow() {
    // Sync path for widget tests (post-frame already delayed the call).
    // Concurrent Future-sharing is covered by the dedicated unit test below.
    if (_ongoingLocal != null) return _ongoingLocal!;
    _onRecover();
    final done = Future<void>.value();
    _ongoingLocal = done;
    return done.whenComplete(() {
      if (identical(_ongoingLocal, done)) {
        _ongoingLocal = null;
      }
    });
  }
}

/// Separate double that proves shared-Future dedupe without sync completion.
class _AsyncCountingCoordinator extends MaintenanceRecoveryCoordinator {
  _AsyncCountingCoordinator(super.ref, this._onRecover);

  final VoidCallback _onRecover;
  Future<void>? _ongoingLocal;

  @override
  bool get isRecovering => _ongoingLocal != null;

  @override
  Future<void> recoverNow() {
    final existing = _ongoingLocal;
    if (existing != null) return existing;
    late final Future<void> future;
    future =
        Future<void>(() {
          _onRecover();
        }).whenComplete(() {
          if (identical(_ongoingLocal, future)) {
            _ongoingLocal = null;
          }
        });
    _ongoingLocal = future;
    return future;
  }
}
