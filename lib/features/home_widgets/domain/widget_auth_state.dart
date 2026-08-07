/// Auth presentation state for home widgets (never includes tokens).
enum WidgetAuthState {
  loggedOut,
  tokenExpired,
  loggedIn;

  static WidgetAuthState fromStorage(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'logged_in':
      case 'loggedin':
        return WidgetAuthState.loggedIn;
      case 'token_expired':
      case 'tokenexpired':
        return WidgetAuthState.tokenExpired;
      default:
        return WidgetAuthState.loggedOut;
    }
  }

  String get storageValue => switch (this) {
        WidgetAuthState.loggedIn => 'logged_in',
        WidgetAuthState.tokenExpired => 'token_expired',
        WidgetAuthState.loggedOut => 'logged_out',
      };

  String get statusMessage => switch (this) {
        WidgetAuthState.loggedOut => 'Sign in to see your dashboard',
        WidgetAuthState.tokenExpired => 'Open Wayo to refresh',
        WidgetAuthState.loggedIn => '',
      };

  String statusMessageForLocale(String localeCode) {
    final fr = localeCode.startsWith('fr');
    return switch (this) {
      WidgetAuthState.loggedOut => fr
          ? 'Connectez-vous pour voir votre tableau de bord'
          : 'Sign in to see your dashboard',
      WidgetAuthState.tokenExpired =>
        fr ? 'Ouvrez Wayo pour actualiser' : 'Open Wayo to refresh',
      WidgetAuthState.loggedIn => '',
    };
  }
}
