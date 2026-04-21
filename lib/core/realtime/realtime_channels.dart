/// Laravel Reverb private channel names (Wayo-ads / broadcasting).
///
/// // TODO(realtime): confirm channel naming with Wayo-ads backend.
abstract final class RealtimeChannels {
  static String advertiser(int userId) => 'private-advertiser.$userId';

  static String user(int userId) => 'private-user.$userId';
}
