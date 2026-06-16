import 'package:equatable/equatable.dart';

/// Creator's unique tracking short link for a LINK campaign
/// (`CreatorTrackingLink` on Wayo-ads, `/t/{slug}`).
final class CreatorTrackingLink extends Equatable {
  const CreatorTrackingLink({
    required this.id,
    required this.slug,
    this.totalClicks = 0,
    this.validatedClicks = 0,
  });

  final String id;
  final String slug;
  final int totalClicks;
  final int validatedClicks;

  factory CreatorTrackingLink.fromJson(Map<String, dynamic> m) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final clickCounts = m['clickCounts'];
    final countsMap =
        clickCounts is Map ? Map<String, dynamic>.from(clickCounts) : null;
    final countBlock = m['_count'];
    final countMap =
        countBlock is Map ? Map<String, dynamic>.from(countBlock) : null;

    return CreatorTrackingLink(
      id: '${m['id'] ?? ''}',
      slug: (m['slug'] as String?)?.trim() ?? '',
      totalClicks: asInt(
        countsMap?['total'] ?? countMap?['visitEvents'],
      ),
      validatedClicks: asInt(countsMap?['validated']),
    );
  }

  @override
  List<Object?> get props => [id, slug, totalClicks, validatedClicks];
}
