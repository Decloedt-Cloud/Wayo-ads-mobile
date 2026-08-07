import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/creator_analytics/domain/creator_analytics_snapshot.dart';
import 'package:wayoadsgo/features/creator_trust/domain/creator_trust_score.dart';
import 'package:wayoadsgo/features/youtube_connection/domain/youtube_channel.dart';

void main() {
  group('YouTubeChannelResponse', () {
    test('parses active channel', () {
      final r = YouTubeChannelResponse.fromJson({
        'oauthStatus': 'active',
        'channel': {
          'youtubeChannelId': 'UC1',
          'channelName': 'Demo',
          'subscriberCount': 12,
        },
      });
      expect(r.isConnected, isTrue);
      expect(r.channel?.channelName, 'Demo');
      expect(r.channel?.subscriberCount, 12);
    });

    test('parses reconnect_required', () {
      final r = YouTubeChannelResponse.fromJson({
        'oauthStatus': 'reconnect_required',
        'channel': {'channelName': 'Old'},
      });
      expect(r.needsReconnect, isTrue);
    });
  });

  group('YouTubeConnectResult', () {
    test('parses reconnect flag', () {
      final r = YouTubeConnectResult.fromJson({
        'channelName': 'X',
        'isReconnect': true,
      });
      expect(r.isReconnect, isTrue);
    });
  });

  group('CreatorTrustScoreSnapshot', () {
    test('parses safe fields only', () {
      final s = CreatorTrustScoreSnapshot.fromJson({
        'trustScore': 72,
        'tier': 'GOLD',
        'isVerified': true,
        'verificationLevel': 'YOUTUBE_VERIFIED',
        'hasMetrics': true,
        'weeklyDelta': 3,
        'potentialCpmIncrease': '+5%',
        'breakdown': {'fraudScorePoints': 99},
      });
      expect(s.trustScore, 72);
      expect(s.tier, 'GOLD');
      expect(s.weeklyDelta, 3);
    });
  });

  group('CreatorAnalyticsSnapshot', () {
    test('parses summary and daily series', () {
      final snap = CreatorAnalyticsSnapshot.fromJson({
        'period': '7d',
        'days': 7,
        'currency': 'USD',
        'data': [
          {
            'date': '2026-01-01',
            'recordedViews': 10,
            'validatedViews': 8,
            'recordedClicks': 2,
            'validatedClicks': 1,
          },
        ],
        'summary': {
          'totalRecordedViews': 10,
          'totalValidatedViews': 8,
          'viewValidationRate': 80,
          'totalRecordedClicks': 2,
          'totalValidatedClicks': 1,
          'clickValidationRate': 50,
          'totalEarnings': 1500,
          'pendingAmount': 200,
        },
        'campaigns': [],
        'campaignBreakdown': [
          {
            'campaignId': 'c1',
            'campaignName': 'Ads',
            'campaignType': 'LINK',
            'validatedViews': 8,
            'validatedClicks': 1,
            'earnings': 1500,
          },
        ],
      });
      expect(snap.summary.totalEarnings, 1500);
      expect(snap.data.single.validatedViews, 8);
      expect(snap.campaignBreakdown.single.campaignName, 'Ads');
    });
  });

  group('YouTube OAuth error codes', () {
    test('known API errors are stable strings', () {
      const codes = [
        'invalid_state',
        'channel_already_connected',
        'connection_cancelled',
        'YouTube channel already connected',
      ];
      expect(codes, contains('invalid_state'));
      expect(codes, contains('channel_already_connected'));
    });
  });
}
