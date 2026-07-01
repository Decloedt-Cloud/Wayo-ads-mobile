// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'superadmin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$superadminRemoteHash() => r'd64d865f4290bccfc3428b8668e33f2c2e0a8999';

/// See also [superadminRemote].
@ProviderFor(superadminRemote)
final superadminRemoteProvider = Provider<SuperadminRemote>.internal(
  superadminRemote,
  name: r'superadminRemoteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$superadminRemoteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SuperadminRemoteRef = ProviderRef<SuperadminRemote>;
String _$superadminRepositoryHash() =>
    r'934a5a4683450e986cb1ac11b2ab7d655a0634d7';

/// See also [superadminRepository].
@ProviderFor(superadminRepository)
final superadminRepositoryProvider = Provider<ISuperadminRepository>.internal(
  superadminRepository,
  name: r'superadminRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$superadminRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SuperadminRepositoryRef = ProviderRef<ISuperadminRepository>;
String _$dashboardStatsHash() => r'8918cef952e3e9367d41e9f6a4c74bd7d4fe59ed';

/// See also [dashboardStats].
@ProviderFor(dashboardStats)
final dashboardStatsProvider =
    AutoDisposeFutureProvider<DashboardStats>.internal(
  dashboardStats,
  name: r'dashboardStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DashboardStatsRef = AutoDisposeFutureProviderRef<DashboardStats>;
String _$adminRecentTransactionsHash() =>
    r'b227ef6bafd28c99da9ba09e898a1266ed21b61b';

/// See also [adminRecentTransactions].
@ProviderFor(adminRecentTransactions)
final adminRecentTransactionsProvider =
    AutoDisposeFutureProvider<AdminTransactionsPage>.internal(
  adminRecentTransactions,
  name: r'adminRecentTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminRecentTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AdminRecentTransactionsRef
    = AutoDisposeFutureProviderRef<AdminTransactionsPage>;
String _$trafficQualitySummaryHash() =>
    r'1044338428a7fd3362b393b83a7c188a2c909098';

/// See also [trafficQualitySummary].
@ProviderFor(trafficQualitySummary)
final trafficQualitySummaryProvider =
    AutoDisposeFutureProvider<TrafficQualitySummary>.internal(
  trafficQualitySummary,
  name: r'trafficQualitySummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trafficQualitySummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrafficQualitySummaryRef
    = AutoDisposeFutureProviderRef<TrafficQualitySummary>;
String _$payoutStatsHash() => r'd303e4fa3bb1bc0406e24870b469c428dbb198e5';

/// See also [payoutStats].
@ProviderFor(payoutStats)
final payoutStatsProvider = AutoDisposeFutureProvider<PayoutStats>.internal(
  payoutStats,
  name: r'payoutStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$payoutStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PayoutStatsRef = AutoDisposeFutureProviderRef<PayoutStats>;
String _$userSearchHash() => r'75c6b99953bfb668f9f95df0c6799fa2aedc9f59';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userSearch].
@ProviderFor(userSearch)
const userSearchProvider = UserSearchFamily();

/// See also [userSearch].
class UserSearchFamily extends Family<AsyncValue<List<SearchUser>>> {
  /// See also [userSearch].
  const UserSearchFamily();

  /// See also [userSearch].
  UserSearchProvider call({
    required String query,
  }) {
    return UserSearchProvider(
      query: query,
    );
  }

  @override
  UserSearchProvider getProviderOverride(
    covariant UserSearchProvider provider,
  ) {
    return call(
      query: provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userSearchProvider';
}

/// See also [userSearch].
class UserSearchProvider extends AutoDisposeFutureProvider<List<SearchUser>> {
  /// See also [userSearch].
  UserSearchProvider({
    required String query,
  }) : this._internal(
          (ref) => userSearch(
            ref as UserSearchRef,
            query: query,
          ),
          from: userSearchProvider,
          name: r'userSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userSearchHash,
          dependencies: UserSearchFamily._dependencies,
          allTransitiveDependencies:
              UserSearchFamily._allTransitiveDependencies,
          query: query,
        );

  UserSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<SearchUser>> Function(UserSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserSearchProvider._internal(
        (ref) => create(ref as UserSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SearchUser>> createElement() {
    return _UserSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserSearchRef on AutoDisposeFutureProviderRef<List<SearchUser>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _UserSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<SearchUser>>
    with UserSearchRef {
  _UserSearchProviderElement(super.provider);

  @override
  String get query => (origin as UserSearchProvider).query;
}

String _$aiUsageHash() => r'5979f08932ddda6cb6432eebfb0d31a7856df1e5';

/// See also [aiUsage].
@ProviderFor(aiUsage)
const aiUsageProvider = AiUsageFamily();

/// See also [aiUsage].
class AiUsageFamily extends Family<AsyncValue<AiUsageStats>> {
  /// See also [aiUsage].
  const AiUsageFamily();

  /// See also [aiUsage].
  AiUsageProvider call({
    String period = '30d',
  }) {
    return AiUsageProvider(
      period: period,
    );
  }

  @override
  AiUsageProvider getProviderOverride(
    covariant AiUsageProvider provider,
  ) {
    return call(
      period: provider.period,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'aiUsageProvider';
}

/// See also [aiUsage].
class AiUsageProvider extends AutoDisposeFutureProvider<AiUsageStats> {
  /// See also [aiUsage].
  AiUsageProvider({
    String period = '30d',
  }) : this._internal(
          (ref) => aiUsage(
            ref as AiUsageRef,
            period: period,
          ),
          from: aiUsageProvider,
          name: r'aiUsageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$aiUsageHash,
          dependencies: AiUsageFamily._dependencies,
          allTransitiveDependencies: AiUsageFamily._allTransitiveDependencies,
          period: period,
        );

  AiUsageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.period,
  }) : super.internal();

  final String period;

  @override
  Override overrideWith(
    FutureOr<AiUsageStats> Function(AiUsageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AiUsageProvider._internal(
        (ref) => create(ref as AiUsageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AiUsageStats> createElement() {
    return _AiUsageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AiUsageProvider && other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AiUsageRef on AutoDisposeFutureProviderRef<AiUsageStats> {
  /// The parameter `period` of this provider.
  String get period;
}

class _AiUsageProviderElement
    extends AutoDisposeFutureProviderElement<AiUsageStats> with AiUsageRef {
  _AiUsageProviderElement(super.provider);

  @override
  String get period => (origin as AiUsageProvider).period;
}

String _$taxRatesHash() => r'8ee7d66f2d603ab4416d00d186d7691137aff54e';

/// See also [taxRates].
@ProviderFor(taxRates)
final taxRatesProvider = AutoDisposeFutureProvider<TaxRatesPage>.internal(
  taxRates,
  name: r'taxRatesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$taxRatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TaxRatesRef = AutoDisposeFutureProviderRef<TaxRatesPage>;
String _$bannedUsersNotifierHash() =>
    r'fba11400af2b46d8d784c60fcf5569f866854f20';

abstract class _$BannedUsersNotifier
    extends BuildlessAutoDisposeAsyncNotifier<BannedUsersPage> {
  late final String? search;

  FutureOr<BannedUsersPage> build({
    String? search,
  });
}

/// See also [BannedUsersNotifier].
@ProviderFor(BannedUsersNotifier)
const bannedUsersNotifierProvider = BannedUsersNotifierFamily();

/// See also [BannedUsersNotifier].
class BannedUsersNotifierFamily extends Family<AsyncValue<BannedUsersPage>> {
  /// See also [BannedUsersNotifier].
  const BannedUsersNotifierFamily();

  /// See also [BannedUsersNotifier].
  BannedUsersNotifierProvider call({
    String? search,
  }) {
    return BannedUsersNotifierProvider(
      search: search,
    );
  }

  @override
  BannedUsersNotifierProvider getProviderOverride(
    covariant BannedUsersNotifierProvider provider,
  ) {
    return call(
      search: provider.search,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bannedUsersNotifierProvider';
}

/// See also [BannedUsersNotifier].
class BannedUsersNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    BannedUsersNotifier, BannedUsersPage> {
  /// See also [BannedUsersNotifier].
  BannedUsersNotifierProvider({
    String? search,
  }) : this._internal(
          () => BannedUsersNotifier()..search = search,
          from: bannedUsersNotifierProvider,
          name: r'bannedUsersNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bannedUsersNotifierHash,
          dependencies: BannedUsersNotifierFamily._dependencies,
          allTransitiveDependencies:
              BannedUsersNotifierFamily._allTransitiveDependencies,
          search: search,
        );

  BannedUsersNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.search,
  }) : super.internal();

  final String? search;

  @override
  FutureOr<BannedUsersPage> runNotifierBuild(
    covariant BannedUsersNotifier notifier,
  ) {
    return notifier.build(
      search: search,
    );
  }

  @override
  Override overrideWith(BannedUsersNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BannedUsersNotifierProvider._internal(
        () => create()..search = search,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        search: search,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<BannedUsersNotifier, BannedUsersPage>
      createElement() {
    return _BannedUsersNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BannedUsersNotifierProvider && other.search == search;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BannedUsersNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<BannedUsersPage> {
  /// The parameter `search` of this provider.
  String? get search;
}

class _BannedUsersNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BannedUsersNotifier,
        BannedUsersPage> with BannedUsersNotifierRef {
  _BannedUsersNotifierProviderElement(super.provider);

  @override
  String? get search => (origin as BannedUsersNotifierProvider).search;
}

String _$adminUsersNotifierHash() =>
    r'7cf05900974c81d4a34a51a80f7f8c667f489158';

abstract class _$AdminUsersNotifier
    extends BuildlessAutoDisposeAsyncNotifier<AdminUsersPage> {
  late final String? search;
  late final RoleFilter? role;
  late final JoinedFilter? joined;
  late final bool? bannedOnly;

  FutureOr<AdminUsersPage> build({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
  });
}

/// See also [AdminUsersNotifier].
@ProviderFor(AdminUsersNotifier)
const adminUsersNotifierProvider = AdminUsersNotifierFamily();

/// See also [AdminUsersNotifier].
class AdminUsersNotifierFamily extends Family<AsyncValue<AdminUsersPage>> {
  /// See also [AdminUsersNotifier].
  const AdminUsersNotifierFamily();

  /// See also [AdminUsersNotifier].
  AdminUsersNotifierProvider call({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
  }) {
    return AdminUsersNotifierProvider(
      search: search,
      role: role,
      joined: joined,
      bannedOnly: bannedOnly,
    );
  }

  @override
  AdminUsersNotifierProvider getProviderOverride(
    covariant AdminUsersNotifierProvider provider,
  ) {
    return call(
      search: provider.search,
      role: provider.role,
      joined: provider.joined,
      bannedOnly: provider.bannedOnly,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminUsersNotifierProvider';
}

/// See also [AdminUsersNotifier].
class AdminUsersNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    AdminUsersNotifier, AdminUsersPage> {
  /// See also [AdminUsersNotifier].
  AdminUsersNotifierProvider({
    String? search,
    RoleFilter? role,
    JoinedFilter? joined,
    bool? bannedOnly,
  }) : this._internal(
          () => AdminUsersNotifier()
            ..search = search
            ..role = role
            ..joined = joined
            ..bannedOnly = bannedOnly,
          from: adminUsersNotifierProvider,
          name: r'adminUsersNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$adminUsersNotifierHash,
          dependencies: AdminUsersNotifierFamily._dependencies,
          allTransitiveDependencies:
              AdminUsersNotifierFamily._allTransitiveDependencies,
          search: search,
          role: role,
          joined: joined,
          bannedOnly: bannedOnly,
        );

  AdminUsersNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.search,
    required this.role,
    required this.joined,
    required this.bannedOnly,
  }) : super.internal();

  final String? search;
  final RoleFilter? role;
  final JoinedFilter? joined;
  final bool? bannedOnly;

  @override
  FutureOr<AdminUsersPage> runNotifierBuild(
    covariant AdminUsersNotifier notifier,
  ) {
    return notifier.build(
      search: search,
      role: role,
      joined: joined,
      bannedOnly: bannedOnly,
    );
  }

  @override
  Override overrideWith(AdminUsersNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AdminUsersNotifierProvider._internal(
        () => create()
          ..search = search
          ..role = role
          ..joined = joined
          ..bannedOnly = bannedOnly,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        search: search,
        role: role,
        joined: joined,
        bannedOnly: bannedOnly,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AdminUsersNotifier, AdminUsersPage>
      createElement() {
    return _AdminUsersNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUsersNotifierProvider &&
        other.search == search &&
        other.role == role &&
        other.joined == joined &&
        other.bannedOnly == bannedOnly;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);
    hash = _SystemHash.combine(hash, role.hashCode);
    hash = _SystemHash.combine(hash, joined.hashCode);
    hash = _SystemHash.combine(hash, bannedOnly.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AdminUsersNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<AdminUsersPage> {
  /// The parameter `search` of this provider.
  String? get search;

  /// The parameter `role` of this provider.
  RoleFilter? get role;

  /// The parameter `joined` of this provider.
  JoinedFilter? get joined;

  /// The parameter `bannedOnly` of this provider.
  bool? get bannedOnly;
}

class _AdminUsersNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AdminUsersNotifier,
        AdminUsersPage> with AdminUsersNotifierRef {
  _AdminUsersNotifierProviderElement(super.provider);

  @override
  String? get search => (origin as AdminUsersNotifierProvider).search;
  @override
  RoleFilter? get role => (origin as AdminUsersNotifierProvider).role;
  @override
  JoinedFilter? get joined => (origin as AdminUsersNotifierProvider).joined;
  @override
  bool? get bannedOnly => (origin as AdminUsersNotifierProvider).bannedOnly;
}

String _$withdrawalsNotifierHash() =>
    r'36d90f24c8aa3b86958ee540302d1073c001116b';

abstract class _$WithdrawalsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<WithdrawalsPage> {
  late final WithdrawalStatus? status;

  FutureOr<WithdrawalsPage> build({
    WithdrawalStatus? status,
  });
}

/// See also [WithdrawalsNotifier].
@ProviderFor(WithdrawalsNotifier)
const withdrawalsNotifierProvider = WithdrawalsNotifierFamily();

/// See also [WithdrawalsNotifier].
class WithdrawalsNotifierFamily extends Family<AsyncValue<WithdrawalsPage>> {
  /// See also [WithdrawalsNotifier].
  const WithdrawalsNotifierFamily();

  /// See also [WithdrawalsNotifier].
  WithdrawalsNotifierProvider call({
    WithdrawalStatus? status,
  }) {
    return WithdrawalsNotifierProvider(
      status: status,
    );
  }

  @override
  WithdrawalsNotifierProvider getProviderOverride(
    covariant WithdrawalsNotifierProvider provider,
  ) {
    return call(
      status: provider.status,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'withdrawalsNotifierProvider';
}

/// See also [WithdrawalsNotifier].
class WithdrawalsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    WithdrawalsNotifier, WithdrawalsPage> {
  /// See also [WithdrawalsNotifier].
  WithdrawalsNotifierProvider({
    WithdrawalStatus? status,
  }) : this._internal(
          () => WithdrawalsNotifier()..status = status,
          from: withdrawalsNotifierProvider,
          name: r'withdrawalsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$withdrawalsNotifierHash,
          dependencies: WithdrawalsNotifierFamily._dependencies,
          allTransitiveDependencies:
              WithdrawalsNotifierFamily._allTransitiveDependencies,
          status: status,
        );

  WithdrawalsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final WithdrawalStatus? status;

  @override
  FutureOr<WithdrawalsPage> runNotifierBuild(
    covariant WithdrawalsNotifier notifier,
  ) {
    return notifier.build(
      status: status,
    );
  }

  @override
  Override overrideWith(WithdrawalsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WithdrawalsNotifierProvider._internal(
        () => create()..status = status,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<WithdrawalsNotifier, WithdrawalsPage>
      createElement() {
    return _WithdrawalsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WithdrawalsNotifierProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WithdrawalsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<WithdrawalsPage> {
  /// The parameter `status` of this provider.
  WithdrawalStatus? get status;
}

class _WithdrawalsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<WithdrawalsNotifier,
        WithdrawalsPage> with WithdrawalsNotifierRef {
  _WithdrawalsNotifierProviderElement(super.provider);

  @override
  WithdrawalStatus? get status =>
      (origin as WithdrawalsNotifierProvider).status;
}

String _$announcementsNotifierHash() =>
    r'219f4f4b8b76bda87fa1953f627ff04d2185005b';

/// See also [AnnouncementsNotifier].
@ProviderFor(AnnouncementsNotifier)
final announcementsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    AnnouncementsNotifier, List<Announcement>>.internal(
  AnnouncementsNotifier.new,
  name: r'announcementsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$announcementsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnnouncementsNotifier = AutoDisposeAsyncNotifier<List<Announcement>>;
String _$ledgerNotifierHash() => r'e3308b014ebdf7569c41b3ba222f71a9d4313f14';

abstract class _$LedgerNotifier
    extends BuildlessAutoDisposeAsyncNotifier<LedgerPage> {
  late final LedgerEntryType? type;
  late final String? creatorId;
  late final String? campaignId;
  late final DateTime? startDate;
  late final DateTime? endDate;

  FutureOr<LedgerPage> build({
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// See also [LedgerNotifier].
@ProviderFor(LedgerNotifier)
const ledgerNotifierProvider = LedgerNotifierFamily();

/// See also [LedgerNotifier].
class LedgerNotifierFamily extends Family<AsyncValue<LedgerPage>> {
  /// See also [LedgerNotifier].
  const LedgerNotifierFamily();

  /// See also [LedgerNotifier].
  LedgerNotifierProvider call({
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return LedgerNotifierProvider(
      type: type,
      creatorId: creatorId,
      campaignId: campaignId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  LedgerNotifierProvider getProviderOverride(
    covariant LedgerNotifierProvider provider,
  ) {
    return call(
      type: provider.type,
      creatorId: provider.creatorId,
      campaignId: provider.campaignId,
      startDate: provider.startDate,
      endDate: provider.endDate,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'ledgerNotifierProvider';
}

/// See also [LedgerNotifier].
class LedgerNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<LedgerNotifier, LedgerPage> {
  /// See also [LedgerNotifier].
  LedgerNotifierProvider({
    LedgerEntryType? type,
    String? creatorId,
    String? campaignId,
    DateTime? startDate,
    DateTime? endDate,
  }) : this._internal(
          () => LedgerNotifier()
            ..type = type
            ..creatorId = creatorId
            ..campaignId = campaignId
            ..startDate = startDate
            ..endDate = endDate,
          from: ledgerNotifierProvider,
          name: r'ledgerNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ledgerNotifierHash,
          dependencies: LedgerNotifierFamily._dependencies,
          allTransitiveDependencies:
              LedgerNotifierFamily._allTransitiveDependencies,
          type: type,
          creatorId: creatorId,
          campaignId: campaignId,
          startDate: startDate,
          endDate: endDate,
        );

  LedgerNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
    required this.creatorId,
    required this.campaignId,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final LedgerEntryType? type;
  final String? creatorId;
  final String? campaignId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  FutureOr<LedgerPage> runNotifierBuild(
    covariant LedgerNotifier notifier,
  ) {
    return notifier.build(
      type: type,
      creatorId: creatorId,
      campaignId: campaignId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Override overrideWith(LedgerNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LedgerNotifierProvider._internal(
        () => create()
          ..type = type
          ..creatorId = creatorId
          ..campaignId = campaignId
          ..startDate = startDate
          ..endDate = endDate,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
        creatorId: creatorId,
        campaignId: campaignId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<LedgerNotifier, LedgerPage>
      createElement() {
    return _LedgerNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LedgerNotifierProvider &&
        other.type == type &&
        other.creatorId == creatorId &&
        other.campaignId == campaignId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, creatorId.hashCode);
    hash = _SystemHash.combine(hash, campaignId.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LedgerNotifierRef on AutoDisposeAsyncNotifierProviderRef<LedgerPage> {
  /// The parameter `type` of this provider.
  LedgerEntryType? get type;

  /// The parameter `creatorId` of this provider.
  String? get creatorId;

  /// The parameter `campaignId` of this provider.
  String? get campaignId;

  /// The parameter `startDate` of this provider.
  DateTime? get startDate;

  /// The parameter `endDate` of this provider.
  DateTime? get endDate;
}

class _LedgerNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<LedgerNotifier, LedgerPage>
    with LedgerNotifierRef {
  _LedgerNotifierProviderElement(super.provider);

  @override
  LedgerEntryType? get type => (origin as LedgerNotifierProvider).type;
  @override
  String? get creatorId => (origin as LedgerNotifierProvider).creatorId;
  @override
  String? get campaignId => (origin as LedgerNotifierProvider).campaignId;
  @override
  DateTime? get startDate => (origin as LedgerNotifierProvider).startDate;
  @override
  DateTime? get endDate => (origin as LedgerNotifierProvider).endDate;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
