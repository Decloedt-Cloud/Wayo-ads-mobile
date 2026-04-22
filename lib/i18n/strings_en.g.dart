///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final TranslationsConnectivityEn connectivity = TranslationsConnectivityEn.internal(_root);
	late final TranslationsLoginEn login = TranslationsLoginEn.internal(_root);
	late final TranslationsForgotPasswordEn forgot_password = TranslationsForgotPasswordEn.internal(_root);
	late final TranslationsOtpEn otp = TranslationsOtpEn.internal(_root);
	late final TranslationsResetPasswordEn reset_password = TranslationsResetPasswordEn.internal(_root);
	late final TranslationsValidationEn validation = TranslationsValidationEn.internal(_root);
	late final TranslationsHomeEn home = TranslationsHomeEn.internal(_root);
	late final TranslationsDashboardEn dashboard = TranslationsDashboardEn.internal(_root);
	late final TranslationsAdvertiserCampaignsEn advertiser_campaigns = TranslationsAdvertiserCampaignsEn.internal(_root);
	late final TranslationsNavEn nav = TranslationsNavEn.internal(_root);
	late final TranslationsChatEn chat = TranslationsChatEn.internal(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsPrivacyPolicyEn privacy_policy = TranslationsPrivacyPolicyEn.internal(_root);
	late final TranslationsAppSettingsEn app_settings = TranslationsAppSettingsEn.internal(_root);
}

// Path: connectivity
class TranslationsConnectivityEn {
	TranslationsConnectivityEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get offline_title => 'No Internet Connection';
	String get offline_subtitle => 'Please check your network and try again.';
	String get reconnecting_title => 'Reconnecting…';
	String get reconnecting_subtitle => 'Trying to restore your connection.';
	String get weak_title => 'Weak connection';
	String get weak_subtitle => 'Some actions may be slower than usual.';
	String get restored => 'Connection restored';
	String get action_retry => 'Retry';
	String get action_settings => 'Settings';
}

// Path: login
class TranslationsLoginEn {
	TranslationsLoginEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get brand => 'Wayo Ads';
	String get headline_line1 => 'Welcome';
	String get headline_line2_prefix => 'to ';
	String get headline_brand => 'Wayo';
	String get subtitle => 'Sign in with your Wayo ID to manage your campaigns and collaborations.';
	String get cta => 'Sign in with Wayo';
	String get secure_note => 'Secure authentication via Wayo ID';
	String get terms_prefix => 'By continuing, you agree to our ';
	String get terms => 'Terms';
	String get and => ' and ';
	String get privacy => 'Privacy Policy';
	String get dot => '.';
	String get email_label => 'Email';
	String get password_label => 'Password';
	String get show_password => 'Show';
	String get hide_password => 'Hide';
	String get email_required => 'Email is required';
	String get email_invalid => 'Invalid email';
	String get password_required => 'Password is required';
	String get password_min => 'At least 6 characters';
	String get rate_limit_title => 'Please wait';
	String get rate_limit_body => 'Too many login attempts.';
	String rate_limit_remaining({required Object seconds}) => 'Try again in ${seconds} s';
	String get forgot_password_link => 'Forgot password?';
	String get google_cta => 'Continue with Google';
	String get google_not_configured => 'Google sign-in is not configured. Add AUTH_GOOGLE_SERVER_CLIENT_ID to dart_defines.json (Web client ID ending in .apps.googleusercontent.com) and do a full restart.';
	String get google_wrong_client_id => 'AUTH_GOOGLE_SERVER_CLIENT_ID must be your Google Cloud Web client ID (…apps.googleusercontent.com), not the Passport OAuth client UUID.';
	String get google_failed => 'Google sign-in failed. Try again.';
	String get google_channel_restart => 'Google Sign-In lost connection to Android (often after hot restart). Stop the app completely, then Run again — do not use hot restart.';
}

// Path: forgot_password
class TranslationsForgotPasswordEn {
	TranslationsForgotPasswordEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Reset\npassword';
	String get subtitle => 'Enter your Wayo email. We will send you a 6-digit code.';
	String get email_label => 'Email';
	String get cta => 'Send code';
	String get rate_limit_title => 'Please wait';
	String get rate_limit_body => 'Too many password reset requests. Try again shortly.';
	String rate_limit_remaining({required Object seconds}) => 'Try again in ${seconds} s';
}

// Path: otp
class TranslationsOtpEn {
	TranslationsOtpEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Verify\nyour email';
	String subtitle({required Object email}) => 'Enter the code sent to ${email}';
	String get resend => 'Resend code';
	String resend_in({required Object seconds}) => 'Resend in ${seconds} s';
}

// Path: reset_password
class TranslationsResetPasswordEn {
	TranslationsResetPasswordEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'New\npassword';
	String get subtitle => 'Choose a strong password (min. 8 characters, 1 uppercase letter, 1 digit).';
	String get new_password => 'New password';
	String get confirm_password => 'Confirm password';
	String get cta => 'Update password';
	String get password_updated => 'Password updated. You can now sign in.';
}

// Path: validation
class TranslationsValidationEn {
	TranslationsValidationEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get required => 'Required';
	String get invalid_email => 'Invalid email';
	String get min8 => 'At least 8 characters';
	String get need_upper => 'Needs an uppercase letter';
	String get need_digit => 'Needs a digit';
	String get mismatch => 'Passwords do not match';
}

// Path: home
class TranslationsHomeEn {
	TranslationsHomeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Wayo Ads';
	String get logout => 'Log out';
	String get session_title => 'Active session';
	String get session_hint => 'Auth_Wayo token stored securely. API calls use Authorization: Bearer automatically.';
	String get user_fallback => 'User';
}

// Path: dashboard
class TranslationsDashboardEn {
	TranslationsDashboardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Dashboard';
	String get welcome => 'Welcome back, {name}!';
	String get welcome_fallback => 'Welcome back!';
	String get subtitle => 'Here\'s your current campaign overview.';
	String get account_creator => 'Creator account';
	String get account_advertiser => 'Advertiser account';
	String get coming_soon => 'Coming soon.';
	late final TranslationsDashboardBalanceEn balance = TranslationsDashboardBalanceEn.internal(_root);
	late final TranslationsDashboardCampaignsEn campaigns = TranslationsDashboardCampaignsEn.internal(_root);
	late final TranslationsDashboardErrorsEn errors = TranslationsDashboardErrorsEn.internal(_root);
	String get notifications_title => 'Notifications';
	String get notifications_empty => 'No notifications';
	String get notification_incoming => 'New notification';
	String get notification_view => 'View';
	String get notifications_mark_all_read => 'Mark all read';
	String get notifications_view_all => 'View all notifications';
	String get notifications_important => 'Important';
	String get theme_toggle_tooltip => 'Switch between light and dark theme';
	String get refresh => 'Refresh dashboard';
}

// Path: advertiser_campaigns
class TranslationsAdvertiserCampaignsEn {
	TranslationsAdvertiserCampaignsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Campaigns';
	String get subtitle => 'Track your campaign performance — read only.';
	late final TranslationsAdvertiserCampaignsTabsEn tabs = TranslationsAdvertiserCampaignsTabsEn.internal(_root);
	String get search_placeholder => 'Search campaigns';
	late final TranslationsAdvertiserCampaignsEmptyEn empty = TranslationsAdvertiserCampaignsEmptyEn.internal(_root);
	late final TranslationsAdvertiserCampaignsCardEn card = TranslationsAdvertiserCampaignsCardEn.internal(_root);
	late final TranslationsAdvertiserCampaignsStatusEn status = TranslationsAdvertiserCampaignsStatusEn.internal(_root);
	late final TranslationsAdvertiserCampaignsPlatformEn platform = TranslationsAdvertiserCampaignsPlatformEn.internal(_root);
	late final TranslationsAdvertiserCampaignsDetailEn detail = TranslationsAdvertiserCampaignsDetailEn.internal(_root);
}

// Path: nav
class TranslationsNavEn {
	TranslationsNavEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get dashboard => 'Dashboard';
	String get campaigns => 'Campaigns';
	String get analytics => 'Analytics';
	String get wallet => 'Wallet';
	String get chat => 'Chat';
}

// Path: chat
class TranslationsChatEn {
	TranslationsChatEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get inbox_title => 'Messages';
	String get inbox_subtitle => 'Secure conversations for your campaigns';
	String get conversation_unknown => 'Conversation';
	String get thread_fallback_title => 'Chat';
	String get composer_hint => 'Write a message…';
	String get typing => 'Typing…';
	String get error_load_threads => 'Could not load your conversations. Try again.';
	String get error_phone => 'Sharing phone numbers in chat is not allowed.';
	String get empty_threads_title => 'No conversations yet';
	String get empty_threads_hint => 'When someone messages you about a campaign, it will appear here.';
	String get online => 'Online';
	String get offline => 'Offline';
	String get typing_status => 'Typing…';
	String get attachment => 'Attachment';
	String get attachment_image => 'Photo';
	String get attachment_pdf => 'PDF';
	String get open_file => 'Open';
	String get pick_attachment => 'Image or PDF';
	String get upload_failed => 'Could not send the file. Try again.';
	String get file_too_large => 'File is too large (max 10 MB for images, 50 MB for PDF).';
	String get search_users_hint => 'Search people by name…';
	String get search_users_no_results => 'No users match your search.';
	String get search_users_min_hint => 'Type at least 2 characters to search.';
	String get conversation_open_failed => 'Could not open that conversation. Try again.';
	String get file_picker_restart_hint => 'Attachments need a full app restart after updates. Stop the app, then Run again (avoid hot restart).';
	String get attachment_type_not_allowed => 'Only images (JPG, PNG, GIF, WebP, BMP) or PDF are allowed.';
	String get inbox_swipe_soon => 'Pin and archive from the list are coming soon.';
	String get date_today => 'Today';
	String get date_yesterday => 'Yesterday';
	String get bubble_reply => 'Reply';
	String get bubble_copy => 'Copy';
	String get bubble_react => 'React';
	String get bubble_delete => 'Delete';
	String get bubble_update => 'Edit';
	String get bubble_delete_unavailable => 'Deleting messages from the app is not available yet.';
	String get bubble_copied => 'Copied to clipboard';
	String get edited => 'edited';
	String get seen => 'Seen';
	String get delivered => 'Delivered';
	String get edit_mode_title => 'Editing message';
	String get edit_mode_cancel => 'Cancel';
	String get edit_mode_hint => 'Update your message…';
	String get edit_failed => 'Could not update the message. Try again.';
	String get edit_not_allowed => 'Only your own text messages can be edited.';
	String get delete_failed => 'Could not delete the message. Try again.';
	String get delete_not_allowed => 'You can only delete your own messages.';
	String get delete_confirm_title => 'Delete this message?';
	String get delete_confirm_text => 'This action cannot be undone.';
	String get delete_confirm_cta => 'Delete';
	String get delete_confirm_cancel => 'Cancel';
	String get scroll_to_latest => 'Latest';
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get language => 'Language';
	String get theme => 'Theme';
	String get light => 'Light';
	String get dark => 'Dark';
	String get system => 'System';
}

// Path: errors
class TranslationsErrorsEn {
	TranslationsErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get rate_limited => 'Too many attempts. Please try again in a few minutes.';
	String get invalid_credentials => 'These credentials do not match our records.';
	String get network => 'Unable to reach the server. Check your connection.';
	String get server_generic => 'Something went wrong. Please try again.';
	String get empty_response => 'Empty response from server.';
	String get login_failed => 'Login failed.';
	String get unknown => 'An unexpected error occurred.';
	String get session_invalid => 'Your session has expired. Please sign in again.';
	String get email_not_found => 'No account found for this email.';
}

// Path: privacy_policy
class TranslationsPrivacyPolicyEn {
	TranslationsPrivacyPolicyEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Privacy Policy';
	String get last_updated => 'Last updated: October 7, 2025';
	String get intro_title => '1. Introduction';
	String get intro_body => 'At Wayo Ads, we are committed to collecting and using your data responsibly, in compliance with applicable data protection laws, including Moroccan law no. 09-08 and, when applicable, the GDPR (EU 2016/679). By using our platform, you agree to the collection, processing, and use of your data as described in this privacy policy.';
	String get data_title => '2. Data We Collect';
	String get data_body => 'We only collect data that is necessary, in accordance with law 09-08 and, where applicable, the GDPR.\n\nFor advertisers\n• Identification and contact: company name, email address, phone number.\n• Profile: business logo (if provided), company description.\n• Campaigns: campaign content, budgets, targeting criteria, analytics data.\n\nFor creators\n• Identification and contact: name, email address, phone number.\n• Profile: profile photo (if provided), biography, expertise, social media links.\n• Content: videos, posts, and materials you upload.\n• Usage: interactions with the platform, engagement statistics, earnings data.\n\nTechnical information (all users)\n• Technical data: IP address, browser type and version, device type, operating system, session identifiers, timestamps, pages visited, clicks, referrers.\n• Cookies and similar technologies: see section 8 (Cookies).\n\nPayment data\n• Transactions: amounts, currency, date, payment method, billing address.\n• Important: card data is processed exclusively by our payment provider (Stripe). Wayo Ads does not store credit card information.';
	String get purpose_title => '3. Purpose of Using Your Data';
	String get purpose_body => 'We use your data to: provide, maintain, and improve our services; personalize the experience and recommend relevant content; manage contractual relationships (accounts, billing, support); communicate service information (updates, changes, alerts); ensure platform security and integrity (abuse and fraud detection); and perform usage analysis with aggregated or anonymized data whenever possible.';
	String get legal_bases_title => '4. Legal Bases for Processing';
	String get legal_bases_body => 'Depending on the case, we rely on: your consent (for example, non-essential cookies, newsletters); performance of a contract or pre-contractual measures (for example, registration, billing); compliance with a legal obligation (for example, invoice retention); and our legitimate interests (for example, security, service improvement).';
	String get sharing_title => '5. Sharing Your Information';
	String get sharing_body => 'Wayo Ads does not sell your personal data. Limited sharing may occur with: essential service providers (payment processors, hosting providers, emailing tools, analytics); and for legal reasons if required by law or in response to a legitimate request from a competent authority.';
	String get security_title => '6. Data Security';
	String get security_body => 'We apply measures including: TLS/HTTPS encryption for data in transit; access controls based on need-to-know; regular backups and restoration procedures; security updates and periodic audits; and logging and detection of abnormal activities.';
	String get content_title => '7. User Responsibilities and Content Protection';
	String get content_body => 'You must respect the intellectual property rights of creators and Wayo Ads. Do not copy, share, redistribute, or resell content without authorization. Any violation may result in account suspension and, if applicable, legal action.';
	String get cookies_title => '8. Cookies and Tracking Technologies';
	String get cookies_body => 'We use: essential cookies (site functionality, security, session); and analytical cookies (for example, Google Analytics) for audience measurement. Non-essential cookies are only set with your consent via a cookie banner on your first visit.';
	String get retention_title => '9. Data Retention';
	String get retention_body => 'We retain your data only as long as necessary for the purposes outlined in this policy. Account data is retained for the duration of your account plus any legally required retention period. Transaction data is retained in accordance with accounting and tax requirements.';
	String get children_title => '10. Children\'s Privacy';
	String get children_body => 'Our services are not intended for children under 18. We do not knowingly collect personal information from children. If we become aware that we have collected data from a child without parental consent, we will take steps to delete such information.';
	String get changes_title => '11. Changes to This Policy';
	String get changes_body => 'We may update this privacy policy from time to time. We will notify you of any material changes by posting the new policy on this page and updating the "Last updated" date.';
	String get contact_title => '12. Contact Information';
	String get contact_body => 'Data controller: Wayo, Dubai, UAE.\nEmail: info@wayo.cloud\nAddress: R320 Umm Hurair 2, Dubai, UAE.';
}

// Path: app_settings
class TranslationsAppSettingsEn {
	TranslationsAppSettingsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Preferences';
	String get subtitle => 'Appearance & language';
	String get section_appearance => 'Appearance';
	String get section_language => 'Language';
	String get theme_light => 'Light';
	String get theme_dark => 'Dark';
	String get theme_system => 'System';
	String get theme_hint => 'Choose how Wayo Ads looks. System follows your device setting.';
	String get language_hint => 'Interface language. Dates and formats follow the locale.';
	String get design_variant => 'Panel style';
	String get design_glass => 'Soft glass';
	String get design_corporate => 'Corporate';
	String get close => 'Close';
	String get open_semantics => 'Open preferences and language';
	String get close_semantics => 'Close preferences';
	String get profile_fallback => 'Account';
	String get selected => 'Selected';
	String get lang_en => 'English';
	String get lang_fr => 'Français';
	String get lang_ar => 'العربية';
}

// Path: dashboard.balance
class TranslationsDashboardBalanceEn {
	TranslationsDashboardBalanceEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Balance overview';
	String get available => 'Available';
	String get locked => 'Locked';
	String get spent => 'Spent';
}

// Path: dashboard.campaigns
class TranslationsDashboardCampaignsEn {
	TranslationsDashboardCampaignsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Your Campaigns';
	String get subtitle => 'Manage your campaigns and track their performance.';
	String get creators => '{count} Creators';
	String get empty_title => 'No campaigns';
	String get empty_subtitle => 'Create your first campaign to get started';
	String get create_cta => 'Create Campaign';
}

// Path: dashboard.errors
class TranslationsDashboardErrorsEn {
	TranslationsDashboardErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get load_balance => 'Couldn\'t load balance';
	String get load_campaigns => 'Couldn\'t load campaigns';
	String get retry => 'Retry';
}

// Path: advertiser_campaigns.tabs
class TranslationsAdvertiserCampaignsTabsEn {
	TranslationsAdvertiserCampaignsTabsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get active => 'Active';
	String get paused => 'Paused';
	String get completed => 'Completed';
}

// Path: advertiser_campaigns.empty
class TranslationsAdvertiserCampaignsEmptyEn {
	TranslationsAdvertiserCampaignsEmptyEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get none => 'No campaigns found';
	String get hint => 'You don\'t have any campaigns in this status yet.';
	String get search => 'No campaigns match your search';
	String get search_hint => 'Try a different name or clear the search field.';
}

// Path: advertiser_campaigns.card
class TranslationsAdvertiserCampaignsCardEn {
	TranslationsAdvertiserCampaignsCardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get budget_total => 'Budget';
	String get remaining => 'Remaining';
	String get spent => 'Spent';
	String get cpc => 'CPC';
	String get valid_engagements => '{count} validated views';
}

// Path: advertiser_campaigns.status
class TranslationsAdvertiserCampaignsStatusEn {
	TranslationsAdvertiserCampaignsStatusEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get active => 'Active';
	String get paused => 'Paused';
	String get completed => 'Completed';
	String get draft => 'Draft';
	String get other => 'Other';
}

// Path: advertiser_campaigns.platform
class TranslationsAdvertiserCampaignsPlatformEn {
	TranslationsAdvertiserCampaignsPlatformEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get youtube => 'YouTube';
	String get tiktok => 'TikTok';
	String get instagram => 'Instagram';
	String get other => 'Platform';
}

// Path: advertiser_campaigns.detail
class TranslationsAdvertiserCampaignsDetailEn {
	TranslationsAdvertiserCampaignsDetailEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get fallback_title => 'Campaign';
	String get metrics_title => 'Performance';
	String get valid_views => 'Validated views';
	String get approved_creators => 'Approved creators';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'connectivity.offline_title': return 'No Internet Connection';
			case 'connectivity.offline_subtitle': return 'Please check your network and try again.';
			case 'connectivity.reconnecting_title': return 'Reconnecting…';
			case 'connectivity.reconnecting_subtitle': return 'Trying to restore your connection.';
			case 'connectivity.weak_title': return 'Weak connection';
			case 'connectivity.weak_subtitle': return 'Some actions may be slower than usual.';
			case 'connectivity.restored': return 'Connection restored';
			case 'connectivity.action_retry': return 'Retry';
			case 'connectivity.action_settings': return 'Settings';
			case 'login.brand': return 'Wayo Ads';
			case 'login.headline_line1': return 'Welcome';
			case 'login.headline_line2_prefix': return 'to ';
			case 'login.headline_brand': return 'Wayo';
			case 'login.subtitle': return 'Sign in with your Wayo ID to manage your campaigns and collaborations.';
			case 'login.cta': return 'Sign in with Wayo';
			case 'login.secure_note': return 'Secure authentication via Wayo ID';
			case 'login.terms_prefix': return 'By continuing, you agree to our ';
			case 'login.terms': return 'Terms';
			case 'login.and': return ' and ';
			case 'login.privacy': return 'Privacy Policy';
			case 'login.dot': return '.';
			case 'login.email_label': return 'Email';
			case 'login.password_label': return 'Password';
			case 'login.show_password': return 'Show';
			case 'login.hide_password': return 'Hide';
			case 'login.email_required': return 'Email is required';
			case 'login.email_invalid': return 'Invalid email';
			case 'login.password_required': return 'Password is required';
			case 'login.password_min': return 'At least 6 characters';
			case 'login.rate_limit_title': return 'Please wait';
			case 'login.rate_limit_body': return 'Too many login attempts.';
			case 'login.rate_limit_remaining': return ({required Object seconds}) => 'Try again in ${seconds} s';
			case 'login.forgot_password_link': return 'Forgot password?';
			case 'login.google_cta': return 'Continue with Google';
			case 'login.google_not_configured': return 'Google sign-in is not configured. Add AUTH_GOOGLE_SERVER_CLIENT_ID to dart_defines.json (Web client ID ending in .apps.googleusercontent.com) and do a full restart.';
			case 'login.google_wrong_client_id': return 'AUTH_GOOGLE_SERVER_CLIENT_ID must be your Google Cloud Web client ID (…apps.googleusercontent.com), not the Passport OAuth client UUID.';
			case 'login.google_failed': return 'Google sign-in failed. Try again.';
			case 'login.google_channel_restart': return 'Google Sign-In lost connection to Android (often after hot restart). Stop the app completely, then Run again — do not use hot restart.';
			case 'forgot_password.title': return 'Reset\npassword';
			case 'forgot_password.subtitle': return 'Enter your Wayo email. We will send you a 6-digit code.';
			case 'forgot_password.email_label': return 'Email';
			case 'forgot_password.cta': return 'Send code';
			case 'forgot_password.rate_limit_title': return 'Please wait';
			case 'forgot_password.rate_limit_body': return 'Too many password reset requests. Try again shortly.';
			case 'forgot_password.rate_limit_remaining': return ({required Object seconds}) => 'Try again in ${seconds} s';
			case 'otp.title': return 'Verify\nyour email';
			case 'otp.subtitle': return ({required Object email}) => 'Enter the code sent to ${email}';
			case 'otp.resend': return 'Resend code';
			case 'otp.resend_in': return ({required Object seconds}) => 'Resend in ${seconds} s';
			case 'reset_password.title': return 'New\npassword';
			case 'reset_password.subtitle': return 'Choose a strong password (min. 8 characters, 1 uppercase letter, 1 digit).';
			case 'reset_password.new_password': return 'New password';
			case 'reset_password.confirm_password': return 'Confirm password';
			case 'reset_password.cta': return 'Update password';
			case 'reset_password.password_updated': return 'Password updated. You can now sign in.';
			case 'validation.required': return 'Required';
			case 'validation.invalid_email': return 'Invalid email';
			case 'validation.min8': return 'At least 8 characters';
			case 'validation.need_upper': return 'Needs an uppercase letter';
			case 'validation.need_digit': return 'Needs a digit';
			case 'validation.mismatch': return 'Passwords do not match';
			case 'home.title': return 'Wayo Ads';
			case 'home.logout': return 'Log out';
			case 'home.session_title': return 'Active session';
			case 'home.session_hint': return 'Auth_Wayo token stored securely. API calls use Authorization: Bearer automatically.';
			case 'home.user_fallback': return 'User';
			case 'dashboard.title': return 'Dashboard';
			case 'dashboard.welcome': return 'Welcome back, {name}!';
			case 'dashboard.welcome_fallback': return 'Welcome back!';
			case 'dashboard.subtitle': return 'Here\'s your current campaign overview.';
			case 'dashboard.account_creator': return 'Creator account';
			case 'dashboard.account_advertiser': return 'Advertiser account';
			case 'dashboard.coming_soon': return 'Coming soon.';
			case 'dashboard.balance.title': return 'Balance overview';
			case 'dashboard.balance.available': return 'Available';
			case 'dashboard.balance.locked': return 'Locked';
			case 'dashboard.balance.spent': return 'Spent';
			case 'dashboard.campaigns.title': return 'Your Campaigns';
			case 'dashboard.campaigns.subtitle': return 'Manage your campaigns and track their performance.';
			case 'dashboard.campaigns.creators': return '{count} Creators';
			case 'dashboard.campaigns.empty_title': return 'No campaigns';
			case 'dashboard.campaigns.empty_subtitle': return 'Create your first campaign to get started';
			case 'dashboard.campaigns.create_cta': return 'Create Campaign';
			case 'dashboard.errors.load_balance': return 'Couldn\'t load balance';
			case 'dashboard.errors.load_campaigns': return 'Couldn\'t load campaigns';
			case 'dashboard.errors.retry': return 'Retry';
			case 'dashboard.notifications_title': return 'Notifications';
			case 'dashboard.notifications_empty': return 'No notifications';
			case 'dashboard.notification_incoming': return 'New notification';
			case 'dashboard.notification_view': return 'View';
			case 'dashboard.notifications_mark_all_read': return 'Mark all read';
			case 'dashboard.notifications_view_all': return 'View all notifications';
			case 'dashboard.notifications_important': return 'Important';
			case 'dashboard.theme_toggle_tooltip': return 'Switch between light and dark theme';
			case 'dashboard.refresh': return 'Refresh dashboard';
			case 'advertiser_campaigns.title': return 'Campaigns';
			case 'advertiser_campaigns.subtitle': return 'Track your campaign performance — read only.';
			case 'advertiser_campaigns.tabs.active': return 'Active';
			case 'advertiser_campaigns.tabs.paused': return 'Paused';
			case 'advertiser_campaigns.tabs.completed': return 'Completed';
			case 'advertiser_campaigns.search_placeholder': return 'Search campaigns';
			case 'advertiser_campaigns.empty.none': return 'No campaigns found';
			case 'advertiser_campaigns.empty.hint': return 'You don\'t have any campaigns in this status yet.';
			case 'advertiser_campaigns.empty.search': return 'No campaigns match your search';
			case 'advertiser_campaigns.empty.search_hint': return 'Try a different name or clear the search field.';
			case 'advertiser_campaigns.card.budget_total': return 'Budget';
			case 'advertiser_campaigns.card.remaining': return 'Remaining';
			case 'advertiser_campaigns.card.spent': return 'Spent';
			case 'advertiser_campaigns.card.cpc': return 'CPC';
			case 'advertiser_campaigns.card.valid_engagements': return '{count} validated views';
			case 'advertiser_campaigns.status.active': return 'Active';
			case 'advertiser_campaigns.status.paused': return 'Paused';
			case 'advertiser_campaigns.status.completed': return 'Completed';
			case 'advertiser_campaigns.status.draft': return 'Draft';
			case 'advertiser_campaigns.status.other': return 'Other';
			case 'advertiser_campaigns.platform.youtube': return 'YouTube';
			case 'advertiser_campaigns.platform.tiktok': return 'TikTok';
			case 'advertiser_campaigns.platform.instagram': return 'Instagram';
			case 'advertiser_campaigns.platform.other': return 'Platform';
			case 'advertiser_campaigns.detail.fallback_title': return 'Campaign';
			case 'advertiser_campaigns.detail.metrics_title': return 'Performance';
			case 'advertiser_campaigns.detail.valid_views': return 'Validated views';
			case 'advertiser_campaigns.detail.approved_creators': return 'Approved creators';
			case 'nav.dashboard': return 'Dashboard';
			case 'nav.campaigns': return 'Campaigns';
			case 'nav.analytics': return 'Analytics';
			case 'nav.wallet': return 'Wallet';
			case 'nav.chat': return 'Chat';
			case 'chat.inbox_title': return 'Messages';
			case 'chat.inbox_subtitle': return 'Secure conversations for your campaigns';
			case 'chat.conversation_unknown': return 'Conversation';
			case 'chat.thread_fallback_title': return 'Chat';
			case 'chat.composer_hint': return 'Write a message…';
			case 'chat.typing': return 'Typing…';
			case 'chat.error_load_threads': return 'Could not load your conversations. Try again.';
			case 'chat.error_phone': return 'Sharing phone numbers in chat is not allowed.';
			case 'chat.empty_threads_title': return 'No conversations yet';
			case 'chat.empty_threads_hint': return 'When someone messages you about a campaign, it will appear here.';
			case 'chat.online': return 'Online';
			case 'chat.offline': return 'Offline';
			case 'chat.typing_status': return 'Typing…';
			case 'chat.attachment': return 'Attachment';
			case 'chat.attachment_image': return 'Photo';
			case 'chat.attachment_pdf': return 'PDF';
			case 'chat.open_file': return 'Open';
			case 'chat.pick_attachment': return 'Image or PDF';
			case 'chat.upload_failed': return 'Could not send the file. Try again.';
			case 'chat.file_too_large': return 'File is too large (max 10 MB for images, 50 MB for PDF).';
			case 'chat.search_users_hint': return 'Search people by name…';
			case 'chat.search_users_no_results': return 'No users match your search.';
			case 'chat.search_users_min_hint': return 'Type at least 2 characters to search.';
			case 'chat.conversation_open_failed': return 'Could not open that conversation. Try again.';
			case 'chat.file_picker_restart_hint': return 'Attachments need a full app restart after updates. Stop the app, then Run again (avoid hot restart).';
			case 'chat.attachment_type_not_allowed': return 'Only images (JPG, PNG, GIF, WebP, BMP) or PDF are allowed.';
			case 'chat.inbox_swipe_soon': return 'Pin and archive from the list are coming soon.';
			case 'chat.date_today': return 'Today';
			case 'chat.date_yesterday': return 'Yesterday';
			case 'chat.bubble_reply': return 'Reply';
			case 'chat.bubble_copy': return 'Copy';
			case 'chat.bubble_react': return 'React';
			case 'chat.bubble_delete': return 'Delete';
			case 'chat.bubble_update': return 'Edit';
			case 'chat.bubble_delete_unavailable': return 'Deleting messages from the app is not available yet.';
			case 'chat.bubble_copied': return 'Copied to clipboard';
			case 'chat.edited': return 'edited';
			case 'chat.seen': return 'Seen';
			case 'chat.delivered': return 'Delivered';
			case 'chat.edit_mode_title': return 'Editing message';
			case 'chat.edit_mode_cancel': return 'Cancel';
			case 'chat.edit_mode_hint': return 'Update your message…';
			case 'chat.edit_failed': return 'Could not update the message. Try again.';
			case 'chat.edit_not_allowed': return 'Only your own text messages can be edited.';
			case 'chat.delete_failed': return 'Could not delete the message. Try again.';
			case 'chat.delete_not_allowed': return 'You can only delete your own messages.';
			case 'chat.delete_confirm_title': return 'Delete this message?';
			case 'chat.delete_confirm_text': return 'This action cannot be undone.';
			case 'chat.delete_confirm_cta': return 'Delete';
			case 'chat.delete_confirm_cancel': return 'Cancel';
			case 'chat.scroll_to_latest': return 'Latest';
			case 'common.language': return 'Language';
			case 'common.theme': return 'Theme';
			case 'common.light': return 'Light';
			case 'common.dark': return 'Dark';
			case 'common.system': return 'System';
			case 'errors.rate_limited': return 'Too many attempts. Please try again in a few minutes.';
			case 'errors.invalid_credentials': return 'These credentials do not match our records.';
			case 'errors.network': return 'Unable to reach the server. Check your connection.';
			case 'errors.server_generic': return 'Something went wrong. Please try again.';
			case 'errors.empty_response': return 'Empty response from server.';
			case 'errors.login_failed': return 'Login failed.';
			case 'errors.unknown': return 'An unexpected error occurred.';
			case 'errors.session_invalid': return 'Your session has expired. Please sign in again.';
			case 'errors.email_not_found': return 'No account found for this email.';
			case 'privacy_policy.title': return 'Privacy Policy';
			case 'privacy_policy.last_updated': return 'Last updated: October 7, 2025';
			case 'privacy_policy.intro_title': return '1. Introduction';
			case 'privacy_policy.intro_body': return 'At Wayo Ads, we are committed to collecting and using your data responsibly, in compliance with applicable data protection laws, including Moroccan law no. 09-08 and, when applicable, the GDPR (EU 2016/679). By using our platform, you agree to the collection, processing, and use of your data as described in this privacy policy.';
			case 'privacy_policy.data_title': return '2. Data We Collect';
			case 'privacy_policy.data_body': return 'We only collect data that is necessary, in accordance with law 09-08 and, where applicable, the GDPR.\n\nFor advertisers\n• Identification and contact: company name, email address, phone number.\n• Profile: business logo (if provided), company description.\n• Campaigns: campaign content, budgets, targeting criteria, analytics data.\n\nFor creators\n• Identification and contact: name, email address, phone number.\n• Profile: profile photo (if provided), biography, expertise, social media links.\n• Content: videos, posts, and materials you upload.\n• Usage: interactions with the platform, engagement statistics, earnings data.\n\nTechnical information (all users)\n• Technical data: IP address, browser type and version, device type, operating system, session identifiers, timestamps, pages visited, clicks, referrers.\n• Cookies and similar technologies: see section 8 (Cookies).\n\nPayment data\n• Transactions: amounts, currency, date, payment method, billing address.\n• Important: card data is processed exclusively by our payment provider (Stripe). Wayo Ads does not store credit card information.';
			case 'privacy_policy.purpose_title': return '3. Purpose of Using Your Data';
			case 'privacy_policy.purpose_body': return 'We use your data to: provide, maintain, and improve our services; personalize the experience and recommend relevant content; manage contractual relationships (accounts, billing, support); communicate service information (updates, changes, alerts); ensure platform security and integrity (abuse and fraud detection); and perform usage analysis with aggregated or anonymized data whenever possible.';
			case 'privacy_policy.legal_bases_title': return '4. Legal Bases for Processing';
			case 'privacy_policy.legal_bases_body': return 'Depending on the case, we rely on: your consent (for example, non-essential cookies, newsletters); performance of a contract or pre-contractual measures (for example, registration, billing); compliance with a legal obligation (for example, invoice retention); and our legitimate interests (for example, security, service improvement).';
			case 'privacy_policy.sharing_title': return '5. Sharing Your Information';
			case 'privacy_policy.sharing_body': return 'Wayo Ads does not sell your personal data. Limited sharing may occur with: essential service providers (payment processors, hosting providers, emailing tools, analytics); and for legal reasons if required by law or in response to a legitimate request from a competent authority.';
			case 'privacy_policy.security_title': return '6. Data Security';
			case 'privacy_policy.security_body': return 'We apply measures including: TLS/HTTPS encryption for data in transit; access controls based on need-to-know; regular backups and restoration procedures; security updates and periodic audits; and logging and detection of abnormal activities.';
			case 'privacy_policy.content_title': return '7. User Responsibilities and Content Protection';
			case 'privacy_policy.content_body': return 'You must respect the intellectual property rights of creators and Wayo Ads. Do not copy, share, redistribute, or resell content without authorization. Any violation may result in account suspension and, if applicable, legal action.';
			case 'privacy_policy.cookies_title': return '8. Cookies and Tracking Technologies';
			case 'privacy_policy.cookies_body': return 'We use: essential cookies (site functionality, security, session); and analytical cookies (for example, Google Analytics) for audience measurement. Non-essential cookies are only set with your consent via a cookie banner on your first visit.';
			case 'privacy_policy.retention_title': return '9. Data Retention';
			case 'privacy_policy.retention_body': return 'We retain your data only as long as necessary for the purposes outlined in this policy. Account data is retained for the duration of your account plus any legally required retention period. Transaction data is retained in accordance with accounting and tax requirements.';
			case 'privacy_policy.children_title': return '10. Children\'s Privacy';
			case 'privacy_policy.children_body': return 'Our services are not intended for children under 18. We do not knowingly collect personal information from children. If we become aware that we have collected data from a child without parental consent, we will take steps to delete such information.';
			case 'privacy_policy.changes_title': return '11. Changes to This Policy';
			case 'privacy_policy.changes_body': return 'We may update this privacy policy from time to time. We will notify you of any material changes by posting the new policy on this page and updating the "Last updated" date.';
			case 'privacy_policy.contact_title': return '12. Contact Information';
			case 'privacy_policy.contact_body': return 'Data controller: Wayo, Dubai, UAE.\nEmail: info@wayo.cloud\nAddress: R320 Umm Hurair 2, Dubai, UAE.';
			case 'app_settings.title': return 'Preferences';
			case 'app_settings.subtitle': return 'Appearance & language';
			case 'app_settings.section_appearance': return 'Appearance';
			case 'app_settings.section_language': return 'Language';
			case 'app_settings.theme_light': return 'Light';
			case 'app_settings.theme_dark': return 'Dark';
			case 'app_settings.theme_system': return 'System';
			case 'app_settings.theme_hint': return 'Choose how Wayo Ads looks. System follows your device setting.';
			case 'app_settings.language_hint': return 'Interface language. Dates and formats follow the locale.';
			case 'app_settings.design_variant': return 'Panel style';
			case 'app_settings.design_glass': return 'Soft glass';
			case 'app_settings.design_corporate': return 'Corporate';
			case 'app_settings.close': return 'Close';
			case 'app_settings.open_semantics': return 'Open preferences and language';
			case 'app_settings.close_semantics': return 'Close preferences';
			case 'app_settings.profile_fallback': return 'Account';
			case 'app_settings.selected': return 'Selected';
			case 'app_settings.lang_en': return 'English';
			case 'app_settings.lang_fr': return 'Français';
			case 'app_settings.lang_ar': return 'العربية';
			default: return null;
		}
	}
}

