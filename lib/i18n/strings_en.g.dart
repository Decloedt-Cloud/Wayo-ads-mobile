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
	late final TranslationsVerifyEmailEn verify_email = TranslationsVerifyEmailEn.internal(_root);
	late final TranslationsForgotPasswordEn forgot_password = TranslationsForgotPasswordEn.internal(_root);
	late final TranslationsOtpEn otp = TranslationsOtpEn.internal(_root);
	late final TranslationsResetPasswordEn reset_password = TranslationsResetPasswordEn.internal(_root);
	late final TranslationsValidationEn validation = TranslationsValidationEn.internal(_root);
	late final TranslationsHomeEn home = TranslationsHomeEn.internal(_root);
	late final TranslationsDashboardEn dashboard = TranslationsDashboardEn.internal(_root);
	late final TranslationsAdvertiserCampaignsEn advertiser_campaigns = TranslationsAdvertiserCampaignsEn.internal(_root);
	late final TranslationsNavEn nav = TranslationsNavEn.internal(_root);
	late final TranslationsCreatorEn creator = TranslationsCreatorEn.internal(_root);
	late final TranslationsAdvertiserWalletEn advertiser_wallet = TranslationsAdvertiserWalletEn.internal(_root);
	late final TranslationsChatEn chat = TranslationsChatEn.internal(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsPrivacyPolicyEn privacy_policy = TranslationsPrivacyPolicyEn.internal(_root);
	late final TranslationsAppSettingsEn app_settings = TranslationsAppSettingsEn.internal(_root);
	late final TranslationsOnboardingEn onboarding = TranslationsOnboardingEn.internal(_root);
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
	String get headline_brand => 'Wayo Ads';
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
	String get google_android_oauth_misconfigured => 'Google could not verify this app (code 10). In Google Cloud Console, open the same project as your Web client, create an Android OAuth client with package ma.wayo.wayoadsgo and your debug (or release) keystore SHA-1, then wait a few minutes and try again.';
}

// Path: verify_email
class TranslationsVerifyEmailEn {
	TranslationsVerifyEmailEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Confirm your email';
	String get subtitle => 'Wayo ID needs a verified address (same step as on the website). Open the link we sent to:';
	String get check_again => 'I\'ve confirmed — continue';
	String get open_mail => 'Open email app';
	String get still_pending => 'Still waiting for verification. Check your inbox or spam, then try again.';
	String get open_mail_failed => 'Could not open the email app.';
	String get sign_out => 'Sign out';
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
	String get application_approve => 'Approve';
	String get application_reject => 'Reject';
	String get application_approved => 'Application approved';
	String get application_rejected => 'Application rejected';
	String get application_action_failed => 'Could not update the application. Try again.';
	String get theme_toggle_tooltip => 'Switch between light and dark theme';
	String get refresh => 'Refresh dashboard';
	String get shell_tour_restart => 'Restart onboarding tour';
	String get shell_tour_restart_hint => 'Replay the guided tour of Dashboard, Campaigns, Wallet and Chat navigation';
}

// Path: advertiser_campaigns
class TranslationsAdvertiserCampaignsEn {
	TranslationsAdvertiserCampaignsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Campaigns';
	String get subtitle => 'Create draft campaigns, track performance, and review creator applications.';
	late final TranslationsAdvertiserCampaignsTabsEn tabs = TranslationsAdvertiserCampaignsTabsEn.internal(_root);
	String get search_placeholder => 'Search campaigns';
	late final TranslationsAdvertiserCampaignsEmptyEn empty = TranslationsAdvertiserCampaignsEmptyEn.internal(_root);
	late final TranslationsAdvertiserCampaignsCardEn card = TranslationsAdvertiserCampaignsCardEn.internal(_root);
	late final TranslationsAdvertiserCampaignsStatusEn status = TranslationsAdvertiserCampaignsStatusEn.internal(_root);
	late final TranslationsAdvertiserCampaignsPlatformEn platform = TranslationsAdvertiserCampaignsPlatformEn.internal(_root);
	late final TranslationsAdvertiserCampaignsDetailEn detail = TranslationsAdvertiserCampaignsDetailEn.internal(_root);
	late final TranslationsAdvertiserCampaignsCreateEn create = TranslationsAdvertiserCampaignsCreateEn.internal(_root);
	late final TranslationsAdvertiserCampaignsApplicationsEn applications = TranslationsAdvertiserCampaignsApplicationsEn.internal(_root);
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

// Path: creator
class TranslationsCreatorEn {
	TranslationsCreatorEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsCreatorDashboardEn dashboard = TranslationsCreatorDashboardEn.internal(_root);
	late final TranslationsCreatorWalletEn wallet = TranslationsCreatorWalletEn.internal(_root);
	late final TranslationsCreatorCampaignsEn campaigns = TranslationsCreatorCampaignsEn.internal(_root);
	late final TranslationsCreatorStatsEn stats = TranslationsCreatorStatsEn.internal(_root);
	late final TranslationsCreatorApplicationsEn applications = TranslationsCreatorApplicationsEn.internal(_root);
	late final TranslationsCreatorBusinessEn business = TranslationsCreatorBusinessEn.internal(_root);
}

// Path: advertiser_wallet
class TranslationsAdvertiserWalletEn {
	TranslationsAdvertiserWalletEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get hero_title => 'Your balance';
	String get hero_subtitle => 'Add funds to run campaigns. Payments are processed securely by Stripe. Apple Pay (iOS) and Google Pay (Android) are available when supported.';
	String get available => 'Available';
	String get pending => 'Pending';
	String get add_funds => 'Add funds';
	String get amount_label => 'Amount';
	String get quick_50 => '€50';
	String get quick_100 => '€100';
	String get quick_250 => '€250';
	String get min_deposit => 'Minimum deposit is 50.00 in your currency.';
	String get test_pay => 'Simulate payment (dev)';
	String get test_hint => 'Test mode: no real card. Tops up your dev wallet for QA.';
	String get pay_secure => 'Pay with card, Apple Pay or Google Pay';
	String get pay_with_card => 'Pay with card';
	String get pay_with_apple => 'Pay with Apple Pay';
	String get pay_with_google => 'Pay with Google Pay';
	String get or => 'or';
	String get stripe_unavailable => 'Top-ups are not available: payment is not configured on the server.';
	String get tx_title => 'Recent activity';
	String get tx_empty => 'No transactions yet';
	String get tx_deposit => 'Deposit';
	String get tx_withdrawal => 'Withdrawal';
	String get tx_other => 'Transaction';
	String get success => 'Balance updated';
	String get failed => 'Could not add funds. Try again.';
	String get in_progress => 'Processing…';
	String tx_page({required Object current, required Object total}) => 'Page ${current} of ${total}';
	String get tx_prev => 'Previous';
	String get tx_next => 'Next';
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
	String get search_prior_chats_hint => 'Search people you\'ve messaged…';
	String get search_prior_chats_no_results => 'No one in your conversations matches.';
	String get search_prior_chats_min_hint => 'Type at least 2 characters.';
	String get conversation_open_failed => 'Could not open that conversation. Try again.';
	String get file_picker_restart_hint => 'Attachments need a full app restart after updates. Stop the app, then Run again (avoid hot restart).';
	String get attachment_type_not_allowed => 'Only images (JPG, PNG, GIF, WebP, BMP) or PDF are allowed.';
	String get inbox_swipe_soon => 'Pin and archive from the list are coming soon.';
	String get date_today => 'Today';
	String get date_yesterday => 'Yesterday';
	String get bubble_reply => 'Reply';
	String get reply_composer_title => 'Reply';
	String get reply_composer_you => 'You';
	String get composer_reply_hint => 'Write a reply…';
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

// Path: onboarding
class TranslationsOnboardingEn {
	TranslationsOnboardingEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get role_gate_title => 'Choose your profile';
	String get role_gate_subtitle => 'Same step as on the Wayo Ads website before you can use the app.';
	String get role_creator_cta => 'Creator';
	String get role_creator_desc => 'Browse campaigns, apply, and collaborate with brands.';
	String get role_advertiser_cta => 'Advertiser';
	String get role_advertiser_desc => 'Launch campaigns and manage creators from your dashboard.';
	String get email_code_title => 'Verify your email';
	String email_code_subtitle({required Object email}) => 'Enter the 6-digit code we sent to ${email}.';
	String get skip => 'Skip';
	String get next => 'Next';
	String get done => 'Got it';
	late final TranslationsOnboardingAdvertiserEn advertiser = TranslationsOnboardingAdvertiserEn.internal(_root);
	late final TranslationsOnboardingCreatorEn creator = TranslationsOnboardingCreatorEn.internal(_root);
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
	String get pagination_previous => 'Previous';
	String get pagination_next => 'Next';
	String pagination_page({required Object current, required Object total}) => 'Page ${current} / ${total}';
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
	String get draft => 'Draft';
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
	String get locked => 'Locked';
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
	String get valid_clicks => 'Valid clicks';
	String get approved_creators => 'Approved creators';
	String get platform_label => 'Platform';
	String get campaign_type_label => 'Campaign type';
	String get niche_label => 'Niche';
	String get objective_label => 'Objective';
	String get objective_awareness => 'Awareness';
	String get objective_traffic => 'Traffic';
	String get objective_conversion => 'Conversion';
	String get cpm_metric => 'CPM (per 1k views)';
	String get cpc_metric => 'CPC (per click)';
}

// Path: advertiser_campaigns.create
class TranslationsAdvertiserCampaignsCreateEn {
	TranslationsAdvertiserCampaignsCreateEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'New campaign';
	String get section_basics => 'Basics';
	String get section_budget => 'Budget & rates';
	String get field_type => 'Campaign type';
	String get field_objective => 'Campaign objective';
	String get field_niche => 'Industry niche';
	String get field_title => 'Title';
	String get field_description => 'Description (optional)';
	String get field_landing => 'Landing page URL';
	String get field_assets => 'Brief / assets link';
	String get field_budget => 'Total budget';
	String get field_cpm_hint => 'CPM — cost per 1,000 impressions (¢)';
	String get field_cpc_hint => 'CPC — cost per click (¢)';
	String get field_video_min_duration => 'Minimum video length (minutes)';
	String get field_shorts_max_duration => 'Max shorts length (seconds)';
	String get type_link => 'Link';
	String get type_video => 'Video';
	String get type_shorts => 'Shorts';
	String get landing_help => 'Required for link campaigns (https).';
	String get assets_help => 'Video & shorts require a Drive, OneDrive, or SharePoint https link.';
	String get submit_draft => 'Save as draft';
	String get validation_title => 'Check the highlighted fields.';
	String get assets_url_invalid => 'Use an https Google Drive, OneDrive, or SharePoint URL.';
	String get success => 'Draft campaign created';
	String get submit_in_progress => 'Saving…';
}

// Path: advertiser_campaigns.applications
class TranslationsAdvertiserCampaignsApplicationsEn {
	TranslationsAdvertiserCampaignsApplicationsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Creator Applications';
	String pending_badge({required Object count}) => '${count} pending';
	String get subtitle => 'Review and approve or reject creator applications';
	String get empty_title => 'No applications yet';
	String get empty_subtitle => 'When creators apply to this campaign, they will appear here.';
	String get load_error => 'Could not load applications';
	String trust_score({required Object score}) => 'Trust: ${score}';
	String get approve_button => 'Approve';
	String get reject_button => 'Reject';
	String get approved_status => 'Approved';
	String get rejected_status => 'Rejected';
}

// Path: creator.dashboard
class TranslationsCreatorDashboardEn {
	TranslationsCreatorDashboardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Creator Studio';
	String get subtitle => 'Track your stats, applications and earnings in real time.';
	String get coming_soon_title => 'Your creator dashboard';
	String get coming_soon_subtitle => 'Stats, analytics and active applications will appear here. Real-time updates are wired up — no refresh needed.';
}

// Path: creator.wallet
class TranslationsCreatorWalletEn {
	TranslationsCreatorWalletEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get coming_soon_title => 'Your earnings';
	String get coming_soon_subtitle => 'Available balance, pending payouts and Stripe payout history will show up here.';
	String get connect_stripe_title => 'Connect Stripe';
	String get connect_stripe_subtitle => 'Link your bank account securely via Stripe to enable payouts. We never store your financial details.';
	String get withdraw_title => 'Request a payout';
	String get withdraw_subtitle => 'Withdraw your available balance to your connected Stripe account.';
	String get available_balance => 'Available';
	String get pending_balance => 'Pending';
	String get total_earned => 'Total earned';
	String get load_error => 'Couldn\'t load your wallet';
	String get withdraw_button => 'Withdraw';
	String get withdraw_sheet_title => 'Request a payout';
	String get withdraw_sheet_subtitle => 'Available balance: {available}. Funds will be sent to your connected Stripe account.';
	String get withdraw_amount_label => 'Amount';
	String get withdraw_submit => 'Confirm withdrawal';
	String get withdraw_submitting => 'Processing…';
	String get withdraw_max => 'Max';
	String get withdraw_success => 'Withdrawal request submitted.';
	String get withdraw_secure_footer => 'Secure payout — processed by Stripe. We never see your bank details.';
	String get withdraw_error_invalid => 'Enter a valid amount.';
	String get withdraw_error_min => 'Minimum withdrawal is {min}.';
	String get withdraw_error_insufficient => 'Insufficient available balance.';
	String get withdraw_reason_business_info => 'Finalize your business information before connecting a payout account.';
	String get withdraw_reason_stripe => 'Connect Stripe to enable withdrawals.';
	String get withdraw_reason_stripe_incomplete => 'Finish Stripe onboarding to enable withdrawals.';
	String get withdraw_reason_payouts_disabled => 'Your Stripe account isn\'t cleared for payouts yet.';
	String get withdraw_reason_below_min => 'Minimum withdrawal is {min}.';
	String get cancel_action => 'Cancel request';
	String get cancel_in_progress => 'Cancelling…';
	String get cancel_dialog_title => 'Cancel this withdrawal?';
	String get cancel_dialog_message => 'The pending payout will be cancelled and the funds returned to your available balance.';
	String get cancel_dialog_yes => 'Cancel withdrawal';
	String get cancel_dialog_no => 'Keep it';
	String get cancel_success => 'Withdrawal cancelled and funds restored.';
	String get stripe_connected => 'Connected';
	String get stripe_onboarding_required_pill => 'Action required';
	String get stripe_connect_action => 'Connect Stripe';
	String get stripe_complete_action => 'Finish onboarding';
	String get stripe_open_dashboard => 'Open Stripe dashboard';
	String get stripe_error => 'Something went wrong with Stripe. Please try again.';
	String get stripe_card_title_disconnected => 'Connect Stripe';
	String get stripe_card_subtitle_disconnected => 'Link your bank account securely via Stripe to receive payouts.';
	String get stripe_card_title_incomplete => 'Finish your onboarding';
	String get stripe_card_subtitle_incomplete => 'Stripe still needs a few details before payouts can be enabled.';
	String get stripe_card_title_connected => 'Stripe is connected';
	String get stripe_card_subtitle_connected => 'Your Stripe Express account is active. Payouts land in your bank.';
	String get history_title => 'Payout history';
	String get history_empty => 'No withdrawals yet — they will appear here.';
	String get history_load_error => 'Couldn\'t load your payout history.';
	String get history_status_pending => 'Pending';
	String get history_status_processing => 'Processing';
	String get history_status_succeeded => 'Paid';
	String get history_status_failed => 'Failed';
	String get history_status_cancelled => 'Cancelled';
	String get conditions_title => 'Withdrawal conditions';
	String get conditions_subtitle => 'Good to know before you request a payout.';
	String get conditions_min_label => 'Minimum withdrawal';
	String get conditions_fee_label => 'Fee';
	String conditions_fee_value({required Object percent}) => '${percent} (ex VAT)';
	String get conditions_processing_label => 'Processing time';
	String get conditions_processing_value => '2–5 business days';
}

// Path: creator.campaigns
class TranslationsCreatorCampaignsEn {
	TranslationsCreatorCampaignsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get browse_title => 'Browse campaigns';
	String get browse_subtitle => 'Find campaigns that match your audience and apply in one tap.';
	String get browse_search_placeholder => 'Search by name, type or brand';
	String get browse_empty_search_title => 'No matching campaigns';
	String get browse_empty_search_subtitle => 'Try another keyword — name, type (video, shorts, link) or advertiser brand.';
	String get applications_title => 'My applications';
	String get applications_subtitle => 'Track the status of campaigns you\'ve applied to — approved, pending or rejected.';
	String get submit_title => 'Submit a post';
	String get submit_subtitle => 'Once approved, share a public video URL so the advertiser can review it.';
	String get details_title => 'Campaign details';
	String get application_title => 'My application';
	String get load_error => 'Couldn\'t load campaigns.';
	String get empty_title => 'No campaigns right now';
	String get empty_subtitle => 'New campaigns show up here the moment advertisers launch them.';
	String get pagination_previous => 'Previous';
	String get pagination_next => 'Next';
	String pagination_page({required Object current, required Object total}) => 'Page ${current} / ${total}';
	String get description_title => 'Brief';
	String get requirements_title => 'Requirements';
	String get assets_title => 'Brand assets';
	String get assets_subtitle => 'Download the brief, logos and footage.';
	String get type_link => 'Link';
	String get type_video => 'Video';
	String get type_shorts => 'Shorts';
	String get reward_cpm_label => 'CPM';
	String get reward_cpc_label => 'Payout per click';
	String get reward_per_view_label => 'Payout per view';
	String reward_per_view({required Object amount}) => '${amount} / view';
	String reward_per_click({required Object amount}) => '${amount} / click';
	String get budget_remaining_label => 'Remaining budget';
	String requirement_platform({required Object platform}) => 'Post on ${platform} only';
	String requirement_min_duration({required Object minutes}) => 'Minimum duration: ${minutes} min';
	String requirement_shorts_max({required Object seconds}) => 'Shorts up to ${seconds} s';
	String get requirement_vertical => 'Vertical format (9:16) required';
	String get requirement_none => 'No specific requirements.';
	String get apply_cta => 'Apply to this campaign';
	String get apply_title => 'Apply';
	String get apply_message_label => 'Pitch (optional)';
	String get apply_message_hint => 'Tell the advertiser why you\'re a great fit…';
	String get apply_submit => 'Send application';
	String get apply_in_progress => 'Sending…';
	String get apply_error => 'Could not send your application. Please try again.';
	String get apply_success => 'Application sent — you\'ll be notified when it\'s reviewed.';
	String get apply_pending_title => 'Application under review';
	String get apply_pending_subtitle => 'We\'ll notify you the moment the advertiser responds.';
	String get open_application_cta => 'Open my application';
	String get chat_with_advertiser => 'Chat with advertiser';
	String get status_banner_approved_title => 'You\'re approved!';
	String get status_banner_approved_subtitle => 'You can now submit your video and chat with the advertiser.';
	String get status_banner_pending_title => 'Waiting on advertiser';
	String get status_banner_pending_subtitle => 'Your pitch is in review — we\'ll ping you here when it\'s decided.';
	String get status_banner_rejected_title => 'Not selected this time';
	String get status_banner_rejected_subtitle => 'Keep an eye on the Campaigns tab — new briefs ship every week.';
	String get my_submissions_title => 'My submissions';
	String get my_submissions_empty_approved => 'No video submitted yet. Upload one to start earning.';
	String get my_submissions_empty_pending => 'Submissions unlock once your application is approved.';
	String get submit_cta => 'Submit a post';
	String get submit_platform_label => 'Platform';
	String get submit_url_label => 'Public video URL';
	String get submit_url_hint => 'https://youtube.com/watch?v=…';
	String get submit_url_required => 'Please paste the video URL.';
	String get submit_url_invalid => 'Enter a valid public URL.';
	String get submit_url_youtube_only => 'Only YouTube URLs are supported right now.';
	String get submit_in_progress => 'Submitting…';
	String get submit_footer => 'Your video stays public during the campaign so we can validate views.';
	String get submit_error => 'Could not submit your video. Please try again.';
	String get submit_success => 'Video submitted — advertiser will review it shortly.';
	String get submit_blocked_limit => 'You\'ve already submitted for this campaign. Wait for the review.';
	String get submission_status_pending => 'In review';
	String get submission_status_approved => 'Approved';
	String get submission_status_rejected => 'Rejected';
	String get submission_status_flagged => 'Flagged';
	String submission_views({required Object views}) => '${views} validated views';
}

// Path: creator.stats
class TranslationsCreatorStatsEn {
	TranslationsCreatorStatsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get earnings_title => 'Total earnings';
	String get pending => 'Pending';
	String get validated_views => 'Validated views';
	String get validation_rate => 'Validation rate';
	String get approved_campaigns => 'Approved campaigns';
}

// Path: creator.applications
class TranslationsCreatorApplicationsEn {
	TranslationsCreatorApplicationsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get section_title => 'Active applications';
	String get empty_title => 'No applications yet';
	String get empty_subtitle => 'Browse the Campaigns tab and apply to the ones that match your audience.';
	String get load_error => 'Couldn\'t load your applications';
	String get status_pending => 'Pending';
	String get status_approved => 'Approved';
	String get status_rejected => 'Rejected';
	String get status_withdrawn => 'Withdrawn';
	String get status_unknown => '—';
}

// Path: creator.business
class TranslationsCreatorBusinessEn {
	TranslationsCreatorBusinessEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get cta_title => 'Finalize your business information';
	String get cta_subtitle => 'Required before connecting your bank account so we can route your payouts correctly.';
	String get cta_required_pill => 'REQUIRED';
	String get cta_button => 'Finalize your Business Information';
	String get dialog_title => 'Business information';
	String get dialog_subtitle => 'Provide a few legal details so Stripe can onboard your account and settle payouts.';
	String get section_type => 'Account type';
	String get section_company => 'Company';
	String get section_address => 'Address';
	String get section_stripe => 'Payout country & currency';
	String get type_personal_title => 'Individual';
	String get type_personal_subtitle => 'I receive payouts as a private person.';
	String get type_sole_title => 'Sole proprietor';
	String get type_sole_subtitle => 'I run my own freelance business.';
	String get type_company_title => 'Registered company';
	String get type_company_subtitle => 'I operate under a registered legal entity.';
	String get company_name => 'Company name';
	String get vat_number => 'VAT number';
	String get address_line1 => 'Address line 1';
	String get address_line2 => 'Address line 2 (optional)';
	String get city => 'City';
	String get postal_code => 'Postal code';
	String get state_region => 'State / Region (optional)';
	String get country => 'Country';
	String get currency => 'Payout currency';
	String get error_required => 'Required';
	String get save_and_continue => 'Save & continue';
	String get submitting => 'Saving…';
	String get footer_info => 'This information is shared with Stripe to enable your payout account. We never see your banking details.';
	String get save_error => 'We couldn\'t save your business info. Please try again.';
}

// Path: onboarding.advertiser
class TranslationsOnboardingAdvertiserEn {
	TranslationsOnboardingAdvertiserEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get dashboard_title => 'Your dashboard';
	String get dashboard_subtitle => 'Track balance, active campaigns and notifications — all updates land here in real time.';
	String get campaigns_title => 'Campaigns';
	String get campaigns_subtitle => 'Create new campaigns, review applications and monitor performance in one place.';
	String get wallet_title => 'Wallet';
	String get wallet_subtitle => 'Top up your budget, view invoices and spending history — secured by Stripe.';
	String get chat_title => 'Chat';
	String get chat_subtitle => 'Talk to your creators once a campaign is approved. Conversations stay in sync across devices.';
}

// Path: onboarding.creator
class TranslationsOnboardingCreatorEn {
	TranslationsOnboardingCreatorEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get dashboard_title => 'Creator dashboard';
	String get dashboard_subtitle => 'Your KPIs, active applications and earnings refresh automatically — no need to pull to refresh.';
	String get campaigns_title => 'Browse & apply';
	String get campaigns_subtitle => 'Discover eligible campaigns, apply in one tap and follow your application status live.';
	String get wallet_title => 'Earnings & payouts';
	String get wallet_subtitle => 'See your balance, request payouts via Stripe Connect and review past withdrawals.';
	String get chat_title => 'Talk to advertisers';
	String get chat_subtitle => 'Once approved, the chat opens with your advertiser to align on deliverables.';
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
			case 'login.headline_brand': return 'Wayo Ads';
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
			case 'login.google_android_oauth_misconfigured': return 'Google could not verify this app (code 10). In Google Cloud Console, open the same project as your Web client, create an Android OAuth client with package ma.wayo.wayoadsgo and your debug (or release) keystore SHA-1, then wait a few minutes and try again.';
			case 'verify_email.title': return 'Confirm your email';
			case 'verify_email.subtitle': return 'Wayo ID needs a verified address (same step as on the website). Open the link we sent to:';
			case 'verify_email.check_again': return 'I\'ve confirmed — continue';
			case 'verify_email.open_mail': return 'Open email app';
			case 'verify_email.still_pending': return 'Still waiting for verification. Check your inbox or spam, then try again.';
			case 'verify_email.open_mail_failed': return 'Could not open the email app.';
			case 'verify_email.sign_out': return 'Sign out';
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
			case 'dashboard.campaigns.pagination_previous': return 'Previous';
			case 'dashboard.campaigns.pagination_next': return 'Next';
			case 'dashboard.campaigns.pagination_page': return ({required Object current, required Object total}) => 'Page ${current} / ${total}';
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
			case 'dashboard.application_approve': return 'Approve';
			case 'dashboard.application_reject': return 'Reject';
			case 'dashboard.application_approved': return 'Application approved';
			case 'dashboard.application_rejected': return 'Application rejected';
			case 'dashboard.application_action_failed': return 'Could not update the application. Try again.';
			case 'dashboard.theme_toggle_tooltip': return 'Switch between light and dark theme';
			case 'dashboard.refresh': return 'Refresh dashboard';
			case 'dashboard.shell_tour_restart': return 'Restart onboarding tour';
			case 'dashboard.shell_tour_restart_hint': return 'Replay the guided tour of Dashboard, Campaigns, Wallet and Chat navigation';
			case 'advertiser_campaigns.title': return 'Campaigns';
			case 'advertiser_campaigns.subtitle': return 'Create draft campaigns, track performance, and review creator applications.';
			case 'advertiser_campaigns.tabs.active': return 'Active';
			case 'advertiser_campaigns.tabs.draft': return 'Draft';
			case 'advertiser_campaigns.tabs.paused': return 'Paused';
			case 'advertiser_campaigns.tabs.completed': return 'Completed';
			case 'advertiser_campaigns.search_placeholder': return 'Search campaigns';
			case 'advertiser_campaigns.empty.none': return 'No campaigns found';
			case 'advertiser_campaigns.empty.hint': return 'You don\'t have any campaigns in this status yet.';
			case 'advertiser_campaigns.empty.search': return 'No campaigns match your search';
			case 'advertiser_campaigns.empty.search_hint': return 'Try a different name or clear the search field.';
			case 'advertiser_campaigns.card.budget_total': return 'Budget';
			case 'advertiser_campaigns.card.remaining': return 'Remaining';
			case 'advertiser_campaigns.card.locked': return 'Locked';
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
			case 'advertiser_campaigns.detail.valid_clicks': return 'Valid clicks';
			case 'advertiser_campaigns.detail.approved_creators': return 'Approved creators';
			case 'advertiser_campaigns.detail.platform_label': return 'Platform';
			case 'advertiser_campaigns.detail.campaign_type_label': return 'Campaign type';
			case 'advertiser_campaigns.detail.niche_label': return 'Niche';
			case 'advertiser_campaigns.detail.objective_label': return 'Objective';
			case 'advertiser_campaigns.detail.objective_awareness': return 'Awareness';
			case 'advertiser_campaigns.detail.objective_traffic': return 'Traffic';
			case 'advertiser_campaigns.detail.objective_conversion': return 'Conversion';
			case 'advertiser_campaigns.detail.cpm_metric': return 'CPM (per 1k views)';
			case 'advertiser_campaigns.detail.cpc_metric': return 'CPC (per click)';
			case 'advertiser_campaigns.create.title': return 'New campaign';
			case 'advertiser_campaigns.create.section_basics': return 'Basics';
			case 'advertiser_campaigns.create.section_budget': return 'Budget & rates';
			case 'advertiser_campaigns.create.field_type': return 'Campaign type';
			case 'advertiser_campaigns.create.field_objective': return 'Campaign objective';
			case 'advertiser_campaigns.create.field_niche': return 'Industry niche';
			case 'advertiser_campaigns.create.field_title': return 'Title';
			case 'advertiser_campaigns.create.field_description': return 'Description (optional)';
			case 'advertiser_campaigns.create.field_landing': return 'Landing page URL';
			case 'advertiser_campaigns.create.field_assets': return 'Brief / assets link';
			case 'advertiser_campaigns.create.field_budget': return 'Total budget';
			case 'advertiser_campaigns.create.field_cpm_hint': return 'CPM — cost per 1,000 impressions (¢)';
			case 'advertiser_campaigns.create.field_cpc_hint': return 'CPC — cost per click (¢)';
			case 'advertiser_campaigns.create.field_video_min_duration': return 'Minimum video length (minutes)';
			case 'advertiser_campaigns.create.field_shorts_max_duration': return 'Max shorts length (seconds)';
			case 'advertiser_campaigns.create.type_link': return 'Link';
			case 'advertiser_campaigns.create.type_video': return 'Video';
			case 'advertiser_campaigns.create.type_shorts': return 'Shorts';
			case 'advertiser_campaigns.create.landing_help': return 'Required for link campaigns (https).';
			case 'advertiser_campaigns.create.assets_help': return 'Video & shorts require a Drive, OneDrive, or SharePoint https link.';
			case 'advertiser_campaigns.create.submit_draft': return 'Save as draft';
			case 'advertiser_campaigns.create.validation_title': return 'Check the highlighted fields.';
			case 'advertiser_campaigns.create.assets_url_invalid': return 'Use an https Google Drive, OneDrive, or SharePoint URL.';
			case 'advertiser_campaigns.create.success': return 'Draft campaign created';
			case 'advertiser_campaigns.create.submit_in_progress': return 'Saving…';
			case 'advertiser_campaigns.applications.title': return 'Creator Applications';
			case 'advertiser_campaigns.applications.pending_badge': return ({required Object count}) => '${count} pending';
			case 'advertiser_campaigns.applications.subtitle': return 'Review and approve or reject creator applications';
			case 'advertiser_campaigns.applications.empty_title': return 'No applications yet';
			case 'advertiser_campaigns.applications.empty_subtitle': return 'When creators apply to this campaign, they will appear here.';
			case 'advertiser_campaigns.applications.load_error': return 'Could not load applications';
			case 'advertiser_campaigns.applications.trust_score': return ({required Object score}) => 'Trust: ${score}';
			case 'advertiser_campaigns.applications.approve_button': return 'Approve';
			case 'advertiser_campaigns.applications.reject_button': return 'Reject';
			case 'advertiser_campaigns.applications.approved_status': return 'Approved';
			case 'advertiser_campaigns.applications.rejected_status': return 'Rejected';
			case 'nav.dashboard': return 'Dashboard';
			case 'nav.campaigns': return 'Campaigns';
			case 'nav.analytics': return 'Analytics';
			case 'nav.wallet': return 'Wallet';
			case 'nav.chat': return 'Chat';
			case 'creator.dashboard.title': return 'Creator Studio';
			case 'creator.dashboard.subtitle': return 'Track your stats, applications and earnings in real time.';
			case 'creator.dashboard.coming_soon_title': return 'Your creator dashboard';
			case 'creator.dashboard.coming_soon_subtitle': return 'Stats, analytics and active applications will appear here. Real-time updates are wired up — no refresh needed.';
			case 'creator.wallet.coming_soon_title': return 'Your earnings';
			case 'creator.wallet.coming_soon_subtitle': return 'Available balance, pending payouts and Stripe payout history will show up here.';
			case 'creator.wallet.connect_stripe_title': return 'Connect Stripe';
			case 'creator.wallet.connect_stripe_subtitle': return 'Link your bank account securely via Stripe to enable payouts. We never store your financial details.';
			case 'creator.wallet.withdraw_title': return 'Request a payout';
			case 'creator.wallet.withdraw_subtitle': return 'Withdraw your available balance to your connected Stripe account.';
			case 'creator.wallet.available_balance': return 'Available';
			case 'creator.wallet.pending_balance': return 'Pending';
			case 'creator.wallet.total_earned': return 'Total earned';
			case 'creator.wallet.load_error': return 'Couldn\'t load your wallet';
			case 'creator.wallet.withdraw_button': return 'Withdraw';
			case 'creator.wallet.withdraw_sheet_title': return 'Request a payout';
			case 'creator.wallet.withdraw_sheet_subtitle': return 'Available balance: {available}. Funds will be sent to your connected Stripe account.';
			case 'creator.wallet.withdraw_amount_label': return 'Amount';
			case 'creator.wallet.withdraw_submit': return 'Confirm withdrawal';
			case 'creator.wallet.withdraw_submitting': return 'Processing…';
			case 'creator.wallet.withdraw_max': return 'Max';
			case 'creator.wallet.withdraw_success': return 'Withdrawal request submitted.';
			case 'creator.wallet.withdraw_secure_footer': return 'Secure payout — processed by Stripe. We never see your bank details.';
			case 'creator.wallet.withdraw_error_invalid': return 'Enter a valid amount.';
			case 'creator.wallet.withdraw_error_min': return 'Minimum withdrawal is {min}.';
			case 'creator.wallet.withdraw_error_insufficient': return 'Insufficient available balance.';
			case 'creator.wallet.withdraw_reason_business_info': return 'Finalize your business information before connecting a payout account.';
			case 'creator.wallet.withdraw_reason_stripe': return 'Connect Stripe to enable withdrawals.';
			case 'creator.wallet.withdraw_reason_stripe_incomplete': return 'Finish Stripe onboarding to enable withdrawals.';
			case 'creator.wallet.withdraw_reason_payouts_disabled': return 'Your Stripe account isn\'t cleared for payouts yet.';
			case 'creator.wallet.withdraw_reason_below_min': return 'Minimum withdrawal is {min}.';
			case 'creator.wallet.cancel_action': return 'Cancel request';
			case 'creator.wallet.cancel_in_progress': return 'Cancelling…';
			case 'creator.wallet.cancel_dialog_title': return 'Cancel this withdrawal?';
			case 'creator.wallet.cancel_dialog_message': return 'The pending payout will be cancelled and the funds returned to your available balance.';
			case 'creator.wallet.cancel_dialog_yes': return 'Cancel withdrawal';
			case 'creator.wallet.cancel_dialog_no': return 'Keep it';
			case 'creator.wallet.cancel_success': return 'Withdrawal cancelled and funds restored.';
			case 'creator.wallet.stripe_connected': return 'Connected';
			case 'creator.wallet.stripe_onboarding_required_pill': return 'Action required';
			case 'creator.wallet.stripe_connect_action': return 'Connect Stripe';
			case 'creator.wallet.stripe_complete_action': return 'Finish onboarding';
			case 'creator.wallet.stripe_open_dashboard': return 'Open Stripe dashboard';
			case 'creator.wallet.stripe_error': return 'Something went wrong with Stripe. Please try again.';
			case 'creator.wallet.stripe_card_title_disconnected': return 'Connect Stripe';
			case 'creator.wallet.stripe_card_subtitle_disconnected': return 'Link your bank account securely via Stripe to receive payouts.';
			case 'creator.wallet.stripe_card_title_incomplete': return 'Finish your onboarding';
			case 'creator.wallet.stripe_card_subtitle_incomplete': return 'Stripe still needs a few details before payouts can be enabled.';
			case 'creator.wallet.stripe_card_title_connected': return 'Stripe is connected';
			case 'creator.wallet.stripe_card_subtitle_connected': return 'Your Stripe Express account is active. Payouts land in your bank.';
			case 'creator.wallet.history_title': return 'Payout history';
			case 'creator.wallet.history_empty': return 'No withdrawals yet — they will appear here.';
			case 'creator.wallet.history_load_error': return 'Couldn\'t load your payout history.';
			case 'creator.wallet.history_status_pending': return 'Pending';
			case 'creator.wallet.history_status_processing': return 'Processing';
			case 'creator.wallet.history_status_succeeded': return 'Paid';
			case 'creator.wallet.history_status_failed': return 'Failed';
			case 'creator.wallet.history_status_cancelled': return 'Cancelled';
			case 'creator.wallet.conditions_title': return 'Withdrawal conditions';
			case 'creator.wallet.conditions_subtitle': return 'Good to know before you request a payout.';
			case 'creator.wallet.conditions_min_label': return 'Minimum withdrawal';
			case 'creator.wallet.conditions_fee_label': return 'Fee';
			case 'creator.wallet.conditions_fee_value': return ({required Object percent}) => '${percent} (ex VAT)';
			case 'creator.wallet.conditions_processing_label': return 'Processing time';
			case 'creator.wallet.conditions_processing_value': return '2–5 business days';
			case 'creator.campaigns.browse_title': return 'Browse campaigns';
			case 'creator.campaigns.browse_subtitle': return 'Find campaigns that match your audience and apply in one tap.';
			case 'creator.campaigns.browse_search_placeholder': return 'Search by name, type or brand';
			case 'creator.campaigns.browse_empty_search_title': return 'No matching campaigns';
			case 'creator.campaigns.browse_empty_search_subtitle': return 'Try another keyword — name, type (video, shorts, link) or advertiser brand.';
			case 'creator.campaigns.applications_title': return 'My applications';
			case 'creator.campaigns.applications_subtitle': return 'Track the status of campaigns you\'ve applied to — approved, pending or rejected.';
			case 'creator.campaigns.submit_title': return 'Submit a post';
			case 'creator.campaigns.submit_subtitle': return 'Once approved, share a public video URL so the advertiser can review it.';
			case 'creator.campaigns.details_title': return 'Campaign details';
			case 'creator.campaigns.application_title': return 'My application';
			case 'creator.campaigns.load_error': return 'Couldn\'t load campaigns.';
			case 'creator.campaigns.empty_title': return 'No campaigns right now';
			case 'creator.campaigns.empty_subtitle': return 'New campaigns show up here the moment advertisers launch them.';
			case 'creator.campaigns.pagination_previous': return 'Previous';
			case 'creator.campaigns.pagination_next': return 'Next';
			case 'creator.campaigns.pagination_page': return ({required Object current, required Object total}) => 'Page ${current} / ${total}';
			case 'creator.campaigns.description_title': return 'Brief';
			case 'creator.campaigns.requirements_title': return 'Requirements';
			case 'creator.campaigns.assets_title': return 'Brand assets';
			case 'creator.campaigns.assets_subtitle': return 'Download the brief, logos and footage.';
			case 'creator.campaigns.type_link': return 'Link';
			case 'creator.campaigns.type_video': return 'Video';
			case 'creator.campaigns.type_shorts': return 'Shorts';
			case 'creator.campaigns.reward_cpm_label': return 'CPM';
			case 'creator.campaigns.reward_cpc_label': return 'Payout per click';
			case 'creator.campaigns.reward_per_view_label': return 'Payout per view';
			case 'creator.campaigns.reward_per_view': return ({required Object amount}) => '${amount} / view';
			case 'creator.campaigns.reward_per_click': return ({required Object amount}) => '${amount} / click';
			case 'creator.campaigns.budget_remaining_label': return 'Remaining budget';
			case 'creator.campaigns.requirement_platform': return ({required Object platform}) => 'Post on ${platform} only';
			case 'creator.campaigns.requirement_min_duration': return ({required Object minutes}) => 'Minimum duration: ${minutes} min';
			case 'creator.campaigns.requirement_shorts_max': return ({required Object seconds}) => 'Shorts up to ${seconds} s';
			case 'creator.campaigns.requirement_vertical': return 'Vertical format (9:16) required';
			case 'creator.campaigns.requirement_none': return 'No specific requirements.';
			case 'creator.campaigns.apply_cta': return 'Apply to this campaign';
			case 'creator.campaigns.apply_title': return 'Apply';
			case 'creator.campaigns.apply_message_label': return 'Pitch (optional)';
			case 'creator.campaigns.apply_message_hint': return 'Tell the advertiser why you\'re a great fit…';
			case 'creator.campaigns.apply_submit': return 'Send application';
			case 'creator.campaigns.apply_in_progress': return 'Sending…';
			case 'creator.campaigns.apply_error': return 'Could not send your application. Please try again.';
			case 'creator.campaigns.apply_success': return 'Application sent — you\'ll be notified when it\'s reviewed.';
			case 'creator.campaigns.apply_pending_title': return 'Application under review';
			case 'creator.campaigns.apply_pending_subtitle': return 'We\'ll notify you the moment the advertiser responds.';
			case 'creator.campaigns.open_application_cta': return 'Open my application';
			case 'creator.campaigns.chat_with_advertiser': return 'Chat with advertiser';
			case 'creator.campaigns.status_banner_approved_title': return 'You\'re approved!';
			case 'creator.campaigns.status_banner_approved_subtitle': return 'You can now submit your video and chat with the advertiser.';
			case 'creator.campaigns.status_banner_pending_title': return 'Waiting on advertiser';
			case 'creator.campaigns.status_banner_pending_subtitle': return 'Your pitch is in review — we\'ll ping you here when it\'s decided.';
			case 'creator.campaigns.status_banner_rejected_title': return 'Not selected this time';
			case 'creator.campaigns.status_banner_rejected_subtitle': return 'Keep an eye on the Campaigns tab — new briefs ship every week.';
			case 'creator.campaigns.my_submissions_title': return 'My submissions';
			case 'creator.campaigns.my_submissions_empty_approved': return 'No video submitted yet. Upload one to start earning.';
			case 'creator.campaigns.my_submissions_empty_pending': return 'Submissions unlock once your application is approved.';
			case 'creator.campaigns.submit_cta': return 'Submit a post';
			case 'creator.campaigns.submit_platform_label': return 'Platform';
			case 'creator.campaigns.submit_url_label': return 'Public video URL';
			case 'creator.campaigns.submit_url_hint': return 'https://youtube.com/watch?v=…';
			case 'creator.campaigns.submit_url_required': return 'Please paste the video URL.';
			case 'creator.campaigns.submit_url_invalid': return 'Enter a valid public URL.';
			case 'creator.campaigns.submit_url_youtube_only': return 'Only YouTube URLs are supported right now.';
			case 'creator.campaigns.submit_in_progress': return 'Submitting…';
			case 'creator.campaigns.submit_footer': return 'Your video stays public during the campaign so we can validate views.';
			case 'creator.campaigns.submit_error': return 'Could not submit your video. Please try again.';
			case 'creator.campaigns.submit_success': return 'Video submitted — advertiser will review it shortly.';
			case 'creator.campaigns.submit_blocked_limit': return 'You\'ve already submitted for this campaign. Wait for the review.';
			case 'creator.campaigns.submission_status_pending': return 'In review';
			case 'creator.campaigns.submission_status_approved': return 'Approved';
			case 'creator.campaigns.submission_status_rejected': return 'Rejected';
			case 'creator.campaigns.submission_status_flagged': return 'Flagged';
			case 'creator.campaigns.submission_views': return ({required Object views}) => '${views} validated views';
			case 'creator.stats.earnings_title': return 'Total earnings';
			case 'creator.stats.pending': return 'Pending';
			case 'creator.stats.validated_views': return 'Validated views';
			case 'creator.stats.validation_rate': return 'Validation rate';
			case 'creator.stats.approved_campaigns': return 'Approved campaigns';
			case 'creator.applications.section_title': return 'Active applications';
			case 'creator.applications.empty_title': return 'No applications yet';
			case 'creator.applications.empty_subtitle': return 'Browse the Campaigns tab and apply to the ones that match your audience.';
			case 'creator.applications.load_error': return 'Couldn\'t load your applications';
			case 'creator.applications.status_pending': return 'Pending';
			case 'creator.applications.status_approved': return 'Approved';
			case 'creator.applications.status_rejected': return 'Rejected';
			case 'creator.applications.status_withdrawn': return 'Withdrawn';
			case 'creator.applications.status_unknown': return '—';
			case 'creator.business.cta_title': return 'Finalize your business information';
			case 'creator.business.cta_subtitle': return 'Required before connecting your bank account so we can route your payouts correctly.';
			case 'creator.business.cta_required_pill': return 'REQUIRED';
			case 'creator.business.cta_button': return 'Finalize your Business Information';
			case 'creator.business.dialog_title': return 'Business information';
			case 'creator.business.dialog_subtitle': return 'Provide a few legal details so Stripe can onboard your account and settle payouts.';
			case 'creator.business.section_type': return 'Account type';
			case 'creator.business.section_company': return 'Company';
			case 'creator.business.section_address': return 'Address';
			case 'creator.business.section_stripe': return 'Payout country & currency';
			case 'creator.business.type_personal_title': return 'Individual';
			case 'creator.business.type_personal_subtitle': return 'I receive payouts as a private person.';
			case 'creator.business.type_sole_title': return 'Sole proprietor';
			case 'creator.business.type_sole_subtitle': return 'I run my own freelance business.';
			case 'creator.business.type_company_title': return 'Registered company';
			case 'creator.business.type_company_subtitle': return 'I operate under a registered legal entity.';
			case 'creator.business.company_name': return 'Company name';
			case 'creator.business.vat_number': return 'VAT number';
			case 'creator.business.address_line1': return 'Address line 1';
			case 'creator.business.address_line2': return 'Address line 2 (optional)';
			case 'creator.business.city': return 'City';
			case 'creator.business.postal_code': return 'Postal code';
			case 'creator.business.state_region': return 'State / Region (optional)';
			case 'creator.business.country': return 'Country';
			case 'creator.business.currency': return 'Payout currency';
			case 'creator.business.error_required': return 'Required';
			case 'creator.business.save_and_continue': return 'Save & continue';
			case 'creator.business.submitting': return 'Saving…';
			case 'creator.business.footer_info': return 'This information is shared with Stripe to enable your payout account. We never see your banking details.';
			case 'creator.business.save_error': return 'We couldn\'t save your business info. Please try again.';
			case 'advertiser_wallet.hero_title': return 'Your balance';
			case 'advertiser_wallet.hero_subtitle': return 'Add funds to run campaigns. Payments are processed securely by Stripe. Apple Pay (iOS) and Google Pay (Android) are available when supported.';
			case 'advertiser_wallet.available': return 'Available';
			case 'advertiser_wallet.pending': return 'Pending';
			case 'advertiser_wallet.add_funds': return 'Add funds';
			case 'advertiser_wallet.amount_label': return 'Amount';
			case 'advertiser_wallet.quick_50': return '€50';
			case 'advertiser_wallet.quick_100': return '€100';
			case 'advertiser_wallet.quick_250': return '€250';
			case 'advertiser_wallet.min_deposit': return 'Minimum deposit is 50.00 in your currency.';
			case 'advertiser_wallet.test_pay': return 'Simulate payment (dev)';
			case 'advertiser_wallet.test_hint': return 'Test mode: no real card. Tops up your dev wallet for QA.';
			case 'advertiser_wallet.pay_secure': return 'Pay with card, Apple Pay or Google Pay';
			case 'advertiser_wallet.pay_with_card': return 'Pay with card';
			case 'advertiser_wallet.pay_with_apple': return 'Pay with Apple Pay';
			case 'advertiser_wallet.pay_with_google': return 'Pay with Google Pay';
			case 'advertiser_wallet.or': return 'or';
			case 'advertiser_wallet.stripe_unavailable': return 'Top-ups are not available: payment is not configured on the server.';
			case 'advertiser_wallet.tx_title': return 'Recent activity';
			case 'advertiser_wallet.tx_empty': return 'No transactions yet';
			case 'advertiser_wallet.tx_deposit': return 'Deposit';
			case 'advertiser_wallet.tx_withdrawal': return 'Withdrawal';
			case 'advertiser_wallet.tx_other': return 'Transaction';
			case 'advertiser_wallet.success': return 'Balance updated';
			case 'advertiser_wallet.failed': return 'Could not add funds. Try again.';
			case 'advertiser_wallet.in_progress': return 'Processing…';
			case 'advertiser_wallet.tx_page': return ({required Object current, required Object total}) => 'Page ${current} of ${total}';
			case 'advertiser_wallet.tx_prev': return 'Previous';
			case 'advertiser_wallet.tx_next': return 'Next';
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
			case 'chat.search_prior_chats_hint': return 'Search people you\'ve messaged…';
			case 'chat.search_prior_chats_no_results': return 'No one in your conversations matches.';
			case 'chat.search_prior_chats_min_hint': return 'Type at least 2 characters.';
			case 'chat.conversation_open_failed': return 'Could not open that conversation. Try again.';
			case 'chat.file_picker_restart_hint': return 'Attachments need a full app restart after updates. Stop the app, then Run again (avoid hot restart).';
			case 'chat.attachment_type_not_allowed': return 'Only images (JPG, PNG, GIF, WebP, BMP) or PDF are allowed.';
			case 'chat.inbox_swipe_soon': return 'Pin and archive from the list are coming soon.';
			case 'chat.date_today': return 'Today';
			case 'chat.date_yesterday': return 'Yesterday';
			case 'chat.bubble_reply': return 'Reply';
			case 'chat.reply_composer_title': return 'Reply';
			case 'chat.reply_composer_you': return 'You';
			case 'chat.composer_reply_hint': return 'Write a reply…';
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
			case 'onboarding.role_gate_title': return 'Choose your profile';
			case 'onboarding.role_gate_subtitle': return 'Same step as on the Wayo Ads website before you can use the app.';
			case 'onboarding.role_creator_cta': return 'Creator';
			case 'onboarding.role_creator_desc': return 'Browse campaigns, apply, and collaborate with brands.';
			case 'onboarding.role_advertiser_cta': return 'Advertiser';
			case 'onboarding.role_advertiser_desc': return 'Launch campaigns and manage creators from your dashboard.';
			case 'onboarding.email_code_title': return 'Verify your email';
			case 'onboarding.email_code_subtitle': return ({required Object email}) => 'Enter the 6-digit code we sent to ${email}.';
			case 'onboarding.skip': return 'Skip';
			case 'onboarding.next': return 'Next';
			case 'onboarding.done': return 'Got it';
			case 'onboarding.advertiser.dashboard_title': return 'Your dashboard';
			case 'onboarding.advertiser.dashboard_subtitle': return 'Track balance, active campaigns and notifications — all updates land here in real time.';
			case 'onboarding.advertiser.campaigns_title': return 'Campaigns';
			case 'onboarding.advertiser.campaigns_subtitle': return 'Create new campaigns, review applications and monitor performance in one place.';
			case 'onboarding.advertiser.wallet_title': return 'Wallet';
			case 'onboarding.advertiser.wallet_subtitle': return 'Top up your budget, view invoices and spending history — secured by Stripe.';
			case 'onboarding.advertiser.chat_title': return 'Chat';
			case 'onboarding.advertiser.chat_subtitle': return 'Talk to your creators once a campaign is approved. Conversations stay in sync across devices.';
			case 'onboarding.creator.dashboard_title': return 'Creator dashboard';
			case 'onboarding.creator.dashboard_subtitle': return 'Your KPIs, active applications and earnings refresh automatically — no need to pull to refresh.';
			case 'onboarding.creator.campaigns_title': return 'Browse & apply';
			case 'onboarding.creator.campaigns_subtitle': return 'Discover eligible campaigns, apply in one tap and follow your application status live.';
			case 'onboarding.creator.wallet_title': return 'Earnings & payouts';
			case 'onboarding.creator.wallet_subtitle': return 'See your balance, request payouts via Stripe Connect and review past withdrawals.';
			case 'onboarding.creator.chat_title': return 'Talk to advertisers';
			case 'onboarding.creator.chat_subtitle': return 'Once approved, the chat opens with your advertiser to align on deliverables.';
			default: return null;
		}
	}
}

