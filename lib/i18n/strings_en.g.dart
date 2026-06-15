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
	late final TranslationsForceUpdateEn force_update = TranslationsForceUpdateEn.internal(_root);
	late final TranslationsMaintenanceEn maintenance = TranslationsMaintenanceEn.internal(_root);
	late final TranslationsConnectivityEn connectivity = TranslationsConnectivityEn.internal(_root);
	late final TranslationsCampaignsExplorerEn campaigns_explorer = TranslationsCampaignsExplorerEn.internal(_root);
	late final TranslationsLoginEn login = TranslationsLoginEn.internal(_root);
	late final TranslationsVerifyEmailEn verify_email = TranslationsVerifyEmailEn.internal(_root);
	late final TranslationsForgotPasswordEn forgot_password = TranslationsForgotPasswordEn.internal(_root);
	late final TranslationsOtpEn otp = TranslationsOtpEn.internal(_root);
	late final TranslationsResetPasswordEn reset_password = TranslationsResetPasswordEn.internal(_root);
	late final TranslationsValidationEn validation = TranslationsValidationEn.internal(_root);
	late final TranslationsHomeEn home = TranslationsHomeEn.internal(_root);
	late final TranslationsDashboardEn dashboard = TranslationsDashboardEn.internal(_root);
	late final TranslationsAdvertiserCampaignsEn advertiser_campaigns = TranslationsAdvertiserCampaignsEn.internal(_root);
	late final TranslationsAdvertiserVideoReviewsEn advertiser_video_reviews = TranslationsAdvertiserVideoReviewsEn.internal(_root);
	late final TranslationsNavEn nav = TranslationsNavEn.internal(_root);
	late final TranslationsInvoicesEn invoices = TranslationsInvoicesEn.internal(_root);
	late final TranslationsPushEn push = TranslationsPushEn.internal(_root);
	late final TranslationsCreatorEn creator = TranslationsCreatorEn.internal(_root);
	late final TranslationsAdvertiserWalletEn advertiser_wallet = TranslationsAdvertiserWalletEn.internal(_root);
	late final TranslationsChatEn chat = TranslationsChatEn.internal(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsPrivacyPolicyEn privacy_policy = TranslationsPrivacyPolicyEn.internal(_root);
	late final TranslationsAppSettingsEn app_settings = TranslationsAppSettingsEn.internal(_root);
	late final TranslationsAccountDeletionEn account_deletion = TranslationsAccountDeletionEn.internal(_root);
	late final TranslationsOnboardingEn onboarding = TranslationsOnboardingEn.internal(_root);
}

// Path: force_update
class TranslationsForceUpdateEn {
	TranslationsForceUpdateEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Update required';
	String get subtitle => 'A new version of Wayo Ads is available. Please update from the store to continue.';
	String get action_update => 'Update now';
	String get checking => 'Checking for updates…';
}

// Path: maintenance
class TranslationsMaintenanceEn {
	TranslationsMaintenanceEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'We\'ll be back soon';
	String get subtitle => 'We are busy upgrading the service with more features. We will return soon.';
	String get apology => 'We apologize for the inconvenience and appreciate your patience.';
	String get copyright => '© 2026 Wayo Ads. All rights reserved.';
	String get support_email => 'support@wayo.cloud';
	String get action_retry => 'Retry';
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

// Path: campaigns_explorer
class TranslationsCampaignsExplorerEn {
	TranslationsCampaignsExplorerEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get filter_all_types => 'All types';
	String get filter_all_platforms => 'All platforms';
	String get filter_all_niches => 'All niches';
	String get filter_all_locations => 'All locations';
	String get platform_youtube => 'YouTube';
	String get platform_tiktok => 'TikTok';
	String get platform_instagram => 'Instagram';
	String get results_one => '1 campaign';
	String results_many({required Object n}) => '${n} campaigns';
	String get layout_grid => 'Grid view';
	String get layout_list => 'List view';
	String get empty_filters => 'No campaigns match these filters.';
	String get empty_filters_subtitle => 'Clear a filter or change the type — niche options only include campaigns that fit your other choices.';
	String get search_aria => 'Search campaigns';
	String get reset_filters => 'Reset filters';
	String get toolbar_show_search_filters => 'Show search and filters';
	String get toolbar_hide_search_filters => 'Hide search and filters';
	String get filter_label_type => 'Type';
	String get filter_label_status => 'Status';
	String get filter_label_niche => 'Niche';
	String get filter_label_location => 'Location';
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
	String get apple_cta => 'Sign in with Apple';
	String get apple_unavailable => 'Sign in with Apple is not available on this device.';
	String get apple_failed => 'Apple sign-in failed. Try again.';
	String get apple_server_not_configured => 'Sign in with Apple is not enabled on the Wayo ID server yet. Ask your administrator to configure Apple credentials on Auth_Wayo (production), then try again.';
	String get apple_canceled => 'Sign in with Apple was canceled.';
	String get apple_hide_my_email_hint => 'For verification codes to arrive, choose Share My Email — not Hide My Email when signing in with Apple.';
	String get google_not_configured => 'Google sign-in is not configured. Add AUTH_GOOGLE_SERVER_CLIENT_ID to dart_defines.json (Web client ID ending in .apps.googleusercontent.com) and do a full restart.';
	String get google_wrong_client_id => 'AUTH_GOOGLE_SERVER_CLIENT_ID must be your Google Cloud Web client ID (…apps.googleusercontent.com), not the Passport OAuth client UUID.';
	String get google_failed => 'Google sign-in failed. Try again.';
	String get google_channel_restart => 'Google Sign-In lost connection to Android (often after hot restart). Stop the app completely, then Run again — do not use hot restart.';
	String get google_android_oauth_misconfigured => 'Google could not verify this app (code 10). In Google Cloud Console, open the same project as your Web client, create an Android OAuth client with package ma.wayo.wayoadsgo and your debug (or release) keystore SHA-1, then wait a few minutes and try again.';
	String get session_expired_snack => 'Your session has expired. Please sign in again.';
	String get web_session_title => 'Already signed in on the web';
	String get web_session_body => 'This account is still connected on the Wayo Ads website. Sign out from the web before signing in on the app.';
	String get web_session_disconnect => 'Sign out from web and continue';
	String get web_session_open_browser => 'Open website to sign out';
	String get web_session_cancel => 'Cancel';
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
	String get notifications_mark_read => 'Mark as read';
	String get notifications_dismiss => 'Dismiss';
	String get notifications_view_all => 'View all notifications';
	String get notifications_important => 'Important';
	String get notifications_earlier => 'Earlier';
	String get notifications_caught_up_title => 'All caught up!';
	String get notifications_caught_up_subtitle => 'No new notifications';
	String get notifications_center_title => 'Notification center';
	String get notifications_unread_count => '{count} unread notifications';
	String get notifications_all_caught_up => 'You\'re all caught up';
	String get notifications_tab_all => 'All';
	String get notifications_tab_archived => 'Archived';
	String get notifications_search_hint => 'Search notifications…';
	String get notifications_filter_type_all => 'All types';
	String get notifications_filter_priority_all => 'All priorities';
	String get notifications_priority_critical => 'Critical';
	String get notifications_priority_high => 'High';
	String get notifications_priority_normal => 'Normal';
	String get notifications_priority_low => 'Low';
	String get notifications_load_more => 'Load more';
	String get notifications_view_details => 'View details';
	String get notifications_archive => 'Archive';
	String get notifications_urgent => 'Urgent';
	String get notifications_just_now => 'Just now';
	String get notifications_minutes_ago => '{n} min ago';
	String get notifications_hours_ago => '{n} h ago';
	String get notifications_days_ago => '{n} d ago';
	String get notifications_section_all => 'All notifications';
	String get notifications_section_important => 'Important alerts';
	String get notifications_section_archived => 'Archived notifications';
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

// Path: advertiser_video_reviews
class TranslationsAdvertiserVideoReviewsEn {
	TranslationsAdvertiserVideoReviewsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Video reviews';
	String get subtitle => 'Approve or reject creator video submissions for your campaigns.';
	String get pending => 'Pending';
	String get approved => 'Approved';
	String get rejected => 'Rejected';
	String get flagged => 'Flagged';
	String get empty => 'No videos in this category.';
	String get load_error => 'Could not load video submissions';
	String get approve_button => 'Approve';
	String get reject_button => 'Reject';
	String get approve_success => 'Video approved';
	String get reject_success => 'Video rejected';
	String get reject_reason_required => 'Please provide a rejection reason';
	String get reject_reason_hint => 'Reason for rejection';
	String get reject_dialog_title => 'Reject video';
	String get action_failed => 'Could not update the video. Try again.';
	String get submitted_at => 'Submitted';
	String get shorts_badge => 'Short';
	String get flag_reason => 'Flag reason';
	String get rejection_reason => 'Rejection reason';
	String get status_pending => 'Pending';
	String get status_approved => 'Approved';
	String get status_rejected => 'Rejected';
	String get status_flagged => 'Flagged';
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
	String get invoices => 'Invoices';
	String get invoices_creator => 'Statements';
}

// Path: invoices
class TranslationsInvoicesEn {
	TranslationsInvoicesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Invoices';
	String get title_creator => 'Payment statements';
	String get subtitle_advertiser => 'Every deposit and campaign budget — all in one place.';
	String get subtitle_creator => 'Every earning and payout — secured, downloadable, signed.';
	String get summary_total_paid => 'Total paid';
	String get summary_total_validated => 'Total validated';
	String get summary_pending => 'Pending';
	String get summary_count => 'Documents';
	String get filter_all => 'All';
	String get filter_deposits => 'Deposits';
	String get filter_billing => 'Campaign budget';
	String get filter_payouts => 'Payouts';
	String get filter_earnings => 'Earnings';
	String get type_deposit => 'Wallet deposit';
	String get type_billing => 'Campaign budget';
	String get type_payout => 'Creator payout';
	String get type_earnings => 'Ad earnings';
	String get type_unknown => 'Other';
	String get status_paid => 'Paid';
	String get status_validated => 'Validated';
	String get status_pending => 'Pending';
	String get status_cancelled => 'Cancelled';
	String get role_advertiser => 'Advertiser';
	String get role_creator => 'Creator';
	String get search_hint => 'Search by number, reference…';
	String get empty_title => 'No invoice yet';
	String get empty_subtitle => 'Your wallet deposits, campaign budgets and creator payouts will appear here automatically — no manual step required.';
	String get empty_subtitle_creator => 'Your earnings and payout documents will show up here as soon as they are issued — same signed PDFs as on the web.';
	String get empty_cta => 'Refresh';
	String get error_title => 'Could not load invoices';
	String get error_subtitle => 'Pull to refresh — we\'ll try again right away.';
	String get load_more => 'Load more';
	String get pagination_meta => 'Page {current} of {total}';
	String get pagination_previous => 'Previous';
	String get pagination_next => 'Next';
	String get date_preset_all => 'All dates';
	String get date_preset_30d => '30 days';
	String get date_preset_90d => '90 days';
	String get date_preset_custom => 'Custom';
	String get details_title => 'Invoice {number}';
	String get details_section_summary => 'Summary';
	String get details_section_actions => 'Actions';
	String get details_section_legal => 'Legal & references';
	String get details_invoice_number => 'Invoice number';
	String get details_issued_at => 'Issued on';
	String get details_paid_at => 'Paid on';
	String get details_type => 'Type';
	String get details_status => 'Status';
	String get details_role => 'Role';
	String get details_reference => 'Reference';
	String get details_amount => 'Total';
	String get details_tax => 'VAT included';
	String get details_currency => 'Currency';
	String get action_download_pdf => 'Download PDF';
	String get action_share_pdf => 'Share';
	String get action_open_pdf => 'Open';
	String get action_copy_number => 'Copy invoice #';
	String get action_view_details => 'View details';
	String get download_progress => 'Preparing your PDF…';
	String get download_success => 'Saved to {filename}';
	String get download_error => 'Download failed. Please try again.';
	String get copied_to_clipboard => 'Invoice number copied.';
	String get share_subject => 'Invoice {number}';
	String get polling_live => 'Live';
	String get polling_paused => 'Paused';
	String get summary_this_month => 'This month';
	String get pagination_detail => 'Page {current} of {total} · {count} invoices';
	String get sort_sheet_title => 'Sort';
	String get sort_date_newest => 'Newest first';
	String get sort_date_oldest => 'Oldest first';
	String get sort_amount_high => 'Amount · high to low';
	String get sort_amount_low => 'Amount · low to high';
	String get sort_status_az => 'Status · A to Z';
	String get sort_status_za => 'Status · Z to A';
	String get date_range_title => 'Dates';
	String get date_from => 'From';
	String get date_to => 'To';
	String get clear_dates => 'Clear';
	String get date_apply => 'Apply';
	String get download_all_zip => 'ZIP';
	String get zip_progress => 'Building ZIP…';
	String get zip_success => 'Saved {filename}';
	String get zip_error => 'ZIP download failed.';
}

// Path: push
class TranslationsPushEn {
	TranslationsPushEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get onboarding_title => 'Stay in the loop';
	String get onboarding_subtitle => 'Get instant alerts when something important happens — even when Wayo Ads is in the background.';
	String get onboarding_bullet_campaigns => 'Campaign updates, applications and budgets';
	String get onboarding_bullet_messages => 'New chat messages';
	String get onboarding_bullet_system => 'Invoices, payouts and platform alerts';
	String get onboarding_enable => 'Turn on notifications';
	String get onboarding_later => 'Not now';
	String get onboarding_success => 'Notifications enabled';
	String get onboarding_denied_hint => 'You can enable them anytime in system settings.';
	String get onboarding_context_chat => 'You just received a new chat message — turn on alerts so you never miss a reply.';
	String get onboarding_context_campaign => 'A campaign status changed — enable notifications to stay on top of applications and budgets.';
	String get onboarding_context_invoice => 'A new invoice or payout update is ready — get notified as soon as money moves.';
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
	String get quick_50 => '50 USD';
	String get quick_100 => '100 USD';
	String get quick_250 => '500 USD';
	String get min_deposit => 'Minimum deposit is 50.00 USD.';
	String get test_pay => 'Simulate payment (dev)';
	String get test_hint => 'Test mode: no real card. Tops up your dev wallet for QA.';
	String get pay_secure => 'Pay with card, Apple Pay or Google Pay';
	String get pay_with_card => 'Pay with card';
	String get pay_with_apple => 'Pay with Apple Pay';
	String get pay_with_google => 'Pay with Google Pay';
	String get or => 'or';
	String get stripe_unavailable => 'Top-ups are not available: payment is not configured on the server.';
	String get stripe_keys_mismatch => 'Payment is misconfigured on the server (Stripe test/live keys mixed). Contact support.';
	String get apple_pay_test_hint => 'Stripe test mode: Apple Pay uses your Wallet card but no real charge is made.';
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
	String get business_profile_gate_title => 'Business details required';
	String get business_profile_gate_body => 'Add valid billing information before adding funds. This keeps invoices and compliance aligned with Wayo Ads.';
	String get business_profile_gate_secure => 'Encrypted connection — verified on our servers before any charge.';
	String get business_profile_gate_cta => 'Complete business information';
	String get business_profile_error => 'Could not load business profile.';
	String get pay_locked_until_business => 'Payment unlocks once your business profile is complete.';
	String get payment_title => 'Payment';
	String get payment_total => 'TOTAL';
	String get payment_deposit_amount => 'Deposit amount';
	String get payment_bank_fee => 'Bank transaction fee (3.69%)';
	String get deposit_pending => 'Deposit pending';
	String get deposit_resume_hint => 'Resuming your deposit of {amount} — complete payment or tap Cancel to discard.';
	String get deposit_cancel => 'Cancel';
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
	String get spam_cooldown_title => 'You\'re sending messages too fast';
	String spam_cooldown_body({required Object seconds}) => 'Please wait ${seconds} s before sending again.';
	String spam_cooldown_seconds({required Object seconds}) => '${seconds} s';
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
	String get bubble_forward => 'Forward';
	String get share_media_tooltip => 'Share';
	String get share_failed => 'Could not share this file. Try again.';
	String get forward_sheet_title => 'Forward to…';
	String get forward_no_other_chats => 'You need another conversation open first.';
	String get forward_sending => 'Forwarding…';
	String get forward_ok => 'Message forwarded.';
	String get forward_failed => 'Forward failed.';
	String get forward_view => 'Open';
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
	String get loading_older_messages => 'Loading earlier messages…';
	String get load_older_failed => 'Could not load earlier messages.';
	String get image_download_tooltip => 'Download photo';
	String get image_close_tooltip => 'Close';
	String get image_saved_to_gallery => 'Photo saved to your gallery.';
	String get image_download_failed => 'Couldn\'t download this photo.';
	String get image_permission_denied => 'Photos access denied. Allow it in your device settings.';
	String get image_saved_downloads_browser => 'Photo downloaded — check your Downloads folder.';
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
	String get theme_hint => 'Choose how Wayo Ads looks. The theme follows your phone’s settings.';
	String get language_hint => 'Sets the interface language. Dates and formats adapt to your chosen language.';
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
	String get section_notifications => 'Notifications';
	String get notifications_toggle => 'Push notifications';
	String get notifications_hint => 'Alerts for campaigns, chat, invoices and payouts. Requires permission in your phone settings.';
	String get notifications_status_enabled => 'Enabled — you will receive alerts on this device';
	String get notifications_status_disabled => 'Disabled in the app';
	String get notifications_status_permission_denied => 'Allow notifications in your phone settings to receive alerts';
	String get notifications_open_settings => 'Open phone settings';
	String get notifications_enable_error => 'Could not enable notifications. Check system settings.';
	String get notifications_update_error => 'Could not update notification settings. Try again.';
	String get section_account => 'Account';
	String get delete_account_entry => 'Delete account';
	String get delete_account_entry_sub => '30-day grace — manage deletion in the app';
	String get section_about => 'About';
	String get rate_app => 'Rate Wayo Ads';
	String get rate_app_sub => 'Open the App Store or Google Play';
}

// Path: account_deletion
class TranslationsAccountDeletionEn {
	TranslationsAccountDeletionEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get nav_title => 'Delete account';
	String get title => 'Delete my Wayo Ads account';
	String get danger_zone_chip => 'Danger Zone';
	String get danger_zone_intro => 'Permanently delete your account and all associated data. This action cannot be undone after the grace period.';
	String get danger_what_title => 'What will be deleted:';
	String get danger_item_profile => 'Your profile and personal information';
	String get danger_item_campaigns => 'All your campaigns and their performance data';
	String get danger_item_business => 'Your business profile and brand information';
	String get danger_item_wallet => 'Your advertiser wallet and transaction history';
	String get danger_item_notifications => 'Your notifications and email preferences';
	String get danger_item_access => 'Your access to Wayo Ads (you will not be able to sign in again here)';
	String get danger_wayo_note => 'Only your Wayo Ads data is affected. Your Wayo account (used to sign in) stays active for other Wayo services.';
	String get subtitle_warning => 'Important: after 30 days, your Wayo Ads data will be permanently removed. You can cancel anytime before then.';
	String get bullet_loss => 'Campaigns, applications, and app-side profile data will be deleted after the grace period.';
	String get bullet_wallet => 'Wallet balance, invoices, and transaction history tied to this account will be removed.';
	String get bullet_cancel => 'Free cancellation window: 30 days from your request.';
	String get bullet_recreate => 'Your Wayo ID (login) is not deleted by this step — you may sign in again and get a fresh app profile later.';
	String get role_advertiser => 'Advertiser: active campaigns will stop when data is purged.';
	String get role_creator => 'Creator: applications, channels, and earnings records in the app will be deleted.';
	String get continue_cta => 'Continue';
	String get back => 'Back';
	String get more_info_title => 'Before you go';
	String get more_info_body => 'Emails: you will receive a confirmation now and a reminder about 3 days before deletion.\nSupport: contact us if you need help exporting information or closing campaigns first.';
	String get step_auth_title => 'Confirm your identity';
	String get status_active => 'No deletion scheduled for this account.';
	String status_pending({required Object date}) => 'Deletion already scheduled. Final date: ${date}';
	String get password_label => 'Password';
	String get password_hint => 'At least 8 characters';
	String get forgot_password => 'Forgot password?';
	String get oauth_note => 'If you only sign in with Google or Apple, set a password first (Forgot password).';
	String get oauth_deletion_intro => 'You use Google or Apple to sign in. After you continue, confirm in the next step — no password required.';
	String get oauth_deletion_step_hint => 'Your identity was confirmed when you signed in with Google or Apple. Tap below to review the final confirmation sheet.';
	String legal_recap({required Object date}) => 'You will start a 30-day grace period before permanent deletion. You can cancel until ${date}.';
	String get next_review => 'Review and confirm';
	String get dialog_title => 'Are you sure?';
	String get dialog_body => 'Your Wayo Ads data will be scheduled for deletion. Final removal on:';
	String get dialog_cancel_hint => 'You can cancel anytime in Settings until that date.';
	String get timeline_request => 'Request';
	String get timeline_reminder => 'Email reminder';
	String get timeline_purge => 'Deletion';
	String get dialog_confirm => 'Yes, schedule deletion';
	String get dialog_dismiss => 'Keep my account';
	String get success_title => 'Deletion scheduled';
	String get success_intro => 'What happens next?';
	String get success_use_until => 'You can keep using Wayo Ads until the final date.';
	String get success_reminder => 'We will email you a reminder a few days before deletion.';
	String get success_cancel_anytime => 'Cancel anytime from this screen or Settings.';
	String days_left({required Object n}) => 'Days left: ${n}';
	String purge_date({required Object date}) => 'Final deletion: ${date}';
	String reminder_approx({required Object date}) => 'Reminder around: ${date}';
	String get cancel_request => 'Cancel deletion';
	String get go_home => 'Back to home';
	String get toast_cancelled => 'Deletion cancelled. Your account is restored.';
	String get error_load => 'Could not load account status.';
	String get error_load_unauthorized => 'We could not verify your session with Wayo Ads. Sign out and sign in again, then retry.';
	String get error_load_network => 'Check your connection and that Wayo Ads is reachable, then retry.';
	String get error_delete => 'Something went wrong. Please try again.';
	String get error_password => 'Incorrect password. Try again or reset your password.';
	String banner_line({required Object date, required Object n}) => 'Your account will be deleted on ${date} (${n} days left).';
	String get banner_cancel_dialog_title => 'Cancel scheduled deletion?';
	String get banner_cancel_dialog_body => 'Your Wayo Ads profile will stay active.';
	String get banner_cancel_dialog_confirm => 'Keep my account';
	String pending_danger_card_body({required Object date}) => 'Your account is scheduled for permanent deletion on ${date}. You can cancel this request at any time before that date.';
	String get pending_scheduled_status => 'Account deletion scheduled';
	String get pending_days_remaining_one => '1 day remaining';
	String pending_days_remaining_plural({required Object n}) => '${n} days remaining';
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
	String get email_code_subtitle_prefix => 'Enter the 6-digit code we sent to ';
	String get email_code_subtitle_suffix => '.';
	String get email_code_hide_my_email_warning => 'You signed in with Apple\'s Hide My Email. Verification codes often don\'t reach relay addresses. Sign out, then sign in with Apple again and choose Share My Email, or use email and password with your real iCloud address.';
	String get email_code_otp_label => 'Enter verification code';
	String get email_code_sending => 'Sending code...';
	String get email_code_verifying => 'Verifying...';
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
	String get cpm => 'CPM';
	String get valid_engagements => '{count} validated views';
	String get list_row_views => '{count} views';
	String get list_row_clicks => '{count} clicks';
	String get list_row_creators => '{count} creators';
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
	String get location_label => 'Location';
	String get objective_label => 'Objective';
	String get objective_awareness => 'Awareness';
	String get objective_traffic => 'Traffic';
	String get objective_conversion => 'Conversion';
	String get cpm_metric => 'CPM (per 1k views)';
	String get cpm_consumed => 'Consumed CPM (per 1k views)';
	String get cpc_metric => 'CPC (per click)';
	String get description_title => 'Description';
	String get show_more => 'Show more';
	String get show_less => 'Show less';
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
	String get withdraw_amount_label => 'Amount (USD)';
	String get withdraw_sheet_body => 'Enter the amount you wish to withdraw. Funds will be sent to your connected bank account.';
	String get withdraw_quick_amounts => 'Quick amounts';
	String get withdraw_gross_amount => 'Gross amount';
	String get withdraw_platform_fee => 'Platform fee ({percent}%)';
	String get withdraw_tax_vat => 'VAT ({percent}%)';
	String get withdraw_net_received => 'Net received';
	String get withdraw_submit => 'Confirm withdrawal';
	String get withdraw_submitting => 'Processing…';
	String get withdraw_max => 'Max';
	String get withdraw_preset_all => 'All';
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
	String get stripe_edit_business_action => 'Edit business details';
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
	String get earnings_card_title => 'My earnings from this campaign';
	String get earnings_card_subtitle => 'Your performance and payout breakdown';
	String get earnings_net => 'Net earnings';
	String get earnings_views => 'Earnings views';
	String get earnings_platform_views => 'Platform views';
	String get earnings_valid_clicks => 'Earnings clicks';
	String get earnings_recorded_clicks => 'Recorded clicks';
	String get earnings_available_balance => 'Available balance';
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
	String get section_type => 'Business type';
	String get section_company => 'Company';
	String get section_address => 'Address';
	String get section_stripe => 'Payout country & currency';
	String get type_personal_title => 'Individual / Private person';
	String get type_personal_subtitle => 'I receive payouts as a private person.';
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
	String get wallet_subtitle => 'Top up your budget and track spending — secured by Stripe.';
	String get invoices_title => 'Invoices';
	String get invoices_subtitle => 'Download signed PDFs for deposits, campaign billing and transfers — all in one place.';
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
	String get invoices_title => 'Payment statements';
	String get invoices_subtitle => 'Filter earnings and payouts, download signed PDFs or a ZIP — refreshed automatically while you use the app.';
	String get chat_title => 'Talk to advertisers';
	String get chat_subtitle => 'Once approved, the chat opens with your advertiser to align on deliverables.';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'force_update.title': return 'Update required';
			case 'force_update.subtitle': return 'A new version of Wayo Ads is available. Please update from the store to continue.';
			case 'force_update.action_update': return 'Update now';
			case 'force_update.checking': return 'Checking for updates…';
			case 'maintenance.title': return 'We\'ll be back soon';
			case 'maintenance.subtitle': return 'We are busy upgrading the service with more features. We will return soon.';
			case 'maintenance.apology': return 'We apologize for the inconvenience and appreciate your patience.';
			case 'maintenance.copyright': return '© 2026 Wayo Ads. All rights reserved.';
			case 'maintenance.support_email': return 'support@wayo.cloud';
			case 'maintenance.action_retry': return 'Retry';
			case 'connectivity.offline_title': return 'No Internet Connection';
			case 'connectivity.offline_subtitle': return 'Please check your network and try again.';
			case 'connectivity.reconnecting_title': return 'Reconnecting…';
			case 'connectivity.reconnecting_subtitle': return 'Trying to restore your connection.';
			case 'connectivity.weak_title': return 'Weak connection';
			case 'connectivity.weak_subtitle': return 'Some actions may be slower than usual.';
			case 'connectivity.restored': return 'Connection restored';
			case 'connectivity.action_retry': return 'Retry';
			case 'connectivity.action_settings': return 'Settings';
			case 'campaigns_explorer.filter_all_types': return 'All types';
			case 'campaigns_explorer.filter_all_platforms': return 'All platforms';
			case 'campaigns_explorer.filter_all_niches': return 'All niches';
			case 'campaigns_explorer.filter_all_locations': return 'All locations';
			case 'campaigns_explorer.platform_youtube': return 'YouTube';
			case 'campaigns_explorer.platform_tiktok': return 'TikTok';
			case 'campaigns_explorer.platform_instagram': return 'Instagram';
			case 'campaigns_explorer.results_one': return '1 campaign';
			case 'campaigns_explorer.results_many': return ({required Object n}) => '${n} campaigns';
			case 'campaigns_explorer.layout_grid': return 'Grid view';
			case 'campaigns_explorer.layout_list': return 'List view';
			case 'campaigns_explorer.empty_filters': return 'No campaigns match these filters.';
			case 'campaigns_explorer.empty_filters_subtitle': return 'Clear a filter or change the type — niche options only include campaigns that fit your other choices.';
			case 'campaigns_explorer.search_aria': return 'Search campaigns';
			case 'campaigns_explorer.reset_filters': return 'Reset filters';
			case 'campaigns_explorer.toolbar_show_search_filters': return 'Show search and filters';
			case 'campaigns_explorer.toolbar_hide_search_filters': return 'Hide search and filters';
			case 'campaigns_explorer.filter_label_type': return 'Type';
			case 'campaigns_explorer.filter_label_status': return 'Status';
			case 'campaigns_explorer.filter_label_niche': return 'Niche';
			case 'campaigns_explorer.filter_label_location': return 'Location';
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
			case 'login.apple_cta': return 'Sign in with Apple';
			case 'login.apple_unavailable': return 'Sign in with Apple is not available on this device.';
			case 'login.apple_failed': return 'Apple sign-in failed. Try again.';
			case 'login.apple_server_not_configured': return 'Sign in with Apple is not enabled on the Wayo ID server yet. Ask your administrator to configure Apple credentials on Auth_Wayo (production), then try again.';
			case 'login.apple_canceled': return 'Sign in with Apple was canceled.';
			case 'login.apple_hide_my_email_hint': return 'For verification codes to arrive, choose Share My Email — not Hide My Email when signing in with Apple.';
			case 'login.google_not_configured': return 'Google sign-in is not configured. Add AUTH_GOOGLE_SERVER_CLIENT_ID to dart_defines.json (Web client ID ending in .apps.googleusercontent.com) and do a full restart.';
			case 'login.google_wrong_client_id': return 'AUTH_GOOGLE_SERVER_CLIENT_ID must be your Google Cloud Web client ID (…apps.googleusercontent.com), not the Passport OAuth client UUID.';
			case 'login.google_failed': return 'Google sign-in failed. Try again.';
			case 'login.google_channel_restart': return 'Google Sign-In lost connection to Android (often after hot restart). Stop the app completely, then Run again — do not use hot restart.';
			case 'login.google_android_oauth_misconfigured': return 'Google could not verify this app (code 10). In Google Cloud Console, open the same project as your Web client, create an Android OAuth client with package ma.wayo.wayoadsgo and your debug (or release) keystore SHA-1, then wait a few minutes and try again.';
			case 'login.session_expired_snack': return 'Your session has expired. Please sign in again.';
			case 'login.web_session_title': return 'Already signed in on the web';
			case 'login.web_session_body': return 'This account is still connected on the Wayo Ads website. Sign out from the web before signing in on the app.';
			case 'login.web_session_disconnect': return 'Sign out from web and continue';
			case 'login.web_session_open_browser': return 'Open website to sign out';
			case 'login.web_session_cancel': return 'Cancel';
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
			case 'dashboard.notifications_mark_read': return 'Mark as read';
			case 'dashboard.notifications_dismiss': return 'Dismiss';
			case 'dashboard.notifications_view_all': return 'View all notifications';
			case 'dashboard.notifications_important': return 'Important';
			case 'dashboard.notifications_earlier': return 'Earlier';
			case 'dashboard.notifications_caught_up_title': return 'All caught up!';
			case 'dashboard.notifications_caught_up_subtitle': return 'No new notifications';
			case 'dashboard.notifications_center_title': return 'Notification center';
			case 'dashboard.notifications_unread_count': return '{count} unread notifications';
			case 'dashboard.notifications_all_caught_up': return 'You\'re all caught up';
			case 'dashboard.notifications_tab_all': return 'All';
			case 'dashboard.notifications_tab_archived': return 'Archived';
			case 'dashboard.notifications_search_hint': return 'Search notifications…';
			case 'dashboard.notifications_filter_type_all': return 'All types';
			case 'dashboard.notifications_filter_priority_all': return 'All priorities';
			case 'dashboard.notifications_priority_critical': return 'Critical';
			case 'dashboard.notifications_priority_high': return 'High';
			case 'dashboard.notifications_priority_normal': return 'Normal';
			case 'dashboard.notifications_priority_low': return 'Low';
			case 'dashboard.notifications_load_more': return 'Load more';
			case 'dashboard.notifications_view_details': return 'View details';
			case 'dashboard.notifications_archive': return 'Archive';
			case 'dashboard.notifications_urgent': return 'Urgent';
			case 'dashboard.notifications_just_now': return 'Just now';
			case 'dashboard.notifications_minutes_ago': return '{n} min ago';
			case 'dashboard.notifications_hours_ago': return '{n} h ago';
			case 'dashboard.notifications_days_ago': return '{n} d ago';
			case 'dashboard.notifications_section_all': return 'All notifications';
			case 'dashboard.notifications_section_important': return 'Important alerts';
			case 'dashboard.notifications_section_archived': return 'Archived notifications';
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
			case 'advertiser_campaigns.card.cpm': return 'CPM';
			case 'advertiser_campaigns.card.valid_engagements': return '{count} validated views';
			case 'advertiser_campaigns.card.list_row_views': return '{count} views';
			case 'advertiser_campaigns.card.list_row_clicks': return '{count} clicks';
			case 'advertiser_campaigns.card.list_row_creators': return '{count} creators';
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
			case 'advertiser_campaigns.detail.location_label': return 'Location';
			case 'advertiser_campaigns.detail.objective_label': return 'Objective';
			case 'advertiser_campaigns.detail.objective_awareness': return 'Awareness';
			case 'advertiser_campaigns.detail.objective_traffic': return 'Traffic';
			case 'advertiser_campaigns.detail.objective_conversion': return 'Conversion';
			case 'advertiser_campaigns.detail.cpm_metric': return 'CPM (per 1k views)';
			case 'advertiser_campaigns.detail.cpm_consumed': return 'Consumed CPM (per 1k views)';
			case 'advertiser_campaigns.detail.cpc_metric': return 'CPC (per click)';
			case 'advertiser_campaigns.detail.description_title': return 'Description';
			case 'advertiser_campaigns.detail.show_more': return 'Show more';
			case 'advertiser_campaigns.detail.show_less': return 'Show less';
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
			case 'advertiser_video_reviews.title': return 'Video reviews';
			case 'advertiser_video_reviews.subtitle': return 'Approve or reject creator video submissions for your campaigns.';
			case 'advertiser_video_reviews.pending': return 'Pending';
			case 'advertiser_video_reviews.approved': return 'Approved';
			case 'advertiser_video_reviews.rejected': return 'Rejected';
			case 'advertiser_video_reviews.flagged': return 'Flagged';
			case 'advertiser_video_reviews.empty': return 'No videos in this category.';
			case 'advertiser_video_reviews.load_error': return 'Could not load video submissions';
			case 'advertiser_video_reviews.approve_button': return 'Approve';
			case 'advertiser_video_reviews.reject_button': return 'Reject';
			case 'advertiser_video_reviews.approve_success': return 'Video approved';
			case 'advertiser_video_reviews.reject_success': return 'Video rejected';
			case 'advertiser_video_reviews.reject_reason_required': return 'Please provide a rejection reason';
			case 'advertiser_video_reviews.reject_reason_hint': return 'Reason for rejection';
			case 'advertiser_video_reviews.reject_dialog_title': return 'Reject video';
			case 'advertiser_video_reviews.action_failed': return 'Could not update the video. Try again.';
			case 'advertiser_video_reviews.submitted_at': return 'Submitted';
			case 'advertiser_video_reviews.shorts_badge': return 'Short';
			case 'advertiser_video_reviews.flag_reason': return 'Flag reason';
			case 'advertiser_video_reviews.rejection_reason': return 'Rejection reason';
			case 'advertiser_video_reviews.status_pending': return 'Pending';
			case 'advertiser_video_reviews.status_approved': return 'Approved';
			case 'advertiser_video_reviews.status_rejected': return 'Rejected';
			case 'advertiser_video_reviews.status_flagged': return 'Flagged';
			case 'nav.dashboard': return 'Dashboard';
			case 'nav.campaigns': return 'Campaigns';
			case 'nav.analytics': return 'Analytics';
			case 'nav.wallet': return 'Wallet';
			case 'nav.chat': return 'Chat';
			case 'nav.invoices': return 'Invoices';
			case 'nav.invoices_creator': return 'Statements';
			case 'invoices.title': return 'Invoices';
			case 'invoices.title_creator': return 'Payment statements';
			case 'invoices.subtitle_advertiser': return 'Every deposit and campaign budget — all in one place.';
			case 'invoices.subtitle_creator': return 'Every earning and payout — secured, downloadable, signed.';
			case 'invoices.summary_total_paid': return 'Total paid';
			case 'invoices.summary_total_validated': return 'Total validated';
			case 'invoices.summary_pending': return 'Pending';
			case 'invoices.summary_count': return 'Documents';
			case 'invoices.filter_all': return 'All';
			case 'invoices.filter_deposits': return 'Deposits';
			case 'invoices.filter_billing': return 'Campaign budget';
			case 'invoices.filter_payouts': return 'Payouts';
			case 'invoices.filter_earnings': return 'Earnings';
			case 'invoices.type_deposit': return 'Wallet deposit';
			case 'invoices.type_billing': return 'Campaign budget';
			case 'invoices.type_payout': return 'Creator payout';
			case 'invoices.type_earnings': return 'Ad earnings';
			case 'invoices.type_unknown': return 'Other';
			case 'invoices.status_paid': return 'Paid';
			case 'invoices.status_validated': return 'Validated';
			case 'invoices.status_pending': return 'Pending';
			case 'invoices.status_cancelled': return 'Cancelled';
			case 'invoices.role_advertiser': return 'Advertiser';
			case 'invoices.role_creator': return 'Creator';
			case 'invoices.search_hint': return 'Search by number, reference…';
			case 'invoices.empty_title': return 'No invoice yet';
			case 'invoices.empty_subtitle': return 'Your wallet deposits, campaign budgets and creator payouts will appear here automatically — no manual step required.';
			case 'invoices.empty_subtitle_creator': return 'Your earnings and payout documents will show up here as soon as they are issued — same signed PDFs as on the web.';
			case 'invoices.empty_cta': return 'Refresh';
			case 'invoices.error_title': return 'Could not load invoices';
			case 'invoices.error_subtitle': return 'Pull to refresh — we\'ll try again right away.';
			case 'invoices.load_more': return 'Load more';
			case 'invoices.pagination_meta': return 'Page {current} of {total}';
			case 'invoices.pagination_previous': return 'Previous';
			case 'invoices.pagination_next': return 'Next';
			case 'invoices.date_preset_all': return 'All dates';
			case 'invoices.date_preset_30d': return '30 days';
			case 'invoices.date_preset_90d': return '90 days';
			case 'invoices.date_preset_custom': return 'Custom';
			case 'invoices.details_title': return 'Invoice {number}';
			case 'invoices.details_section_summary': return 'Summary';
			case 'invoices.details_section_actions': return 'Actions';
			case 'invoices.details_section_legal': return 'Legal & references';
			case 'invoices.details_invoice_number': return 'Invoice number';
			case 'invoices.details_issued_at': return 'Issued on';
			case 'invoices.details_paid_at': return 'Paid on';
			case 'invoices.details_type': return 'Type';
			case 'invoices.details_status': return 'Status';
			case 'invoices.details_role': return 'Role';
			case 'invoices.details_reference': return 'Reference';
			case 'invoices.details_amount': return 'Total';
			case 'invoices.details_tax': return 'VAT included';
			case 'invoices.details_currency': return 'Currency';
			case 'invoices.action_download_pdf': return 'Download PDF';
			case 'invoices.action_share_pdf': return 'Share';
			case 'invoices.action_open_pdf': return 'Open';
			case 'invoices.action_copy_number': return 'Copy invoice #';
			case 'invoices.action_view_details': return 'View details';
			case 'invoices.download_progress': return 'Preparing your PDF…';
			case 'invoices.download_success': return 'Saved to {filename}';
			case 'invoices.download_error': return 'Download failed. Please try again.';
			case 'invoices.copied_to_clipboard': return 'Invoice number copied.';
			case 'invoices.share_subject': return 'Invoice {number}';
			case 'invoices.polling_live': return 'Live';
			case 'invoices.polling_paused': return 'Paused';
			case 'invoices.summary_this_month': return 'This month';
			case 'invoices.pagination_detail': return 'Page {current} of {total} · {count} invoices';
			case 'invoices.sort_sheet_title': return 'Sort';
			case 'invoices.sort_date_newest': return 'Newest first';
			case 'invoices.sort_date_oldest': return 'Oldest first';
			case 'invoices.sort_amount_high': return 'Amount · high to low';
			case 'invoices.sort_amount_low': return 'Amount · low to high';
			case 'invoices.sort_status_az': return 'Status · A to Z';
			case 'invoices.sort_status_za': return 'Status · Z to A';
			case 'invoices.date_range_title': return 'Dates';
			case 'invoices.date_from': return 'From';
			case 'invoices.date_to': return 'To';
			case 'invoices.clear_dates': return 'Clear';
			case 'invoices.date_apply': return 'Apply';
			case 'invoices.download_all_zip': return 'ZIP';
			case 'invoices.zip_progress': return 'Building ZIP…';
			case 'invoices.zip_success': return 'Saved {filename}';
			case 'invoices.zip_error': return 'ZIP download failed.';
			case 'push.onboarding_title': return 'Stay in the loop';
			case 'push.onboarding_subtitle': return 'Get instant alerts when something important happens — even when Wayo Ads is in the background.';
			case 'push.onboarding_bullet_campaigns': return 'Campaign updates, applications and budgets';
			case 'push.onboarding_bullet_messages': return 'New chat messages';
			case 'push.onboarding_bullet_system': return 'Invoices, payouts and platform alerts';
			case 'push.onboarding_enable': return 'Turn on notifications';
			case 'push.onboarding_later': return 'Not now';
			case 'push.onboarding_success': return 'Notifications enabled';
			case 'push.onboarding_denied_hint': return 'You can enable them anytime in system settings.';
			case 'push.onboarding_context_chat': return 'You just received a new chat message — turn on alerts so you never miss a reply.';
			case 'push.onboarding_context_campaign': return 'A campaign status changed — enable notifications to stay on top of applications and budgets.';
			case 'push.onboarding_context_invoice': return 'A new invoice or payout update is ready — get notified as soon as money moves.';
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
			case 'creator.wallet.withdraw_amount_label': return 'Amount (USD)';
			case 'creator.wallet.withdraw_sheet_body': return 'Enter the amount you wish to withdraw. Funds will be sent to your connected bank account.';
			case 'creator.wallet.withdraw_quick_amounts': return 'Quick amounts';
			case 'creator.wallet.withdraw_gross_amount': return 'Gross amount';
			case 'creator.wallet.withdraw_platform_fee': return 'Platform fee ({percent}%)';
			case 'creator.wallet.withdraw_tax_vat': return 'VAT ({percent}%)';
			case 'creator.wallet.withdraw_net_received': return 'Net received';
			case 'creator.wallet.withdraw_submit': return 'Confirm withdrawal';
			case 'creator.wallet.withdraw_submitting': return 'Processing…';
			case 'creator.wallet.withdraw_max': return 'Max';
			case 'creator.wallet.withdraw_preset_all': return 'All';
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
			case 'creator.wallet.stripe_edit_business_action': return 'Edit business details';
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
			case 'creator.campaigns.earnings_card_title': return 'My earnings from this campaign';
			case 'creator.campaigns.earnings_card_subtitle': return 'Your performance and payout breakdown';
			case 'creator.campaigns.earnings_net': return 'Net earnings';
			case 'creator.campaigns.earnings_views': return 'Earnings views';
			case 'creator.campaigns.earnings_platform_views': return 'Platform views';
			case 'creator.campaigns.earnings_valid_clicks': return 'Earnings clicks';
			case 'creator.campaigns.earnings_recorded_clicks': return 'Recorded clicks';
			case 'creator.campaigns.earnings_available_balance': return 'Available balance';
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
			case 'creator.business.section_type': return 'Business type';
			case 'creator.business.section_company': return 'Company';
			case 'creator.business.section_address': return 'Address';
			case 'creator.business.section_stripe': return 'Payout country & currency';
			case 'creator.business.type_personal_title': return 'Individual / Private person';
			case 'creator.business.type_personal_subtitle': return 'I receive payouts as a private person.';
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
			case 'advertiser_wallet.quick_50': return '50 USD';
			case 'advertiser_wallet.quick_100': return '100 USD';
			case 'advertiser_wallet.quick_250': return '500 USD';
			case 'advertiser_wallet.min_deposit': return 'Minimum deposit is 50.00 USD.';
			case 'advertiser_wallet.test_pay': return 'Simulate payment (dev)';
			case 'advertiser_wallet.test_hint': return 'Test mode: no real card. Tops up your dev wallet for QA.';
			case 'advertiser_wallet.pay_secure': return 'Pay with card, Apple Pay or Google Pay';
			case 'advertiser_wallet.pay_with_card': return 'Pay with card';
			case 'advertiser_wallet.pay_with_apple': return 'Pay with Apple Pay';
			case 'advertiser_wallet.pay_with_google': return 'Pay with Google Pay';
			case 'advertiser_wallet.or': return 'or';
			case 'advertiser_wallet.stripe_unavailable': return 'Top-ups are not available: payment is not configured on the server.';
			case 'advertiser_wallet.stripe_keys_mismatch': return 'Payment is misconfigured on the server (Stripe test/live keys mixed). Contact support.';
			case 'advertiser_wallet.apple_pay_test_hint': return 'Stripe test mode: Apple Pay uses your Wallet card but no real charge is made.';
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
			case 'advertiser_wallet.business_profile_gate_title': return 'Business details required';
			case 'advertiser_wallet.business_profile_gate_body': return 'Add valid billing information before adding funds. This keeps invoices and compliance aligned with Wayo Ads.';
			case 'advertiser_wallet.business_profile_gate_secure': return 'Encrypted connection — verified on our servers before any charge.';
			case 'advertiser_wallet.business_profile_gate_cta': return 'Complete business information';
			case 'advertiser_wallet.business_profile_error': return 'Could not load business profile.';
			case 'advertiser_wallet.pay_locked_until_business': return 'Payment unlocks once your business profile is complete.';
			case 'advertiser_wallet.payment_title': return 'Payment';
			case 'advertiser_wallet.payment_total': return 'TOTAL';
			case 'advertiser_wallet.payment_deposit_amount': return 'Deposit amount';
			case 'advertiser_wallet.payment_bank_fee': return 'Bank transaction fee (3.69%)';
			case 'advertiser_wallet.deposit_pending': return 'Deposit pending';
			case 'advertiser_wallet.deposit_resume_hint': return 'Resuming your deposit of {amount} — complete payment or tap Cancel to discard.';
			case 'advertiser_wallet.deposit_cancel': return 'Cancel';
			case 'chat.inbox_title': return 'Messages';
			case 'chat.inbox_subtitle': return 'Secure conversations for your campaigns';
			case 'chat.conversation_unknown': return 'Conversation';
			case 'chat.thread_fallback_title': return 'Chat';
			case 'chat.composer_hint': return 'Write a message…';
			case 'chat.typing': return 'Typing…';
			case 'chat.error_load_threads': return 'Could not load your conversations. Try again.';
			case 'chat.error_phone': return 'Sharing phone numbers in chat is not allowed.';
			case 'chat.spam_cooldown_title': return 'You\'re sending messages too fast';
			case 'chat.spam_cooldown_body': return ({required Object seconds}) => 'Please wait ${seconds} s before sending again.';
			case 'chat.spam_cooldown_seconds': return ({required Object seconds}) => '${seconds} s';
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
			case 'chat.bubble_forward': return 'Forward';
			case 'chat.share_media_tooltip': return 'Share';
			case 'chat.share_failed': return 'Could not share this file. Try again.';
			case 'chat.forward_sheet_title': return 'Forward to…';
			case 'chat.forward_no_other_chats': return 'You need another conversation open first.';
			case 'chat.forward_sending': return 'Forwarding…';
			case 'chat.forward_ok': return 'Message forwarded.';
			case 'chat.forward_failed': return 'Forward failed.';
			case 'chat.forward_view': return 'Open';
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
			case 'chat.loading_older_messages': return 'Loading earlier messages…';
			case 'chat.load_older_failed': return 'Could not load earlier messages.';
			case 'chat.image_download_tooltip': return 'Download photo';
			case 'chat.image_close_tooltip': return 'Close';
			case 'chat.image_saved_to_gallery': return 'Photo saved to your gallery.';
			case 'chat.image_download_failed': return 'Couldn\'t download this photo.';
			case 'chat.image_permission_denied': return 'Photos access denied. Allow it in your device settings.';
			case 'chat.image_saved_downloads_browser': return 'Photo downloaded — check your Downloads folder.';
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
			case 'app_settings.theme_hint': return 'Choose how Wayo Ads looks. The theme follows your phone’s settings.';
			case 'app_settings.language_hint': return 'Sets the interface language. Dates and formats adapt to your chosen language.';
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
			case 'app_settings.section_notifications': return 'Notifications';
			case 'app_settings.notifications_toggle': return 'Push notifications';
			case 'app_settings.notifications_hint': return 'Alerts for campaigns, chat, invoices and payouts. Requires permission in your phone settings.';
			case 'app_settings.notifications_status_enabled': return 'Enabled — you will receive alerts on this device';
			case 'app_settings.notifications_status_disabled': return 'Disabled in the app';
			case 'app_settings.notifications_status_permission_denied': return 'Allow notifications in your phone settings to receive alerts';
			case 'app_settings.notifications_open_settings': return 'Open phone settings';
			case 'app_settings.notifications_enable_error': return 'Could not enable notifications. Check system settings.';
			case 'app_settings.notifications_update_error': return 'Could not update notification settings. Try again.';
			case 'app_settings.section_account': return 'Account';
			case 'app_settings.delete_account_entry': return 'Delete account';
			case 'app_settings.delete_account_entry_sub': return '30-day grace — manage deletion in the app';
			case 'app_settings.section_about': return 'About';
			case 'app_settings.rate_app': return 'Rate Wayo Ads';
			case 'app_settings.rate_app_sub': return 'Open the App Store or Google Play';
			case 'account_deletion.nav_title': return 'Delete account';
			case 'account_deletion.title': return 'Delete my Wayo Ads account';
			case 'account_deletion.danger_zone_chip': return 'Danger Zone';
			case 'account_deletion.danger_zone_intro': return 'Permanently delete your account and all associated data. This action cannot be undone after the grace period.';
			case 'account_deletion.danger_what_title': return 'What will be deleted:';
			case 'account_deletion.danger_item_profile': return 'Your profile and personal information';
			case 'account_deletion.danger_item_campaigns': return 'All your campaigns and their performance data';
			case 'account_deletion.danger_item_business': return 'Your business profile and brand information';
			case 'account_deletion.danger_item_wallet': return 'Your advertiser wallet and transaction history';
			case 'account_deletion.danger_item_notifications': return 'Your notifications and email preferences';
			case 'account_deletion.danger_item_access': return 'Your access to Wayo Ads (you will not be able to sign in again here)';
			case 'account_deletion.danger_wayo_note': return 'Only your Wayo Ads data is affected. Your Wayo account (used to sign in) stays active for other Wayo services.';
			case 'account_deletion.subtitle_warning': return 'Important: after 30 days, your Wayo Ads data will be permanently removed. You can cancel anytime before then.';
			case 'account_deletion.bullet_loss': return 'Campaigns, applications, and app-side profile data will be deleted after the grace period.';
			case 'account_deletion.bullet_wallet': return 'Wallet balance, invoices, and transaction history tied to this account will be removed.';
			case 'account_deletion.bullet_cancel': return 'Free cancellation window: 30 days from your request.';
			case 'account_deletion.bullet_recreate': return 'Your Wayo ID (login) is not deleted by this step — you may sign in again and get a fresh app profile later.';
			case 'account_deletion.role_advertiser': return 'Advertiser: active campaigns will stop when data is purged.';
			case 'account_deletion.role_creator': return 'Creator: applications, channels, and earnings records in the app will be deleted.';
			case 'account_deletion.continue_cta': return 'Continue';
			case 'account_deletion.back': return 'Back';
			case 'account_deletion.more_info_title': return 'Before you go';
			case 'account_deletion.more_info_body': return 'Emails: you will receive a confirmation now and a reminder about 3 days before deletion.\nSupport: contact us if you need help exporting information or closing campaigns first.';
			case 'account_deletion.step_auth_title': return 'Confirm your identity';
			case 'account_deletion.status_active': return 'No deletion scheduled for this account.';
			case 'account_deletion.status_pending': return ({required Object date}) => 'Deletion already scheduled. Final date: ${date}';
			case 'account_deletion.password_label': return 'Password';
			case 'account_deletion.password_hint': return 'At least 8 characters';
			case 'account_deletion.forgot_password': return 'Forgot password?';
			case 'account_deletion.oauth_note': return 'If you only sign in with Google or Apple, set a password first (Forgot password).';
			case 'account_deletion.oauth_deletion_intro': return 'You use Google or Apple to sign in. After you continue, confirm in the next step — no password required.';
			case 'account_deletion.oauth_deletion_step_hint': return 'Your identity was confirmed when you signed in with Google or Apple. Tap below to review the final confirmation sheet.';
			case 'account_deletion.legal_recap': return ({required Object date}) => 'You will start a 30-day grace period before permanent deletion. You can cancel until ${date}.';
			case 'account_deletion.next_review': return 'Review and confirm';
			case 'account_deletion.dialog_title': return 'Are you sure?';
			case 'account_deletion.dialog_body': return 'Your Wayo Ads data will be scheduled for deletion. Final removal on:';
			case 'account_deletion.dialog_cancel_hint': return 'You can cancel anytime in Settings until that date.';
			case 'account_deletion.timeline_request': return 'Request';
			case 'account_deletion.timeline_reminder': return 'Email reminder';
			case 'account_deletion.timeline_purge': return 'Deletion';
			case 'account_deletion.dialog_confirm': return 'Yes, schedule deletion';
			case 'account_deletion.dialog_dismiss': return 'Keep my account';
			case 'account_deletion.success_title': return 'Deletion scheduled';
			case 'account_deletion.success_intro': return 'What happens next?';
			case 'account_deletion.success_use_until': return 'You can keep using Wayo Ads until the final date.';
			case 'account_deletion.success_reminder': return 'We will email you a reminder a few days before deletion.';
			case 'account_deletion.success_cancel_anytime': return 'Cancel anytime from this screen or Settings.';
			case 'account_deletion.days_left': return ({required Object n}) => 'Days left: ${n}';
			case 'account_deletion.purge_date': return ({required Object date}) => 'Final deletion: ${date}';
			case 'account_deletion.reminder_approx': return ({required Object date}) => 'Reminder around: ${date}';
			case 'account_deletion.cancel_request': return 'Cancel deletion';
			case 'account_deletion.go_home': return 'Back to home';
			case 'account_deletion.toast_cancelled': return 'Deletion cancelled. Your account is restored.';
			case 'account_deletion.error_load': return 'Could not load account status.';
			case 'account_deletion.error_load_unauthorized': return 'We could not verify your session with Wayo Ads. Sign out and sign in again, then retry.';
			case 'account_deletion.error_load_network': return 'Check your connection and that Wayo Ads is reachable, then retry.';
			case 'account_deletion.error_delete': return 'Something went wrong. Please try again.';
			case 'account_deletion.error_password': return 'Incorrect password. Try again or reset your password.';
			case 'account_deletion.banner_line': return ({required Object date, required Object n}) => 'Your account will be deleted on ${date} (${n} days left).';
			case 'account_deletion.banner_cancel_dialog_title': return 'Cancel scheduled deletion?';
			case 'account_deletion.banner_cancel_dialog_body': return 'Your Wayo Ads profile will stay active.';
			case 'account_deletion.banner_cancel_dialog_confirm': return 'Keep my account';
			case 'account_deletion.pending_danger_card_body': return ({required Object date}) => 'Your account is scheduled for permanent deletion on ${date}. You can cancel this request at any time before that date.';
			case 'account_deletion.pending_scheduled_status': return 'Account deletion scheduled';
			case 'account_deletion.pending_days_remaining_one': return '1 day remaining';
			case 'account_deletion.pending_days_remaining_plural': return ({required Object n}) => '${n} days remaining';
			case 'onboarding.role_gate_title': return 'Choose your profile';
			case 'onboarding.role_gate_subtitle': return 'Same step as on the Wayo Ads website before you can use the app.';
			case 'onboarding.role_creator_cta': return 'Creator';
			case 'onboarding.role_creator_desc': return 'Browse campaigns, apply, and collaborate with brands.';
			case 'onboarding.role_advertiser_cta': return 'Advertiser';
			case 'onboarding.role_advertiser_desc': return 'Launch campaigns and manage creators from your dashboard.';
			case 'onboarding.email_code_title': return 'Verify your email';
			case 'onboarding.email_code_subtitle': return ({required Object email}) => 'Enter the 6-digit code we sent to ${email}.';
			case 'onboarding.email_code_subtitle_prefix': return 'Enter the 6-digit code we sent to ';
			case 'onboarding.email_code_subtitle_suffix': return '.';
			case 'onboarding.email_code_hide_my_email_warning': return 'You signed in with Apple\'s Hide My Email. Verification codes often don\'t reach relay addresses. Sign out, then sign in with Apple again and choose Share My Email, or use email and password with your real iCloud address.';
			case 'onboarding.email_code_otp_label': return 'Enter verification code';
			case 'onboarding.email_code_sending': return 'Sending code...';
			case 'onboarding.email_code_verifying': return 'Verifying...';
			case 'onboarding.skip': return 'Skip';
			case 'onboarding.next': return 'Next';
			case 'onboarding.done': return 'Got it';
			case 'onboarding.advertiser.dashboard_title': return 'Your dashboard';
			case 'onboarding.advertiser.dashboard_subtitle': return 'Track balance, active campaigns and notifications — all updates land here in real time.';
			case 'onboarding.advertiser.campaigns_title': return 'Campaigns';
			case 'onboarding.advertiser.campaigns_subtitle': return 'Create new campaigns, review applications and monitor performance in one place.';
			case 'onboarding.advertiser.wallet_title': return 'Wallet';
			case 'onboarding.advertiser.wallet_subtitle': return 'Top up your budget and track spending — secured by Stripe.';
			case 'onboarding.advertiser.invoices_title': return 'Invoices';
			case 'onboarding.advertiser.invoices_subtitle': return 'Download signed PDFs for deposits, campaign billing and transfers — all in one place.';
			case 'onboarding.advertiser.chat_title': return 'Chat';
			case 'onboarding.advertiser.chat_subtitle': return 'Talk to your creators once a campaign is approved. Conversations stay in sync across devices.';
			case 'onboarding.creator.dashboard_title': return 'Creator dashboard';
			case 'onboarding.creator.dashboard_subtitle': return 'Your KPIs, active applications and earnings refresh automatically — no need to pull to refresh.';
			case 'onboarding.creator.campaigns_title': return 'Browse & apply';
			case 'onboarding.creator.campaigns_subtitle': return 'Discover eligible campaigns, apply in one tap and follow your application status live.';
			case 'onboarding.creator.wallet_title': return 'Earnings & payouts';
			case 'onboarding.creator.wallet_subtitle': return 'See your balance, request payouts via Stripe Connect and review past withdrawals.';
			case 'onboarding.creator.invoices_title': return 'Payment statements';
			case 'onboarding.creator.invoices_subtitle': return 'Filter earnings and payouts, download signed PDFs or a ZIP — refreshed automatically while you use the app.';
			case 'onboarding.creator.chat_title': return 'Talk to advertisers';
			case 'onboarding.creator.chat_subtitle': return 'Once approved, the chat opens with your advertiser to align on deliverables.';
			default: return null;
		}
	}
}

