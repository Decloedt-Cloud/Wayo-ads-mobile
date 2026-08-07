///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsAr extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsAr _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsForceUpdateAr force_update = _TranslationsForceUpdateAr._(_root);
	@override late final _TranslationsMaintenanceAr maintenance = _TranslationsMaintenanceAr._(_root);
	@override late final _TranslationsConnectivityAr connectivity = _TranslationsConnectivityAr._(_root);
	@override late final _TranslationsCampaignsExplorerAr campaigns_explorer = _TranslationsCampaignsExplorerAr._(_root);
	@override late final _TranslationsLoginAr login = _TranslationsLoginAr._(_root);
	@override late final _TranslationsSignupAr signup = _TranslationsSignupAr._(_root);
	@override late final _TranslationsVerifyEmailAr verify_email = _TranslationsVerifyEmailAr._(_root);
	@override late final _TranslationsVerifyAr verify = _TranslationsVerifyAr._(_root);
	@override late final _TranslationsForgotPasswordAr forgot_password = _TranslationsForgotPasswordAr._(_root);
	@override late final _TranslationsOtpAr otp = _TranslationsOtpAr._(_root);
	@override late final _TranslationsResetPasswordAr reset_password = _TranslationsResetPasswordAr._(_root);
	@override late final _TranslationsValidationAr validation = _TranslationsValidationAr._(_root);
	@override late final _TranslationsPasswordReqAr password_req = _TranslationsPasswordReqAr._(_root);
	@override late final _TranslationsHomeAr home = _TranslationsHomeAr._(_root);
	@override late final _TranslationsDashboardAr dashboard = _TranslationsDashboardAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsAr advertiser_campaigns = _TranslationsAdvertiserCampaignsAr._(_root);
	@override late final _TranslationsAdvertiserVideoReviewsAr advertiser_video_reviews = _TranslationsAdvertiserVideoReviewsAr._(_root);
	@override late final _TranslationsNavAr nav = _TranslationsNavAr._(_root);
	@override late final _TranslationsInvoicesAr invoices = _TranslationsInvoicesAr._(_root);
	@override late final _TranslationsPushAr push = _TranslationsPushAr._(_root);
	@override late final _TranslationsCreatorAr creator = _TranslationsCreatorAr._(_root);
	@override late final _TranslationsAdvertiserWalletAr advertiser_wallet = _TranslationsAdvertiserWalletAr._(_root);
	@override late final _TranslationsChatAr chat = _TranslationsChatAr._(_root);
	@override late final _TranslationsCommonAr common = _TranslationsCommonAr._(_root);
	@override late final _TranslationsErrorsAr errors = _TranslationsErrorsAr._(_root);
	@override late final _TranslationsPrivacyPolicyAr privacy_policy = _TranslationsPrivacyPolicyAr._(_root);
	@override late final _TranslationsTermsAndConditionsAr terms_and_conditions = _TranslationsTermsAndConditionsAr._(_root);
	@override late final _TranslationsCookiePolicyAr cookie_policy = _TranslationsCookiePolicyAr._(_root);
	@override late final _TranslationsAppSettingsAr app_settings = _TranslationsAppSettingsAr._(_root);
	@override late final _TranslationsProfileAr profile = _TranslationsProfileAr._(_root);
	@override late final _TranslationsSecurityAr security = _TranslationsSecurityAr._(_root);
	@override late final _TranslationsAccountDeletionAr account_deletion = _TranslationsAccountDeletionAr._(_root);
	@override late final _TranslationsOnboardingAr onboarding = _TranslationsOnboardingAr._(_root);
}

// Path: force_update
class _TranslationsForceUpdateAr extends TranslationsForceUpdateEn {
	_TranslationsForceUpdateAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مطلوب تحديث';
	@override String get subtitle => 'يتوفر إصدار جديد من Wayo Ads. يرجى التحديث من المتجر للمتابعة.';
	@override String get action_update => 'تحديث الآن';
	@override String get checking => 'جاري التحقق من التحديثات…';
}

// Path: maintenance
class _TranslationsMaintenanceAr extends TranslationsMaintenanceEn {
	_TranslationsMaintenanceAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'سنعود قريباً';
	@override String get subtitle => 'نقوم بترقية الخدمة بميزات جديدة. سنعود قريباً.';
	@override String get apology => 'نعتذر عن الإزعاج ونقدّر صبركم.';
	@override String get copyright => '© 2026 Wayo Ads. جميع الحقوق محفوظة.';
	@override String get support_email => 'support@wayo.cloud';
	@override String get action_retry => 'إعادة المحاولة';
}

// Path: connectivity
class _TranslationsConnectivityAr extends TranslationsConnectivityEn {
	_TranslationsConnectivityAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get offline_title => 'لا يوجد اتصال بالإنترنت';
	@override String get offline_subtitle => 'تحقق من Wi‑Fi أو بيانات الجوال ثم أعد المحاولة.';
	@override String get offline_subtitle_radio_up => 'يبدو أن الشبكة متصلة، لكننا لا نصل إلى الإنترنت أو خوادم Wayo. أعد المحاولة أو افتح إعدادات الشبكة.';
	@override String get reconnecting_title => 'إعادة الاتصال…';
	@override String get reconnecting_subtitle => 'جاري محاولة استعادة الاتصال.';
	@override String get weak_title => 'اتصال ضعيف';
	@override String get weak_subtitle => 'قد تكون بعض الإجراءات أبطأ من المعتاد.';
	@override String get restored => 'تم استعادة الاتصال';
	@override String get action_retry => 'إعادة المحاولة';
	@override String get action_settings => 'إعدادات الشبكة';
	@override String get settings_unavailable => 'تعذّر فتح إعدادات النظام.';
}

// Path: campaigns_explorer
class _TranslationsCampaignsExplorerAr extends TranslationsCampaignsExplorerEn {
	_TranslationsCampaignsExplorerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get filter_all_types => 'كل الأنواع';
	@override String get filter_all_platforms => 'كل المنصات';
	@override String get filter_all_niches => 'كل المجالات';
	@override String get filter_all_locations => 'كل المواقع';
	@override String get platform_youtube => 'YouTube';
	@override String get platform_tiktok => 'TikTok';
	@override String get platform_instagram => 'Instagram';
	@override String get results_one => 'حملة واحدة';
	@override String results_many({required Object n}) => '${n} حملة';
	@override String get layout_grid => 'شبكة';
	@override String get layout_list => 'قائمة';
	@override String get empty_filters => 'لا توجد حملات مطابقة لهذه المرشحات.';
	@override String get empty_filters_subtitle => 'أزل أحد المرشحات أو غيّر نوع الحملة — خيارات المجال تعرض ما ينسجم مع بقية اختياراتك.';
	@override String get search_aria => 'البحث في الحملات';
	@override String get reset_filters => 'إعادة ضبط المرشحات';
	@override String get toolbar_show_search_filters => 'إظهار البحث والمرشحات';
	@override String get toolbar_hide_search_filters => 'إخفاء البحث والمرشحات';
	@override String get filter_label_type => 'النوع';
	@override String get filter_label_status => 'الحالة';
	@override String get filter_label_niche => 'المجال';
	@override String get filter_label_location => 'الموقع';
}

// Path: login
class _TranslationsLoginAr extends TranslationsLoginEn {
	_TranslationsLoginAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get brand => 'وايو أدز';
	@override String get headline_line1 => 'مرحبًا بك';
	@override String get headline_line2_prefix => 'في ';
	@override String get headline_brand => 'وايو أدز';
	@override String get subtitle => 'سجّل الدخول بحساب Wayo ID لإدارة حملاتك وتعاوناتك.';
	@override String get cta => 'تسجيل الدخول إلى وايو أدز';
	@override String get secure_note => 'مصادقة آمنة عبر Wayo ID';
	@override String get terms_prefix => 'بالمتابعة، فإنك توافق على ';
	@override String get terms => 'شروط الاستخدام';
	@override String get and => ' و';
	@override String get privacy => 'سياسة الخصوصية';
	@override String get dot => '.';
	@override String get email_label => 'البريد الإلكتروني';
	@override String get password_label => 'كلمة المرور';
	@override String get show_password => 'إظهار';
	@override String get hide_password => 'إخفاء';
	@override String get email_required => 'البريد مطلوب';
	@override String get email_invalid => 'بريد غير صالح';
	@override String get password_required => 'كلمة المرور مطلوبة';
	@override String get password_min => '6 أحرف على الأقل';
	@override String get rate_limit_title => 'يرجى الانتظار';
	@override String get rate_limit_body => 'محاولات تسجيل دخول كثيرة جدًا.';
	@override String rate_limit_remaining({required Object seconds}) => 'أعد المحاولة خلال ${seconds} ث';
	@override String get forgot_password_link => 'نسيت كلمة المرور؟';
	@override String get google_cta => 'المتابعة عبر Google';
	@override String get apple_cta => 'تسجيل الدخول عبر Apple';
	@override String get apple_unavailable => 'تسجيل الدخول عبر Apple غير متاح على هذا الجهاز.';
	@override String get apple_failed => 'فشل تسجيل الدخول عبر Apple. حاول مرة أخرى.';
	@override String get apple_server_not_configured => 'تسجيل الدخول عبر Apple غير مفعّل على خادم Wayo ID بعد. اطلب من المسؤول إعداد Apple على Auth_Wayo (الإنتاج)، ثم أعد المحاولة.';
	@override String get apple_canceled => 'تم إلغاء تسجيل الدخول عبر Apple.';
	@override String get apple_hide_my_email_hint => 'لاستلام رمز التحقق، اختر مشاركة بريدي الإلكتروني — وليس إخفاء بريدي الإلكتروني عند تسجيل الدخول عبر Apple.';
	@override String get google_not_configured => 'لم يُضبط تسجيل الدخول عبر Google. أضف AUTH_GOOGLE_SERVER_CLIENT_ID في dart_defines.json (معرّف عميل الويب من Google ينتهي بـ .apps.googleusercontent.com) ثم أعد تشغيل التطبيق بالكامل.';
	@override String get google_wrong_client_id => 'يجب أن يكون AUTH_GOOGLE_SERVER_CLIENT_ID هو معرّف عميل الويب في Google Cloud (…apps.googleusercontent.com) وليس UUID عميل OAuth في Passport.';
	@override String get google_failed => 'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.';
	@override String get google_channel_restart => 'انقطع اتصال Google مع أندرويد (غالبًا بعد hot restart). أوقف التطبيق بالكامل ثم شغّله من جديد — لا تستخدم hot restart.';
	@override String get google_android_oauth_misconfigured => 'تعذّر على Google التحقق من التطبيق (رمز 10). في Google Cloud Console ونفس مشروع معرّف العميل للويب: أنشئ عميل OAuth من نوع Android باسم الحزمة ma.wayo.wayoadsgo وبصمة SHA-1 لبيانات الاعتماد (تطوير أو إصدار)، انتظر بضع دقائق ثم أعِد المحاولة.';
	@override String get session_expired_snack => 'انتهت جلستك. يُرجى تسجيل الدخول مرة أخرى.';
	@override String get web_session_title => 'الحساب نشط بالفعل';
	@override String get web_session_body => 'هذا الحساب نشط على جهاز آخر. هل تريد قطع اتصال الجهاز الآخر وتسجيل الدخول من هنا؟';
	@override String get web_session_disconnect => 'قطع اتصال الجهاز الآخر';
	@override String get web_session_disconnecting => 'جارٍ قطع الاتصال…';
	@override String get web_session_cancel => 'إلغاء';
}

// Path: signup
class _TranslationsSignupAr extends TranslationsSignupEn {
	_TranslationsSignupAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get role_title => 'إنشاء حساب Wayo Ads';
	@override String get role_subtitle => 'اختر كيف ستستخدم Wayo Ads — نفس الخطوة على الموقع.';
	@override String get create_account => 'إنشاء حساب';
	@override String get create_account_link => 'إنشاء حساب';
	@override String get no_account_yet => 'ليس لديك حساب؟';
	@override String register_subtitle({required Object role}) => 'سجّل كـ ${role} بالبريد أو تابع مع Google أو Apple.';
	@override String get name_label => 'الاسم الكامل';
	@override String get name_required => 'الاسم مطلوب';
	@override String get confirm_password_label => 'تأكيد كلمة المرور';
	@override String get password_need_symbol => 'مطلوب رمز (!@#%…)';
	@override String get register_cta => 'إنشاء حساب';
	@override String get google_cta => 'إنشاء حساب عبر Google';
	@override String get apple_cta => 'إنشاء حساب عبر Apple';
	@override String get already_have_account => 'لديك حساب بالفعل؟';
	@override String get sign_in_link => 'تسجيل الدخول';
	@override String get verify_then_sign_in => 'تم تأكيد البريد. سجّل الدخول بكلمة المرور.';
	@override String get name_taken => 'هذا الاسم مستخدم بالفعل. يرجى اختيار اسم آخر.';
	@override String get email_taken => 'هذا البريد الإلكتروني مسجّل بالفعل. سجّل الدخول بدلاً من ذلك.';
	@override String get disposable_email => 'عناوين البريد الإلكتروني المؤقتة غير مسموح بها.';
	@override String get name_check_failed => 'تعذّر التحقق من هذا الاسم الآن. يرجى المحاولة مرة أخرى.';
	@override String get email_check_failed => 'تعذّر التحقق من هذا البريد الإلكتروني الآن. يرجى المحاولة مرة أخرى.';
	@override String get legal_prefix => 'لقد قرأت وأوافق على ';
	@override String get terms_of_service => 'شروط الخدمة';
	@override String get privacy_policy => 'سياسة الخصوصية';
	@override String get cookie_policy => 'سياسة ملفات تعريف الارتباط';
	@override String get legal_comma => ' و';
	@override String get legal_and => ' و';
	@override String get legal_dot => '.';
	@override String get legal_required => 'يرجى قبول الشروط لإنشاء حسابك.';
	@override String get back_cta => 'رجوع';
}

// Path: verify_email
class _TranslationsVerifyEmailAr extends TranslationsVerifyEmailEn {
	_TranslationsVerifyEmailAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'أكّد بريدك الإلكتروني';
	@override String get subtitle => 'يتطلب Wayo ID عنوانًا مُؤكدًا (كما على الموقع). افتح الرابط الذي أرسلناه إلى:';
	@override String get check_again => 'تم التأكيد — متابعة';
	@override String get open_mail => 'فتح تطبيق البريد';
	@override String get still_pending => 'ما زالت التحقق قيد الانتظار. راجع الوارد أو الرسائل غير المرغوبة ثم أعد المحاولة.';
	@override String get open_mail_failed => 'تعذّر فتح تطبيق البريد.';
	@override String get sign_out => 'تسجيل الخروج';
}

// Path: verify
class _TranslationsVerifyAr extends TranslationsVerifyEn {
	_TranslationsVerifyAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تحقق من بريدك الإلكتروني';
	@override String get subtitle => 'أرسلنا رمزًا من 6 أرقام إلى بريدك. أدخله أدناه للتحقق من حسابك.';
	@override String get code_label => 'رمز التحقق';
	@override String get verify_btn => 'تحقق';
	@override String get code_sent => 'تم إرسال رمز التحقق إلى بريدك الإلكتروني.';
	@override String get or_label => 'أو';
	@override String get resend => 'إعادة إرسال الرمز';
	@override String resend_in({required Object seconds}) => 'إعادة إرسال الرمز (${seconds} ث)';
	@override String get spam => 'لم تستلم الرمز؟ تحقق من مجلد البريد المزعج أو أعد الإرسال.';
	@override String get different_account => 'تسجيل الدخول بحساب مختلف';
}

// Path: forgot_password
class _TranslationsForgotPasswordAr extends TranslationsForgotPasswordEn {
	_TranslationsForgotPasswordAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إعادة تعيين\nكلمة المرور';
	@override String get subtitle => 'أدخل بريدك الإلكتروني على وايو. سنرسل لك رمزًا من 6 أرقام.';
	@override String get email_label => 'البريد الإلكتروني';
	@override String get cta => 'إرسال الرمز';
	@override String get rate_limit_title => 'يرجى الانتظار';
	@override String get rate_limit_body => 'طلبات إعادة تعيين كثيرة. أعد المحاولة بعد لحظات.';
	@override String rate_limit_remaining({required Object seconds}) => 'أعد المحاولة خلال ${seconds} ث';
}

// Path: otp
class _TranslationsOtpAr extends TranslationsOtpEn {
	_TranslationsOtpAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تأكيد\nالبريد';
	@override String subtitle({required Object email}) => 'أدخل الرمز المرسل إلى ${email}';
	@override String get resend => 'إعادة إرسال الرمز';
	@override String resend_in({required Object seconds}) => 'إعادة الإرسال خلال ${seconds} ث';
}

// Path: reset_password
class _TranslationsResetPasswordAr extends TranslationsResetPasswordEn {
	_TranslationsResetPasswordAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'كلمة مرور\nجديدة';
	@override String get subtitle => 'اختر كلمة مرور قوية (8 أحرف على الأقل، حرف كبير، رقم).';
	@override String get new_password => 'كلمة المرور الجديدة';
	@override String get confirm_password => 'تأكيد كلمة المرور';
	@override String get cta => 'تحديث كلمة المرور';
	@override String get password_updated => 'تم تحديث كلمة المرور. يمكنك تسجيل الدخول الآن.';
}

// Path: validation
class _TranslationsValidationAr extends TranslationsValidationEn {
	_TranslationsValidationAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get required => 'مطلوب';
	@override String get invalid_email => 'بريد غير صالح';
	@override String get min8 => '8 أحرف على الأقل';
	@override String get need_upper => 'يلزم حرف كبير واحد على الأقل';
	@override String get need_digit => 'يلزم رقم واحد على الأقل';
	@override String get mismatch => 'كلمتا المرور غير متطابقتين';
}

// Path: password_req
class _TranslationsPasswordReqAr extends TranslationsPasswordReqEn {
	_TranslationsPasswordReqAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get hint => 'يجب أن تحتوي كلمة المرور على:';
	@override String get length => '8 أحرف على الأقل';
	@override String get uppercase => 'حرف كبير واحد على الأقل (A–Z)';
	@override String get lowercase => 'حرف صغير واحد على الأقل (a–z)';
	@override String get number => 'رقم واحد على الأقل (0–9)';
	@override String get symbol => 'رمز واحد على الأقل (!@#%…)';
	@override String get very_weak => 'ضعيف جدًا';
	@override String get weak => 'ضعيف';
	@override String get fair => 'مقبول';
	@override String get good => 'جيد';
	@override String get strong => 'قوي';
}

// Path: home
class _TranslationsHomeAr extends TranslationsHomeEn {
	_TranslationsHomeAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'وايو أدز';
	@override String get logout => 'تسجيل الخروج';
	@override String get session_title => 'جلسة نشطة';
	@override String get session_hint => 'رمز Auth_Wayo مخزّن بأمان. طلبات API تستخدم Authorization: Bearer تلقائيًا.';
	@override String get user_fallback => 'مستخدم';
}

// Path: dashboard
class _TranslationsDashboardAr extends TranslationsDashboardEn {
	_TranslationsDashboardAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'لوحة التحكم';
	@override String get welcome => 'مرحبًا بعودتك، {name}!';
	@override String get welcome_fallback => 'مرحبًا بعودتك!';
	@override String get subtitle => 'إليك نظرة عامة على حملاتك الحالية.';
	@override String get account_creator => 'حساب مبدع';
	@override String get account_advertiser => 'حساب معلن';
	@override String get coming_soon => 'قريبًا.';
	@override late final _TranslationsDashboardBalanceAr balance = _TranslationsDashboardBalanceAr._(_root);
	@override late final _TranslationsDashboardCampaignsAr campaigns = _TranslationsDashboardCampaignsAr._(_root);
	@override late final _TranslationsDashboardErrorsAr errors = _TranslationsDashboardErrorsAr._(_root);
	@override String get notifications_title => 'الإشعارات';
	@override String get notifications_empty => 'لا إشعارات';
	@override String get notification_incoming => 'إشعار جديد';
	@override String get notification_view => 'عرض';
	@override String get notifications_mark_all_read => 'تعليم الكل كمقروء';
	@override String get notifications_mark_read => 'تعليم كمقروء';
	@override String get notifications_dismiss => 'تجاهل';
	@override String get notifications_view_all => 'عرض كل الإشعارات';
	@override String get notifications_important => 'مهم';
	@override String get notifications_earlier => 'سابقًا';
	@override String get notifications_caught_up_title => 'لا جديد!';
	@override String get notifications_caught_up_subtitle => 'لا إشعارات جديدة';
	@override String get notifications_center_title => 'مركز الإشعارات';
	@override String get notifications_unread_count => '{count} إشعارات غير مقروءة';
	@override String get notifications_all_caught_up => 'لا إشعارات جديدة';
	@override String get notifications_tab_all => 'الكل';
	@override String get notifications_tab_archived => 'الأرشيف';
	@override String get notifications_search_hint => 'بحث في الإشعارات…';
	@override String get notifications_filter_type_all => 'كل الأنواع';
	@override String get notifications_filter_priority_all => 'كل الأولويات';
	@override String get notifications_priority_critical => 'حرج';
	@override String get notifications_priority_high => 'عالي';
	@override String get notifications_priority_normal => 'عادي';
	@override String get notifications_priority_low => 'منخفض';
	@override String get notifications_load_more => 'تحميل المزيد';
	@override String get notifications_view_details => 'عرض التفاصيل';
	@override String get notifications_archive => 'أرشفة';
	@override String get notifications_urgent => 'عاجل';
	@override String get notifications_just_now => 'الآن';
	@override String get notifications_minutes_ago => 'منذ {n} د';
	@override String get notifications_hours_ago => 'منذ {n} س';
	@override String get notifications_days_ago => 'منذ {n} ي';
	@override String get notifications_section_all => 'كل الإشعارات';
	@override String get notifications_section_important => 'تنبيهات مهمة';
	@override String get notifications_section_archived => 'إشعارات مؤرشفة';
	@override String get application_approve => 'قبول';
	@override String get application_reject => 'رفض';
	@override String get application_approved => 'تم قبول الطلب';
	@override String get application_rejected => 'تم رفض الطلب';
	@override String get application_action_failed => 'تعذّر تحديث الطلب. أعد المحاولة.';
	@override String get theme_toggle_tooltip => 'التبديل بين الوضع الفاتح والداكن';
	@override String get refresh => 'تحديث لوحة التحكم';
	@override String get shell_tour_restart => 'إعادة جولة التعريف';
	@override String get shell_tour_restart_hint => 'إعادة عرض الجولة التعريفية للتنقل بين لوحة التحكم والحملات والمحفظة والمحادثة';
}

// Path: advertiser_campaigns
class _TranslationsAdvertiserCampaignsAr extends TranslationsAdvertiserCampaignsEn {
	_TranslationsAdvertiserCampaignsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الحملات';
	@override String get subtitle => 'أنشئ حملات كمسودات، تابع الأداء وراجع طلبات المنشئين.';
	@override String get view_mine => 'حملاتي';
	@override String get view_browse => 'استكشاف';
	@override late final _TranslationsAdvertiserCampaignsBrowseAr browse = _TranslationsAdvertiserCampaignsBrowseAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsTabsAr tabs = _TranslationsAdvertiserCampaignsTabsAr._(_root);
	@override String get search_placeholder => 'ابحث عن حملة';
	@override late final _TranslationsAdvertiserCampaignsEmptyAr empty = _TranslationsAdvertiserCampaignsEmptyAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsCardAr card = _TranslationsAdvertiserCampaignsCardAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsStatusAr status = _TranslationsAdvertiserCampaignsStatusAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsPlatformAr platform = _TranslationsAdvertiserCampaignsPlatformAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsDetailAr detail = _TranslationsAdvertiserCampaignsDetailAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsCreateAr create = _TranslationsAdvertiserCampaignsCreateAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsApplicationsAr applications = _TranslationsAdvertiserCampaignsApplicationsAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsActionsAr actions = _TranslationsAdvertiserCampaignsActionsAr._(_root);
}

// Path: advertiser_video_reviews
class _TranslationsAdvertiserVideoReviewsAr extends TranslationsAdvertiserVideoReviewsEn {
	_TranslationsAdvertiserVideoReviewsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مراجعة الفيديوهات';
	@override String get subtitle => 'اعتمد أو ارفض فيديوهات المنشئين المقدّمة لحملاتك.';
	@override String get pending => 'قيد الانتظار';
	@override String get approved => 'معتمدة';
	@override String get rejected => 'مرفوضة';
	@override String get flagged => 'مُبلّغ عنها';
	@override String get empty => 'لا توجد فيديوهات في هذه الفئة.';
	@override String get load_error => 'تعذّر تحميل الفيديوهات المقدّمة';
	@override String get approve_button => 'اعتماد';
	@override String get reject_button => 'رفض';
	@override String get approve_success => 'تم اعتماد الفيديو';
	@override String get reject_success => 'تم رفض الفيديو';
	@override String get reject_reason_required => 'يرجى إدخال سبب الرفض';
	@override String get reject_reason_hint => 'سبب الرفض';
	@override String get reject_dialog_title => 'رفض الفيديو';
	@override String get action_failed => 'تعذّر تحديث الفيديو. حاول مرة أخرى.';
	@override String get submitted_at => 'تاريخ التقديم';
	@override String get shorts_badge => 'Short';
	@override String get flag_reason => 'سبب الإبلاغ';
	@override String get rejection_reason => 'سبب الرفض';
	@override String get status_pending => 'قيد الانتظار';
	@override String get status_approved => 'معتمدة';
	@override String get status_rejected => 'مرفوضة';
	@override String get status_flagged => 'مُبلّغ عنها';
}

// Path: nav
class _TranslationsNavAr extends TranslationsNavEn {
	_TranslationsNavAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get dashboard => 'لوحة التحكم';
	@override String get campaigns => 'الحملات';
	@override String get analytics => 'التحليلات';
	@override String get wallet => 'المحفظة';
	@override String get chat => 'المحادثات';
	@override String get invoices => 'الفواتير';
	@override String get invoices_creator => 'الإيصالات';
}

// Path: invoices
class _TranslationsInvoicesAr extends TranslationsInvoicesEn {
	_TranslationsInvoicesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الفواتير';
	@override String get title_creator => 'إيصالات الدفع';
	@override String get subtitle_advertiser => 'كل إيداع وكل ميزانية حملة — في مكان واحد.';
	@override String get subtitle_creator => 'كل أرباحك وتحويلاتك — موقعة، محمية، قابلة للتنزيل.';
	@override String get summary_total_paid => 'إجمالي المدفوع';
	@override String get summary_pending => 'قيد الانتظار';
	@override String get summary_count => 'المستندات';
	@override String get filter_all => 'الكل';
	@override String get filter_all_types => 'كل الأنواع';
	@override String get filter_deposits => 'الإيداعات';
	@override String get filter_billing => 'ميزانية الحملة';
	@override String get filter_payouts => 'التحويلات';
	@override String get filter_earnings => 'الأرباح';
	@override String get filter_withdrawal => 'السحب';
	@override String get filter_token_purchase => 'شراء الرموز';
	@override String get type_deposit => 'إيداع المحفظة';
	@override String get type_billing => 'ميزانية الحملة';
	@override String get type_payout => 'تحويل المنشئ';
	@override String get type_earnings => 'أرباح الإعلانات';
	@override String get type_token_purchase => 'شراء الرموز';
	@override String get type_unknown => 'أخرى';
	@override String get status_paid => 'مدفوعة';
	@override String get status_validated => 'معتمدة';
	@override String get status_pending => 'قيد الانتظار';
	@override String get status_cancelled => 'ملغاة';
	@override String get role_advertiser => 'المعلن';
	@override String get role_creator => 'المنشئ';
	@override String get search_hint => 'ابحث برقم الفاتورة أو المرجع…';
	@override String get empty_title => 'لا توجد فواتير بعد';
	@override String get empty_subtitle => 'ستظهر هنا الإيداعات وميزانيات الحملات والتحويلات تلقائياً — دون أي خطوة يدوية.';
	@override String get empty_subtitle_creator => 'ستظهر أرباحك ومستندات التحويل هنا فور إصدارها — نفس ملفات PDF المعتمدة كما في الويب.';
	@override String get empty_cta => 'تحديث';
	@override String get error_title => 'تعذّر تحميل الفواتير';
	@override String get error_subtitle => 'اسحب للتحديث — سنحاول من جديد فوراً.';
	@override String get load_more => 'تحميل المزيد';
	@override String get pagination_meta => 'الصفحة {current} من {total}';
	@override String get pagination_previous => 'السابق';
	@override String get pagination_next => 'التالي';
	@override String get date_preset_all => 'كل التواريخ';
	@override String get date_preset_30d => '30 يومًا';
	@override String get date_preset_90d => '90 يومًا';
	@override String get date_preset_custom => 'مخصص';
	@override String get details_title => 'فاتورة {number}';
	@override String get details_section_summary => 'الملخص';
	@override String get details_section_actions => 'الإجراءات';
	@override String get details_section_legal => 'القانوني والمراجع';
	@override String get details_invoice_number => 'رقم الفاتورة';
	@override String get details_issued_at => 'صادرة في';
	@override String get details_paid_at => 'مدفوعة في';
	@override String get details_type => 'النوع';
	@override String get details_status => 'الحالة';
	@override String get details_role => 'الدور';
	@override String get details_reference => 'المرجع';
	@override String get details_amount => 'الإجمالي';
	@override String get details_tax => 'شامل ضريبة القيمة المضافة';
	@override String get details_currency => 'العملة';
	@override String get action_download_pdf => 'تنزيل PDF';
	@override String get action_share_pdf => 'مشاركة';
	@override String get action_open_pdf => 'فتح';
	@override String get action_copy_number => 'نسخ الرقم';
	@override String get action_view_details => 'عرض التفاصيل';
	@override String get download_progress => 'تحضير PDF…';
	@override String get download_success => 'تم الحفظ باسم {filename}';
	@override String get download_error => 'فشل التنزيل. حاول مرة أخرى.';
	@override String get copied_to_clipboard => 'تم نسخ رقم الفاتورة.';
	@override String get share_subject => 'فاتورة {number}';
	@override String get polling_live => 'مباشر';
	@override String get polling_paused => 'إيقاف';
	@override String get summary_this_month => 'هذا الشهر';
	@override String get pagination_detail => 'صفحة {current} من {total} · {count} فواتير';
	@override String get sort_sheet_title => 'الترتيب';
	@override String get sort_date_newest => 'الأحدث أولاً';
	@override String get sort_date_oldest => 'الأقدم أولاً';
	@override String get sort_amount_high => 'المبلغ · من الأعلى';
	@override String get sort_amount_low => 'المبلغ · من الأدنى';
	@override String get sort_status_az => 'الحالة · أ-ي';
	@override String get sort_status_za => 'الحالة · ي-أ';
	@override String get date_range_title => 'التواريخ';
	@override String get date_from => 'من';
	@override String get date_to => 'إلى';
	@override String get clear_dates => 'مسح';
	@override String get date_apply => 'تطبيق';
	@override String get download_all_zip => 'ZIP';
	@override String get zip_progress => 'جاري إنشاء ZIP…';
	@override String get zip_success => 'تم الحفظ: {filename}';
	@override String get zip_error => 'فشل تنزيل ZIP.';
}

// Path: push
class _TranslationsPushAr extends TranslationsPushEn {
	_TranslationsPushAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get onboarding_title => 'ابقَ على اطلاع';
	@override String get onboarding_subtitle => 'استقبل تنبيهات فورية لما يهمك — حتى عندما يكون التطبيق في الخلفية.';
	@override String get onboarding_bullet_campaigns => 'تحديثات الحملات والطلبات والميزانيات';
	@override String get onboarding_bullet_messages => 'رسائل الدردشة الجديدة';
	@override String get onboarding_bullet_system => 'الفواتير والمدفوعات وتنبيهات المنصة';
	@override String get onboarding_enable => 'تفعيل الإشعارات';
	@override String get onboarding_later => 'ليس الآن';
	@override String get onboarding_success => 'تم تفعيل الإشعارات';
	@override String get onboarding_denied_hint => 'يمكنك تفعيلها لاحقاً من إعدادات الجهاز.';
	@override String get onboarding_context_chat => 'وصلتك رسالة جديدة — فعّل التنبيهات حتى لا تفوتك أي رد.';
	@override String get onboarding_context_campaign => 'تغيّرت حالة حملة — فعّل الإشعارات لمتابعة الطلبات والميزانيات.';
	@override String get onboarding_context_invoice => 'فاتورة أو تحويل جديد — احصل على تنبيه فور تحرك الأموال.';
}

// Path: creator
class _TranslationsCreatorAr extends TranslationsCreatorEn {
	_TranslationsCreatorAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsCreatorDashboardAr dashboard = _TranslationsCreatorDashboardAr._(_root);
	@override late final _TranslationsCreatorWalletAr wallet = _TranslationsCreatorWalletAr._(_root);
	@override late final _TranslationsCreatorCampaignsAr campaigns = _TranslationsCreatorCampaignsAr._(_root);
	@override late final _TranslationsCreatorStatsAr stats = _TranslationsCreatorStatsAr._(_root);
	@override late final _TranslationsCreatorApplicationsAr applications = _TranslationsCreatorApplicationsAr._(_root);
	@override late final _TranslationsCreatorBusinessAr business = _TranslationsCreatorBusinessAr._(_root);
	@override late final _TranslationsCreatorTrustAr trust = _TranslationsCreatorTrustAr._(_root);
	@override late final _TranslationsCreatorAnalyticsAr analytics = _TranslationsCreatorAnalyticsAr._(_root);
}

// Path: advertiser_wallet
class _TranslationsAdvertiserWalletAr extends TranslationsAdvertiserWalletEn {
	_TranslationsAdvertiserWalletAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get hero_title => 'رصيدك';
	@override String get hero_subtitle => 'أضف رصيداً لتشغيل الحملات. تتم المعالجة بأمان عبر Stripe. يتوفر Apple Pay على iOS وGoogle Pay على Android عند دعمهما.';
	@override String get available => 'المتاح';
	@override String get pending => 'قيد الانتظار';
	@override String get add_funds => 'إضافة رصيد';
	@override String get amount_label => 'المبلغ';
	@override String get quick_50 => '50 USD';
	@override String get quick_100 => '100 USD';
	@override String get quick_250 => '500 USD';
	@override String get min_deposit => 'الحد الأدنى للإيداع {amount}.';
	@override String get test_pay => 'محاكاة الدفع (تطوير)';
	@override String get test_hint => 'وضع اختباري: بدون بطاقة حقيقية.';
	@override String get pay_secure => 'بطاقة أو Apple Pay أو Google Pay';
	@override String get pay_with_card => 'الدفع بالبطاقة';
	@override String get pay_with_apple => 'الدفع عبر Apple Pay';
	@override String get pay_with_google => 'الدفع عبر Google Pay';
	@override String get google_pay_with_prefix => 'الدفع عبر';
	@override String get or => 'أو';
	@override String get stripe_unavailable => 'الشحن غير متاح: لم يُضبط الدفع في الخادم.';
	@override String get stripe_keys_mismatch => 'الدفع مُعدّ بشكل خاطئ على الخادم (خلط مفاتيح Stripe للاختبار/الإنتاج). تواصل مع الدعم.';
	@override String get apple_pay_test_hint => 'وضع اختبار Stripe: Apple Pay يستخدم بطاقة المحفظة دون خصم حقيقي.';
	@override String get tx_title => 'آخر الحركات';
	@override String get tx_empty => 'لا معاملات بعد';
	@override String get tx_deposit => 'إيداع';
	@override String get tx_withdrawal => 'سحب';
	@override String get tx_other => 'معاملة';
	@override String get success => 'تم تحديث الرصيد';
	@override String get failed => 'تعذّر إضافة الرصيد. أعد المحاولة.';
	@override String get in_progress => 'جاري المعالجة…';
	@override String tx_page({required Object current, required Object total}) => 'الصفحة ${current} من ${total}';
	@override String get tx_prev => 'السابق';
	@override String get tx_next => 'التالي';
	@override String get business_profile_gate_title => 'بيانات النشاط مطلوبة';
	@override String get business_profile_gate_body => 'أكمل معلومات الفوترة الصالحة قبل إضافة الرصيد — متوافق مع Wayo Ads.';
	@override String get business_profile_gate_secure => 'اتصال مشفّر والتحقق على الخادم قبل أي دفع.';
	@override String get business_profile_gate_cta => 'إكمال بيانات النشاط';
	@override String get business_profile_error => 'تعذّر تحميل الملف التجاري.';
	@override String get pay_locked_until_business => 'تُفعّل طرق الدفع بعد إكمال الملف التجاري.';
	@override String get payment_title => 'الدفع';
	@override String get payment_total => 'الإجمالي';
	@override String get payment_deposit_amount => 'مبلغ الإيداع';
	@override String get payment_bank_fee => 'رسوم المعاملة البنكية (3.69%)';
	@override String get deposit_pending => 'إيداع قيد الانتظار';
	@override String get deposit_resume_hint => 'استئناف إيداعك بقيمة {amount} — أكمل الدفع أو اضغط إلغاء للتخلي عنه.';
	@override String get deposit_cancel => 'إلغاء';
	@override String get funding_method_label => 'طريقة التمويل';
	@override String get funding_card_title => 'بطاقة';
	@override String get funding_card_badge => 'فوري';
	@override String get funding_card_desc => 'Visa وMastercard وAmex — تتوفر الأموال فوراً.';
	@override String get funding_ach_title => 'خصم بنكي (ACH)';
	@override String get funding_ach_badge => 'رسوم أقل';
	@override String get funding_ach_desc => 'خصم مباشر من حسابك البنكي الأمريكي — رسوم أقل من البطاقة.';
	@override String get funding_ach_eta => 'تستقر الأموال عادة خلال 1-3 أيام عمل.';
	@override String get funding_ach_usd_only => 'ACH متاح فقط للمحافظ بالدولار الأمريكي.';
	@override String get funding_wire_title => 'حوالة بنكية';
	@override String get funding_wire_badge => 'مبالغ كبيرة';
	@override String get funding_wire_desc => 'أرسل حوالة بنكية باستخدام التعليمات المقدمة.';
	@override String get funding_wire_eta => 'تصل الأموال عادة خلال 1-3 أيام عمل.';
	@override String get funding_wire_currency_only => 'الحوالة متاحة فقط لـ: {currencies}.';
	@override String get saved_cards_loading => 'جارٍ تحميل البطاقات المحفوظة…';
	@override String get default_card_badge => 'افتراضية';
	@override String get saved_card_badge => 'محفوظة';
	@override String get use_new_card => 'استخدام بطاقة جديدة';
	@override String get use_saved_card => 'استخدام بطاقة محفوظة';
	@override String get change_method => 'تغيير';
	@override String get remove_card => 'إزالة';
	@override String get remove_card_confirm_title => 'إزالة هذه البطاقة؟';
	@override String get remove_card_confirm_desc => 'سيتم إزالة {brand} •••• {last4} من بطاقاتك المحفوظة.';
	@override String get remove_card_confirm_action => 'إزالة';
	@override String get card_removed_title => 'تمت إزالة البطاقة';
	@override String get card_removed_desc => 'تمت إزالة •••• {last4}.';
	@override String get card_remove_failed => 'تعذّر إزالة هذه البطاقة. أعد المحاولة.';
	@override String get refresh_saved_cards => 'تحديث';
	@override String get pay_with_saved_card => 'الدفع بـ {brand} •••• {last4}';
	@override String get wire_instructions_loading => 'تجهيز تعليمات الحوالة…';
	@override String get wire_awaiting_title => 'في انتظار حوالتك البنكية';
	@override String get wire_awaiting_desc => 'أرسل حوالة باستخدام التفاصيل أدناه. سيتم تحديث رصيدك عند استلام الأموال.';
	@override String get wire_exact_amount => 'المبلغ الدقيق';
	@override String get wire_reference => 'المرجع (مطلوب)';
	@override String get wire_reference_required_hint => 'أضف هذا المرجع في بيان الحوالة — بدونه لا يمكننا مطابقة دفعتك.';
	@override String get wire_copy_action => 'نسخ';
	@override String get wire_copied_title => 'تم النسخ';
	@override String get wire_copied_desc => 'تم النسخ إلى الحافظة.';
	@override String get wire_copy_failed => 'تعذّر النسخ. أعد المحاولة.';
	@override String get wire_network_swift => 'حوالة SWIFT / دولية';
	@override String get wire_network_aba => 'حوالة أمريكية محلية (ABA)';
	@override String get wire_network_iban => 'IBAN / SEPA';
	@override String get wire_network_sort_code => 'حوالة بنكية بريطانية';
	@override String get wire_network_other => '{network}';
	@override String get wire_account_holder => 'اسم صاحب الحساب';
	@override String get wire_bank_name => 'اسم البنك';
	@override String get wire_routing_number => 'رقم التوجيه';
	@override String get wire_sort_code => 'Sort code';
	@override String get wire_account_number => 'رقم الحساب';
	@override String get wire_swift_code => 'SWIFT/BIC';
	@override String get wire_iban => 'IBAN';
	@override String get wire_bic => 'BIC';
	@override String get wire_hosted_instructions => 'عرض التعليمات الكاملة';
	@override String get wire_done_button => 'لقد أرسلت الحوالة';
	@override String get ach_processing_banner => 'إيداع ACH بقيمة {amount} قيد المعالجة — تستقر الأموال عادة خلال 1-3 أيام عمل.';
	@override String get wire_awaiting_banner => 'إيداع الحوالة بقيمة {amount} في انتظار حوالتك البنكية.';
	@override String get reconcile_button => 'تحقق من الحالة';
	@override String get reconcile_success => 'تم تحديث الحالة.';
	@override String get reconcile_still_pending => 'لا يزال قيد المعالجة — تحقق قريباً.';
	@override String get reconcile_failed => 'تعذّر التحقق من الحالة. أعد المحاولة.';
	@override String get continue_to_payment => 'استمرار';
	@override String get cancel => 'إلغاء';
}

// Path: chat
class _TranslationsChatAr extends TranslationsChatEn {
	_TranslationsChatAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get inbox_title => 'الرسائل';
	@override String get inbox_subtitle => 'محادثات آمنة لحملاتك';
	@override String get conversation_unknown => 'محادثة';
	@override String get thread_fallback_title => 'محادثة';
	@override String get role_creator => 'منشئ';
	@override String get role_advertiser => 'معلن';
	@override String get role_admin => 'أدمن';
	@override String get composer_hint => 'اكتب رسالة…';
	@override String get typing => 'يكتب…';
	@override String get error_load_threads => 'تعذّر تحميل محادثاتك. أعد المحاولة.';
	@override String get error_phone => 'مشاركة أرقام الهاتف في الدردشة غير مسموحة.';
	@override String get spam_cooldown_title => 'ترسل رسائلًا بسرعة كبيرة';
	@override String spam_cooldown_body({required Object seconds}) => 'انتظر ${seconds} ث قبل الإرسال مرة أخرى.';
	@override String spam_cooldown_seconds({required Object seconds}) => '${seconds} ث';
	@override String get empty_threads_title => 'لا توجد محادثات بعد';
	@override String get empty_threads_hint => 'عندما يراسلك أحدهم بخصوص حملة، ستظهر هنا.';
	@override String get online => 'متصل';
	@override String get offline => 'غير متصل';
	@override String get typing_status => 'يكتب…';
	@override String get attachment => 'مرفق';
	@override String get attachment_image => 'صورة';
	@override String get attachment_pdf => 'PDF';
	@override String get open_file => 'فتح';
	@override String get pick_attachment => 'صورة أو PDF';
	@override String get upload_failed => 'تعذّر إرسال الملف. حاول مرة أخرى.';
	@override String get file_too_large => 'الملف كبير جداً (حد أقصى 10 ميجا للصور، 50 ميجا لملف PDF).';
	@override String get search_users_hint => 'ابحث عن شخص بالاسم…';
	@override String get search_users_no_results => 'لا يوجد مستخدمون مطابقون.';
	@override String get search_users_min_hint => 'اكتب حرفين على الأقل للبحث.';
	@override String get search_prior_chats_hint => 'ابحث بين من راسلتهم…';
	@override String get search_prior_chats_no_results => 'لا يوجد تطابق بين أشخاص محادثاتك.';
	@override String get search_prior_chats_min_hint => 'اكتب حرفين على الأقل.';
	@override String get conversation_open_failed => 'تعذّر فتح هذه المحادثة. حاول مرة أخرى.';
	@override String get file_picker_restart_hint => 'المرفقات تحتاج إعادة تشغيل كاملة للتطبيق بعد التحديثات. أوقف التطبيق ثم شغّله من جديد (تجنّب hot restart).';
	@override String get attachment_type_not_allowed => 'يُسمح فقط بالصور (JPG أو PNG أو GIF أو WebP أو BMP) أو ملفات PDF.';
	@override String get inbox_filter_active => 'الوارد';
	@override String get inbox_filter_archived => 'المؤرشفة';
	@override String get inbox_pinned => 'مثبّتة';
	@override String get inbox_unpinned => 'أُزيل التثبيت';
	@override String get inbox_archived => 'مؤرشفة';
	@override String get inbox_unarchived => 'أُعيدت إلى الوارد';
	@override String get inbox_pin_failed => 'تعذّر تحديث التثبيت. حاول مرة أخرى.';
	@override String get inbox_archive_failed => 'تعذّر تحديث الأرشفة. حاول مرة أخرى.';
	@override String get inbox_pin_disabled => 'التثبيت والأرشفة غير متاحين مؤقتًا.';
	@override String get menu_more => 'المزيد';
	@override String get menu_pin => 'تثبيت';
	@override String get menu_unpin => 'إلغاء التثبيت';
	@override String get menu_archive => 'أرشفة';
	@override String get menu_unarchive => 'إلغاء الأرشفة';
	@override String get menu_delete => 'حذف';
	@override String get delete_conversation => 'حذف المحادثة';
	@override String get delete_conversation_confirm_title => 'حذف هذه المحادثة؟';
	@override String get delete_conversation_confirm_text => 'سيتم حذف جميع الرسائل نهائيًا لكلا الطرفين. لا يمكن التراجع عن هذا الإجراء.';
	@override String get delete_conversation_confirm_cta => 'حذف';
	@override String get delete_conversation_failed => 'تعذّر حذف المحادثة. حاول مرة أخرى.';
	@override String get delete_conversation_done => 'تم حذف المحادثة';
	@override String get empty_archived_title => 'لا محادثات مؤرشفة';
	@override String get empty_archived_hint => 'اسحب محادثة إلى اليسار لأرشفتها.';
	@override String get date_today => 'اليوم';
	@override String get date_yesterday => 'أمس';
	@override String get bubble_reply => 'رد';
	@override String get reply_composer_title => 'رد';
	@override String get reply_composer_you => 'أنت';
	@override String get composer_reply_hint => 'اكتب رداً…';
	@override String get bubble_copy => 'نسخ';
	@override String get bubble_react => 'تفاعل';
	@override String get bubble_delete => 'حذف';
	@override String get bubble_update => 'تعديل';
	@override String get bubble_delete_unavailable => 'حذف الرسائل من التطبيق غير متاح بعد.';
	@override String get bubble_copied => 'تم النسخ إلى الحافظة';
	@override String get bubble_forward => 'تحويل';
	@override String get share_media_tooltip => 'مشاركة';
	@override String get share_failed => 'تعذر مشاركة هذا الملف. حاول مرة أخرى.';
	@override String get forward_sheet_title => 'إعادة الإرسال إلى…';
	@override String get forward_no_other_chats => 'يلزم محادثة أخرى مفتوحة أولاً.';
	@override String get forward_sending => 'جاري التحويل…';
	@override String get forward_ok => 'تم تحويل الرسالة.';
	@override String get forward_failed => 'فشل التحويل.';
	@override String get forward_view => 'فتح';
	@override String get edited => 'معدَّل';
	@override String get message_deleted => 'تم حذف هذه الرسالة';
	@override String get seen => 'تمت القراءة';
	@override String get delivered => 'تم التسليم';
	@override String get edit_mode_title => 'تعديل الرسالة';
	@override String get edit_mode_cancel => 'إلغاء';
	@override String get edit_mode_hint => 'حدّث رسالتك…';
	@override String get edit_failed => 'تعذّر تعديل الرسالة. حاول مرة أخرى.';
	@override String get edit_not_allowed => 'يمكن تعديل رسائلك النصية فقط.';
	@override String get delete_failed => 'تعذّر حذف الرسالة. حاول مرة أخرى.';
	@override String get delete_not_allowed => 'يمكنك حذف رسائلك الخاصة فقط.';
	@override String get delete_confirm_title => 'حذف هذه الرسالة؟';
	@override String get delete_confirm_text => 'لا يمكن التراجع عن هذا الإجراء.';
	@override String get delete_confirm_cta => 'حذف';
	@override String get delete_confirm_cancel => 'إلغاء';
	@override String get scroll_to_latest => 'الأحدث';
	@override String get loading_older_messages => 'جاري تحميل الرسائل الأقدم…';
	@override String get load_older_failed => 'تعذّر تحميل الرسائل الأقدم.';
	@override String get image_download_tooltip => 'تنزيل الصورة';
	@override String get image_close_tooltip => 'إغلاق';
	@override String get image_saved_to_gallery => 'تم حفظ الصورة في معرض الصور.';
	@override String get image_download_failed => 'تعذّر تنزيل هذه الصورة.';
	@override String get image_permission_denied => 'تم رفض الوصول إلى الصور. فعّل الإذن من الإعدادات.';
	@override String get image_saved_downloads_browser => 'تم تنزيل الصورة — تحقق من مجلد التحميلات.';
	@override String get peer_unavailable => 'هذا المستخدم لم يعد متاحًا.';
}

// Path: common
class _TranslationsCommonAr extends TranslationsCommonEn {
	_TranslationsCommonAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get language => 'اللغة';
	@override String get theme => 'المظهر';
	@override String get light => 'فاتح';
	@override String get dark => 'داكن';
	@override String get system => 'النظام';
}

// Path: errors
class _TranslationsErrorsAr extends TranslationsErrorsEn {
	_TranslationsErrorsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get rate_limited => 'عدد كبير من المحاولات. أعد المحاولة بعد بضع دقائق.';
	@override String get invalid_credentials => 'بيانات الدخول غير صحيحة.';
	@override String get network => 'تعذّر الاتصال بالخادم. تحقق من اتصالك.';
	@override String get server_generic => 'حدث خطأ. حاول مرة أخرى.';
	@override String get empty_response => 'استجابة فارغة من الخادم.';
	@override String get login_failed => 'فشل تسجيل الدخول.';
	@override String get unknown => 'حدث خطأ غير متوقع.';
	@override String get session_invalid => 'انتهت جلستك. سجّل الدخول من جديد.';
	@override String get email_not_found => 'لا يوجد حساب بهذا البريد.';
}

// Path: privacy_policy
class _TranslationsPrivacyPolicyAr extends TranslationsPrivacyPolicyEn {
	_TranslationsPrivacyPolicyAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'سياسة الخصوصية';
	@override String get last_updated => 'آخر تحديث: 7 أكتوبر 2025';
	@override String get company_legal_name => 'AL BOUHOUTI SOFTWARE DESIGN COMPANY L.L.C';
	@override String get operator_intro => 'يُدار هذا الموقع ومنصة Wayo Ads بواسطة:';
	@override String get company_address => 'Al Barshaa 1، دبي، دبي، الإمارات العربية المتحدة';
	@override String get support_label => 'دعم العملاء';
	@override String get support_email => 'support@wayo.cloud';
	@override String get support_phone => '+971 542396643';
	@override String get intro_title => '1. مقدمة';
	@override String get intro_body => 'في Wayo Ads نلتزم بجمع بياناتك واستخدامها بمسؤولية، وفقًا لقوانين حماية البيانات المعمول بها في الولايات القضائية التي نعمل فيها، بما في ذلك القانون الفدرالي وقوانين الولايات في الولايات المتحدة عند الاقتضاء، وللمستخدمين في المنطقة الاقتصادية الأوروبية أو المملكة المتحدة عند الاقتضاء، اللائحة العامة لحماية البيانات (GDPR) (الاتحاد الأوروبي 2016/679). باستخدامك منصتنا، فإنك توافق على جمع بياناتك ومعالجتها واستخدامها كما هو موضح في سياسة الخصوصية هذه.';
	@override String get data_title => '2. البيانات التي نجمعها';
	@override String get data_intro => 'نجمع فقط البيانات الضرورية، وفقًا للقانون المعمول به وعند الاقتضاء اللائحة العامة لحماية البيانات.';
	@override String get data_advertisers_title => 'للمعلنين';
	@override String get data_advertisers_body => 'التعريف وبيانات الاتصال: اسم الشركة، البريد الإلكتروني، رقم الهاتف.\nالملف الشخصي: شعار الشركة (إن وُجد)، وصف النشاط.\nالحملات: محتوى الحملات، الميزانيات، معايير الاستهداف، بيانات التحليلات.';
	@override String get data_creators_title => 'للمبدعين';
	@override String get data_creators_body => 'التعريف وبيانات الاتصال: الاسم، البريد الإلكتروني، رقم الهاتف.\nالملف الشخصي: صورة الملف (إن وُجدت)، السيرة، الخبرات، روابط وسائل التواصل.\nالمحتوى: الفيديوهات والمنشورات والمواد التي ترفعها.\nبيانات الاستخدام: التفاعل مع المنصة، إحصاءات التفاعل، بيانات الأرباح.';
	@override String get data_technical_title => 'معلومات تقنية (جميع المستخدمين)';
	@override String get data_technical_body => 'بيانات تقنية: عنوان IP، نوع المتصفح وإصداره، نوع الجهاز، نظام التشغيل، معرّفات الجلسة، الطوابع الزمنية، الصفحات التي زرتها، النقرات، المصادر الإحالة.\nملفات تعريف الارتباط وتقنيات مشابهة: انظر القسم 8 (ملفات تعريف الارتباط).';
	@override String get data_payment_title => 'بيانات الدفع';
	@override String get data_payment_body => 'المعاملات: المبالغ، العملة، التاريخ، وسيلة الدفع، عنوان الفوترة.';
	@override String get data_payment_note => 'هام: تُعالج بيانات البطاقة حصريًا عبر مزود الدفع (Stripe). لا تخزّن Wayo معلومات بطاقة الائتمان.';
	@override String get purpose_title => '3. أغراض استخدام بياناتك';
	@override String get purpose_body => 'نستخدم بياناتك من أجل: تقديم خدماتنا وصيانتها وتحسينها؛ تخصيص التجربة واقتراح محتوى مناسب؛ إدارة العلاقات التعاقدية (الحسابات، الفوترة، الدعم)؛ إبلاغك بمعلومات الخدمة (التحديثات، التغييرات، التنبيهات)؛ ضمان أمان المنصة وسلامتها (اكتشاف إساءة الاستخدام والاحتيال)؛ إجراء تحليلات للاستخدام ببيانات مجمّعة أو مجهولة المصدر قدر الإمكان.';
	@override String get legal_bases_title => '4. الأسس القانونية للمعالجة';
	@override String get legal_bases_body => 'بحسب الحالة، نعتمد على: موافقتك (مثل ملفات تعريف الارتباط غير الضرورية، النشرات الإخبارية)؛ تنفيذ عقد أو إجراءات ما قبل تعاقدية (مثل التسجيل، الفوترة)؛ الامتثال لالتزام قانوني (مثل الاحتفاظ بالفواتير)؛ مصلحتنا المشروعة (مثل الأمان، تحسين الخدمة).';
	@override String get sharing_title => '5. مشاركة معلوماتك';
	@override String get sharing_body => 'لا تبيع Wayo بياناتك الشخصية. قد يحدث مشاركة محدودة مع: مزودي خدمات أساسيين (معالجة الدفع، الاستضافة، البريد، التحليلات)؛ لأسباب قانونية إذا طلب القانون ذلك أو استجابةً لطلب مشروع من جهة مختصة.';
	@override String get security_title => '6. أمن البيانات';
	@override String get security_body => 'تشفير TLS/HTTPS للبيانات أثناء النقل.\nضوابط وصول وفق مبدأ «الحاجة للمعرفة».\nنسخ احتياطي منتظم وإجراءات استعادة.\nتحديثات أمنية وتدقيقات دورية.\nتسجيل واكتشاف الأنشطة غير الاعتيادية.';
	@override String get content_title => '7. مسؤوليات المستخدمين وحماية المحتوى';
	@override String get content_body => 'احترم حقوق الملكية الفكرية للمبدعين ولـ Wayo. لا تنسخ أو تشارك أو تعيد توزيع أو تعيد بيع المحتوى دون إذن. قد يؤدي أي خرق إلى تعليق الحساب وإجراءات قانونية عند الاقتضاء.';
	@override String get cookies_title => '8. ملفات تعريف الارتباط وتقنيات التتبع';
	@override String get cookies_body => 'ملفات تعريف ارتباط ضرورية (تشغيل الموقع، الأمان، الجلسة).\nملفات تحليلية (مثل Google Analytics) لقياس الجمهور.\nلا تُفعّل ملفات غير الضرورية إلا بموافقتك عبر شريط ملفات تعريف الارتباط عند أول زيارة.';
	@override String get retention_title => '9. الاحتفاظ بالبيانات';
	@override String get retention_body => 'نحتفظ ببياناتك فقط للمدة اللازمة للأغراض الواردة هنا. تُحفظ بيانات الحساب طيلة عمر الحساب زائد أي مدة احتفاظ قانونية. تُحفظ بيانات المعاملات وفقًا لمتطلبات المحاسبة والضرائب.';
	@override String get children_title => '10. خصوصية الأطفال';
	@override String get children_body => 'خدماتنا غير موجّهة لمن دون 18 عامًا. لا نجمع عن قصد معلومات شخصية من أطفال. إذا علمنا أننا جمعنا بيانات طفل دون موافقة ولي الأمر، سنتخذ خطوات لحذفها.';
	@override String get changes_title => '11. تغييرات هذه السياسة';
	@override String get changes_body => 'قد نحدّث سياسة الخصوصية من وقت لآخر. سنُعلمك بأي تغييرات جوهرية بنشر السياسة الجديدة على هذه الصفحة وتحديث تاريخ «آخر تحديث».';
	@override String get contact_title => '12. معلومات الاتصال';
	@override String get contact_controller_label => 'مسؤول المعالجة';
	@override String get contact_controller => 'Wayo، دبي، الإمارات العربية المتحدة';
	@override String get contact_email_label => 'البريد الإلكتروني';
	@override String get contact_email => 'info@wayo.cloud';
	@override String get contact_address_label => 'العنوان';
	@override String get contact_address => 'R320 Umm Hurair 2, Dubai, UAE';
}

// Path: terms_and_conditions
class _TranslationsTermsAndConditionsAr extends TranslationsTermsAndConditionsEn {
	_TranslationsTermsAndConditionsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الشروط والأحكام';
	@override String get last_updated => 'آخر تحديث: 7 أكتوبر 2025';
	@override String get company_legal_name => 'AL BOUHOUTI SOFTWARE DESIGN COMPANY L.L.C';
	@override String get operator_intro => 'يُدار هذا الموقع ومنصة Wayo Ads بواسطة:';
	@override String get company_address => 'Al Barshaa 1، دبي، دبي، الإمارات العربية المتحدة';
	@override String get support_label => 'دعم العملاء';
	@override String get support_email => 'support@wayo.cloud';
	@override String get support_phone => '+971 542396643';
	@override String get back_home => 'العودة إلى الصفحة الرئيسية';
	@override String get intro_title => '1. مقدمة';
	@override String get intro_body => 'مرحبًا بك في Wayo Ads، منصتك الإلكترونية التي تربط المعلنين بصنّاع المحتوى. بالوصول إلى موقعنا و/أو تطبيقنا للجوال، فإنك توافق على الالتزام بهذه الشروط والأحكام. يرجى قراءتها بعناية، فهي تحدد حقوقك والتزاماتك كمستخدم.';
	@override String get definitions_title => '2. التعريفات';
	@override String get definitions_body => 'Wayo — مجموعة خدمات الإعلان وسوق المبدعين المتاحة عبر الموقع وتطبيق الجوال.\nالمستخدم — أي شخص (معلن، مبدع، أو منظمة) يمتلك حسابًا على المنصة.\nالمحتوى — جميع المستندات والفيديوهات والإعلانات والحملات والمواد الأخرى المتاحة عبر المنصة.\nحقوق الاستخدام — حقوق الوصول والاستخدام للمحتوى شخصية وخاصة وغير قابلة للتحويل.';
	@override String get access_title => '3. الوصول والاستخدام';
	@override String get access_body => 'يجب على المستخدم إنشاء حساب بتقديم معلومات دقيقة ومحدّثة. المستخدم مسؤول عن الحفاظ على سرية بيانات تسجيل الدخول. يجب الإبلاغ فورًا عن أي استخدام غير مصرّح به.';
	@override String get content_protection_title => '4. حماية المحتوى واستخدامه';
	@override String get content_protection_body => 'تبقى جميع المواد والمحتوى ملكًا فكريًا لأصحابها. يُحظر منعًا باتًا النسخ أو التوزيع أو البيع أو المشاركة. أي مخالفة تؤدي إلى تعليق الحساب فورًا وقد تستوجب إجراءات قانونية.';
	@override String get features_title => '5. الميزات والخدمات';
	@override String get features_body => 'توفر منصتنا ميزات متعددة تشمل إنشاء الحملات، سوق المبدعين، لوحات التحليلات، معالجة الدفع، وأدوات التواصل. يوافق المستخدمون على استخدام هذه الخدمات بمسؤولية وفقًا لهذه الشروط.';
	@override String get support_title => '6. الدعم الفني والصيانة';
	@override String get support_body => 'الدعم متاح من الاثنين إلى الجمعة، من 9:00 صباحًا إلى 5:00 مساءً (UTC+1) عبر البريد الإلكتروني أو الدردشة المدمجة. وقت الاستجابة المقدّر من 24 إلى 48 ساعة. سيتم إخطار المستخدمين مسبقًا بأي توقف مجدول.';
	@override String get rights_title => '7. حقوق ومسؤوليات المستخدم';
	@override String get rights_body => 'للمعلنين الحق في إنشاء الحملات وإدارتها والوصول إلى التحليلات والتواصل مع المبدعين. للمبدعين الحق في تصفح الحملات وقبول العروض وتلقي الأجر عن العمل المنجز. يجب على جميع المستخدمين التصرف بحسن نية والامتثال لقواعد المنصة.';
	@override String get prohibited_title => 'سلوك محظور';
	@override String get prohibited_body => 'يُحظر منعًا باتًا الاحتيال (مثل المشاهدات الوهمية أو click fraud)، المحتوى غير القانوني أو المسيء أو الضار، الرسائل المزعجة، انتحال الهوية، وأي نشاط يضر بسلامة المنصة. أي خرق قد يؤدي إلى تعليق دائم وإجراءات قانونية.';
	@override String get ip_title => '8. الملكية الفكرية';
	@override String get ip_body => 'جميع العلامات التجارية والشعارات والتصاميم والأكواد والملكية الفكرية الأخرى على المنصة محمية بقوانين حقوق النشر والاتفاقيات الدولية. يحتفظ المستخدمون بملكية المحتوى الذي ينشئونه لكنهم يمنحون Wayo ترخيصًا غير حصري لاستضافته وعرضه وجعله متاحًا.';
	@override String get privacy_title => '9. البيانات الشخصية';
	@override String get privacy_body => 'يتم جمع البيانات ومعالجتها وفقًا لسياسة الخصوصية لدينا. للمستخدمين الحق في الوصول إلى بياناتهم الشخصية وتصحيحها وحذفها. لمزيد من المعلومات، راجع سياسة الخصوصية.';
	@override String get view_privacy_policy => 'عرض سياسة الخصوصية';
	@override String get liability_title => '10. تحديد المسؤولية';
	@override String get liability_body => 'لا تتحمل Wayo المسؤولية عن: جودة أو ملاءمة المحتوى المقدّم من المستخدمين، النزاعات بين المعلنين والمبدعين، انقطاع الخدمة، فقدان البيانات، أو المشكلات التقنية. تقتصر مسؤولية Wayo على مبلغ الرسوم المدفوعة مقابل الخدمة.';
	@override String get termination_title => '11. الإنهاء';
	@override String get termination_body => 'يجوز لـ Wayo تعليق أو إنهاء حساب في حال مخالفة هذه الشروط. يمكن للمستخدمين إغلاق حسابهم عبر واجهة المنصة في أي وقت. عند الإنهاء، تُلغى جميع الحقوق والوصول فورًا.';
	@override String get governing_law_title => '12. القانون الحاكم وتسوية النزاعات';
	@override String get governing_law_body => 'القانون الحاكم: القوانين المعمول بها في الإمارات العربية المتحدة. يتفق الطرفان على السعي إلى حل ودي قبل اللجوء إلى الإجراءات القانونية.';
	@override String get amendments_title => '13. تعديلات على الشروط';
	@override String get amendments_body => 'يجوز لـ Wayo تعديل هذه الشروط في أي وقت. سيتم إخطار المستخدمين بأي تغييرات، وتدخل حيز التنفيذ بعد 15 يومًا من الإخطار.';
	@override String get waiver_title => '14. التنازل والإقرار';
	@override String get waiver_body => 'تنازل عن الدعاوى الجماعية: يجب التعامل مع جميع النزاعات على أساس فردي.\nمدة التقادم: يجب تقديم أي مطالبة خلال سنة واحدة كحد أقصى.';
	@override String get contact_title => '15. معلومات الاتصال';
	@override String get contact_controller_label => 'مسؤول المعالجة';
	@override String get contact_controller => 'Wayo، دبي، الإمارات العربية المتحدة';
	@override String get contact_email_label => 'البريد الإلكتروني';
	@override String get contact_email => 'info@wayo.cloud';
	@override String get contact_address_label => 'العنوان';
	@override String get contact_address => 'R320 أم هرير 2، دبي، الإمارات العربية المتحدة';
}

// Path: cookie_policy
class _TranslationsCookiePolicyAr extends TranslationsCookiePolicyEn {
	_TranslationsCookiePolicyAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'سياسة ملفات تعريف الارتباط';
	@override String get last_updated => 'آخر تحديث: 15 مايو 2025';
	@override String get company_legal_name => 'AL BOUHOUTI SOFTWARE DESIGN COMPANY L.L.C';
	@override String get operator_intro => 'مشغّل منصة Wayo Ads.';
	@override String get company_address => 'Al Barshaa 1، دبي، دبي، الإمارات العربية المتحدة';
	@override String get support_label => 'دعم العملاء';
	@override String get support_email => 'support@wayo.cloud';
	@override String get support_phone => '+971 542396643';
	@override String get back_home => 'العودة إلى الصفحة الرئيسية';
	@override String get intro_title => '1. مقدمة';
	@override String get intro_body => 'توضّح سياسة ملفات تعريف الارتباط هذه كيفية استخدام Wayo Ads لملفات تعريف الارتباط وتقنيات التتبع المماثلة عند زيارتك لموقعنا. باستخدامك منصتنا، فإنك توافق على استخدام ملفات تعريف الارتباط كما هو موضّح في هذه السياسة، وفقًا لتفضيلات موافقتك.';
	@override String get what_are_title => '2. ما هي ملفات تعريف الارتباط؟';
	@override String get what_are_body => 'ملفات تعريف الارتباط هي ملفات نصية صغيرة تُوضَع على جهازك (كمبيوتر أو جهاز لوحي أو هاتف) عند زيارة موقع ويب. تُستخدم على نطاق واسع لجعل المواقع تعمل بكفاءة، ولتذكّر تفضيلاتك، ولتوفير معلومات لمالكي الموقع. قد تكون «ملفات جلسة» (تُحذف عند إغلاق المتصفح) أو «ملفات دائمة» (تبقى على جهازك لفترة محددة أو حتى تحذفها).';
	@override String get types_title => '3. أنواع ملفات تعريف الارتباط التي نستخدمها';
	@override String get types_essential_title => 'ملفات أساسية';
	@override String get types_essential_body => 'هذه الملفات ضرورية لعمل الموقع بشكل صحيح. تُمكّن الوظائف الأساسية مثل الأمان وإدارة الشبكة وإمكانية الوصول. يمكنك تعطيلها من إعدادات المتصفح، لكن ذلك قد يؤثر على عمل الموقع.';
	@override String get types_analytics_title => 'ملفات تحليلية';
	@override String get types_analytics_body => 'تساعدنا هذه الملفات على فهم كيفية تفاعل الزوار مع موقعنا من خلال جمع المعلومات والإبلاغ عنها بشكل مجهول. نستخدم Google Analytics لقياس حركة المرور وأنماط الاستخدام. لا تُفعَّل ملفات التحليلات إلا بموافقتك عبر شريط ملفات تعريف الارتباط.';
	@override String get types_preferences_title => 'ملفات التفضيلات';
	@override String get types_preferences_body => 'تسمح هذه الملفات للموقع بتذكّر اختياراتك (مثل لغتك أو حالة الشريط الجانبي) لتقديم تجربة أكثر تخصيصًا.';
	@override String get table_title => '4. قائمة ملفات تعريف الارتباط';
	@override String get table_description => 'فيما يلي قائمة تفصيلية بملفات تعريف الارتباط التي قد نضعها على جهازك:';
	@override String get table_col_name => 'اسم الملف';
	@override String get table_col_purpose => 'الغرض';
	@override String get table_col_duration => 'المدة';
	@override String get row_cookie_consent_name => 'cookie_consent';
	@override String get row_cookie_consent_purpose => 'يخزّن قرار موافقتك على ملفات تعريف الارتباط (قبول أو رفض أو تخصيص)';
	@override String get row_cookie_consent_duration => 'سنة واحدة';
	@override String get row_cookie_preferences_name => 'cookie_preferences';
	@override String get row_cookie_preferences_purpose => 'يخزّن تفضيلات ملفات تعريف الارتباط المخصّصة (مثل تفعيل التحليلات)';
	@override String get row_cookie_preferences_duration => 'سنة واحدة';
	@override String get row_session_token_name => 'next-auth.session-token / __Secure-next-auth.session-token';
	@override String get row_session_token_purpose => 'يحافظ على جلسة المصادقة الخاصة بك';
	@override String get row_session_token_duration => 'جلسة';
	@override String get row_callback_url_name => 'next-auth.callback-url';
	@override String get row_callback_url_purpose => 'يخزّن الصفحة التي تُوجَّه إليها بعد تسجيل الدخول';
	@override String get row_callback_url_duration => 'جلسة';
	@override String get row_csrf_token_name => 'next-auth.csrf-token / __Host-next-auth.csrf-token';
	@override String get row_csrf_token_purpose => 'يحمي من هجمات Cross-Site Request Forgery';
	@override String get row_csrf_token_duration => 'جلسة';
	@override String get row_pkce_name => '__Secure-next-auth.pkce.code_verifier';
	@override String get row_pkce_purpose => 'يؤمّن تدفق مصادقة OAuth (PKCE)';
	@override String get row_pkce_duration => 'جلسة';
	@override String get row_oauth_state_name => 'oauth_state_id';
	@override String get row_oauth_state_purpose => 'يربط بحالة تدفق OAuth لتسجيلات الدخول الاجتماعية الآمنة';
	@override String get row_oauth_state_duration => '10 دقائق';
	@override String get row_oauth_reauth_name => 'oauth_force_reauth';
	@override String get row_oauth_reauth_purpose => 'يضمن طلب مصادقة جديد لتسجيلات الدخول الاجتماعية';
	@override String get row_oauth_reauth_duration => '10 دقائق';
	@override String get row_yt_pkce_name => '__yt_oauth_pkce';
	@override String get row_yt_pkce_purpose => 'يؤمّن تدفق ربط OAuth لـ YouTube';
	@override String get row_yt_pkce_duration => '10 دقائق';
	@override String get row_locale_name => 'locale';
	@override String get row_locale_purpose => 'يتذكّر تفضيل اللغة (الإنجليزية أو الفرنسية أو العربية)';
	@override String get row_locale_duration => 'سنة واحدة';
	@override String get row_sidebar_name => 'sidebar_state';
	@override String get row_sidebar_purpose => 'يتذكّر ما إذا كنت قد طيّت الشريط الجانبي أو وسّعته';
	@override String get row_sidebar_duration => '7 أيام';
	@override String get row_iab_dismissed_name => 'wayo_iab_dismissed';
	@override String get row_iab_dismissed_purpose => 'يتذكّر أنك أغلقت تحذير المتصفح المدمج';
	@override String get row_iab_dismissed_duration => '12 ساعة';
	@override String get row_app_install_name => 'wayo_app_install_dismissed';
	@override String get row_app_install_purpose => 'يتذكّر أنك أغلقت مطالبة تثبيت التطبيق على الهاتف';
	@override String get row_app_install_duration => '7 أيام';
	@override String get row_analytics_name => '_ga, _ga_* (Google Analytics)';
	@override String get row_analytics_purpose => 'يجمع إحصاءات استخدام مجهولة (الصفحات التي زُرتها، مدة الجلسة، مصادر الزيارات). يُفعَّل فقط بموافقتك.';
	@override String get row_analytics_duration => 'سنتان';
	@override String get row_stripe_name => 'ملفات Stripe';
	@override String get row_stripe_purpose => 'تُستخدم لمعالجة المدفوعات وكشف الاحتيال وعملية الدفع';
	@override String get row_stripe_duration => 'من الجلسة إلى سنة واحدة';
	@override String get manage_title => '5. إدارة تفضيلات ملفات تعريف الارتباط';
	@override String get manage_body => 'عند أول زيارة لموقعنا، يظهر شريط ملفات تعريف الارتباط الذي يتيح لك قبول جميع الملفات، أو رفض غير الأساسية، أو تخصيص تفضيلاتك. يمكنك تغيير تفضيلاتك في أي وقت عبر رابط «إعدادات ملفات تعريف الارتباط» في تذييل الموقع. تسمح معظم المتصفحات أيضًا بالتحكم في الملفات من إعداداتها. يمكنك عادةً: حذف الملفات المخزّنة على جهازك؛ منع تعيين ملفات جديدة؛ تحديد تفضيلات لمواقع محددة؛ التصفح في وضع خاص/التصفح المتخفي. يرجى ملاحظة أن حظر الملفات الأساسية قد يضعف بعض ميزات الموقع.';
	@override String get changes_title => '6. تغييرات على سياسة ملفات تعريف الارتباط';
	@override String get changes_body => 'قد نحدّث هذه السياسة من وقت لآخر لتعكس تغييرات في ممارساتنا أو لأسباب تشغيلية أو قانونية أو تنظيمية. سننشر أي تغييرات على هذه الصفحة ونحدّث تاريخ «آخر تحديث».';
	@override String get contact_title => '7. معلومات الاتصال';
	@override String get contact_body => 'إذا كانت لديك أسئلة حول استخدامنا لملفات تعريف الارتباط أو هذه السياسة، يرجى التواصل معنا على info@wayo.cloud.';
}

// Path: app_settings
class _TranslationsAppSettingsAr extends TranslationsAppSettingsEn {
	_TranslationsAppSettingsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'التفضيلات';
	@override String get subtitle => 'المظهر واللغة';
	@override String get section_appearance => 'المظهر';
	@override String get section_language => 'اللغة';
	@override String get theme_light => 'فاتح';
	@override String get theme_dark => 'داكن';
	@override String get theme_system => 'النظام';
	@override String get theme_hint => 'اختر مظهر Wayo Ads. يتبع المظهر إعدادات هاتفك.';
	@override String get language_hint => 'يحدّد لغة الواجهة. تتكيّف التواريخ والتنسيقات مع اللغة المختارة.';
	@override String get design_variant => 'أسلوب اللوحة';
	@override String get design_glass => 'زجاج ناعم';
	@override String get design_corporate => 'احترافي بسيط';
	@override String get close => 'إغلاق';
	@override String get open_semantics => 'فتح التفضيلات واللغة';
	@override String get close_semantics => 'إغلاق التفضيلات';
	@override String get profile_fallback => 'الحساب';
	@override String get selected => 'محدد';
	@override String get lang_en => 'English';
	@override String get lang_fr => 'Français';
	@override String get lang_ar => 'العربية';
	@override String get section_notifications => 'الإشعارات';
	@override String get notifications_toggle => 'إشعارات الدفع';
	@override String get notifications_hint => 'تنبيهات الحملات والمحادثات والفواتير والمدفوعات. يتطلب إذنًا في إعدادات الهاتف.';
	@override String get notifications_status_enabled => 'مفعّلة — ستصلك التنبيهات على هذا الجهاز';
	@override String get notifications_status_disabled => 'معطّلة داخل التطبيق';
	@override String get notifications_status_permission_denied => 'اسمح بالإشعارات من إعدادات الهاتف';
	@override String get notifications_open_settings => 'فتح إعدادات الهاتف';
	@override String get notifications_enable_error => 'تعذّر تفعيل الإشعارات. تحقق من إعدادات النظام.';
	@override String get notifications_update_error => 'تعذّر تحديث إعدادات الإشعارات. أعد المحاولة.';
	@override String get notif_prefs_entry_title => 'تفضيلات الإشعارات';
	@override String get notif_prefs_entry_sub => 'القنوات والفئات للتنبيهات داخل التطبيق والبريد';
	@override String get notif_prefs_title => 'تفضيلات الإشعارات';
	@override String get notif_prefs_channels_title => 'القنوات';
	@override String get notif_prefs_channels_sub => 'مفاتيح رئيسية لكيفية وصول Wayo إليك.';
	@override String get notif_prefs_categories_title => 'الفئات';
	@override String get notif_prefs_categories_sub => 'كتم أنواع معينة دون إيقاف الكل.';
	@override String get notif_prefs_in_app => 'داخل التطبيق';
	@override String get notif_prefs_email => 'البريد';
	@override String get notif_prefs_sound => 'الصوت';
	@override String get notif_prefs_load_error => 'تعذّر تحميل التفضيلات.';
	@override String get notif_prefs_error => 'تعذّر الحفظ. أعد المحاولة.';
	@override String get notif_prefs_retry => 'إعادة المحاولة';
	@override String get notif_cat_video => 'الفيديوهات';
	@override String get notif_cat_applications => 'الطلبات';
	@override String get notif_cat_payouts => 'المدفوعات';
	@override String get notif_cat_wallet => 'المحفظة';
	@override String get notif_cat_tokens => 'الرموز';
	@override String get notif_cat_campaigns => 'الحملات';
	@override String get notif_cat_security => 'الأمان';
	@override String get export_data_title => 'تنزيل بياناتي';
	@override String get export_data_sub => 'تصدير نسخة JSON من حساب Wayo Ads';
	@override String get export_data_button => 'تنزيل التصدير';
	@override String get export_data_progress => 'جارٍ تجهيز التصدير…';
	@override String get export_data_success => 'تم حفظ التصدير';
	@override String get export_data_error => 'تعذّر تصدير بياناتك. أعد المحاولة.';
	@override String get passkeys_title => 'مفاتيح المرور';
	@override String get passkeys_sub => 'تسجيل دخول بدون كلمة مرور';
	@override String get passkeys_web_only => 'إدارة مفاتيح المرور تُفتح بأمان عبر Auth Wayo داخل التطبيق.';
	@override String get passkeys_manage_hint => 'أضف أو أزل مفاتيح المرور. تتم الإدارة عبر Auth Wayo (مطلوب لـ WebAuthn).';
	@override String get passkeys_open_manage => 'إدارة مفاتيح المرور';
	@override String get connected_accounts_title => 'الحسابات المرتبطة';
	@override String get connected_accounts_sub => 'Google وApple المرتبطة بحساب Wayo';
	@override String get connected_accounts_web_only => 'اربط أو ألغِ ربط Google/Apple عبر Auth Wayo في التطبيق.';
	@override String get connected_accounts_manage_hint => 'اربط أو ألغِ ربط Google وApple في حساب Auth Wayo.';
	@override String get connected_accounts_open_manage => 'إدارة الحسابات المرتبطة';
	@override String get handoff_error => 'تعذّر فتح الإدارة الآمنة. سيتم فتح المتصفح.';
	@override String get open_web_settings => 'فتح إعدادات الويب';
	@override String get guides_title => 'الأدلة والموارد';
	@override String get guides_sub => 'مقالات المساعدة وأدلة منتج Wayo Ads';
	@override String get section_account => 'الحساب';
	@override String get section_security => 'الأمان';
	@override String get sessions_title => 'الجلسات النشطة';
	@override String get sessions_desc => 'الأجهزة المتصلة حالياً بحسابك. ألغِ أي جلسة لا تعرفها.';
	@override String get sessions_empty => 'لا توجد جلسات متصفح أخرى نشطة.';
	@override String get sessions_error_load => 'تعذّر تحميل الجلسات النشطة.';
	@override String get sessions_error_revoke => 'تعذّر إلغاء الجلسة. حاول مرة أخرى.';
	@override String get session_unknown_device => 'جهاز غير معروف';
	@override String get session_this_device => 'هذا الجهاز';
	@override String get session_last_active => 'آخر نشاط';
	@override String get session_revoke => 'إلغاء';
	@override String get session_revoking => 'جارٍ الإلغاء…';
	@override String get session_revoke_others => 'تسجيل الخروج من الأجهزة الأخرى';
	@override String get session_revoke_confirm_title => 'إلغاء الجلسة؟';
	@override String get session_revoke_confirm_desc => 'سيتم تسجيل خروج هذا الجهاز في طلبه التالي.';
	@override String get session_revoke_others_confirm_title => 'تسجيل الخروج من الأجهزة الأخرى؟';
	@override String get session_revoke_others_confirm_desc => 'سيتم إغلاق جميع جلسات المتصفح الأخرى. يبقى هذا الهاتف متصلاً.';
	@override String get session_revoke_confirm => 'إلغاء';
	@override String get session_revoke_cancel => 'إلغاء';
	@override String get delete_account_entry => 'حذف الحساب';
	@override String get delete_account_entry_sub => 'فترة سماح 30 يومًا — من داخل التطبيق';
	@override String get delete_account_manage => 'عرض تفاصيل الحذف';
	@override String get section_about => 'حول التطبيق';
	@override String get rate_app => 'قيّم Wayo Ads';
	@override String get rate_app_sub => 'افتح App Store أو Google Play';
	@override String get rate_app_error => 'تعذّر فتح المتجر. أعِد المحاولة بعد لحظات.';
	@override String get devices_nav_title => 'أجهزة الثقة';
	@override String get devices_title => 'الأجهزة الموثوقة';
	@override String get devices_desc => 'الأجهزة المسموح لها بالاتصال بحسابك. انسَ أي جهاز لا تعرفه.';
	@override String get devices_empty => 'لا توجد أجهزة موثوقة مسجلة.';
	@override String get devices_error_load => 'تعذر تحميل الأجهزة الموثوقة.';
	@override String get devices_error_revoke => 'تعذر نسيان الجهاز. حاول مرة أخرى.';
	@override String get device_unknown_device => 'جهاز غير معروف';
	@override String get device_this_device => 'هذا الجهاز';
	@override String get device_forget => 'انسَ';
	@override String get device_revoking => 'جارٍ النسيان…';
	@override String get device_revoke_confirm_title => 'نسيان هذا الجهاز؟';
	@override String get device_revoke_confirm_desc => 'سيتم إزالة هذا الجهاز من قائمة الثقة. ستحتاج إلى إعادة الموافقة عليه عند تسجيل الدخول التالي.';
	@override String get device_revoke_confirm => 'انسَ';
	@override String get device_revoke_cancel => 'إلغاء';
	@override String get device_revoked => 'تم نسيان الجهاز.';
}

// Path: profile
class _TranslationsProfileAr extends TranslationsProfileEn {
	_TranslationsProfileAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get nav_title => 'الملف الشخصي';
	@override String get entry_title => 'تعديل الملف الشخصي';
	@override String get entry_sub => 'الصورة، الاسم المعروض ومعلومات الحساب';
	@override String get section_info_title => 'معلومات الملف الشخصي';
	@override String get section_info_desc => 'حدّث معلوماتك الشخصية وصورة ملفك.';
	@override String get section_details_title => 'تفاصيل الحساب';
	@override String get section_details_desc => 'معلومات حسابك وأدوارك.';
	@override String get display_name => 'الاسم المعروض';
	@override String get display_name_hint => 'كيف يراك الآخرون على Wayo Ads';
	@override String get display_name_required => 'الاسم المعروض مطلوب';
	@override String get save_changes => 'حفظ التغييرات';
	@override String get saving => 'جارٍ الحفظ…';
	@override String get saved => 'تم تحديث الملف الشخصي';
	@override String get save_error => 'تعذّر حفظ الملف الشخصي. أعِد المحاولة.';
	@override String get load_error => 'تعذّر تحميل الملف الشخصي.';
	@override String get name_taken => 'هذا الاسم مستخدم بالفعل. يُرجى اختيار اسم آخر.';
	@override String get name_invalid => 'يمزج هذا الاسم أحرفًا من أبجديات مختلفة، وهذا غير مسموح.';
	@override String get avatar_upload => 'رفع صورة';
	@override String get avatar_remove => 'إزالة';
	@override String get avatar_hint => 'JPG أو PNG أو GIF — بحد أقصى 500 ك.ب';
	@override String get avatar_pick_error => 'تعذّر اختيار الصورة.';
	@override String get avatar_too_large => 'الصورة كبيرة جدًا (الحد 500 ك.ب).';
	@override String get email => 'البريد الإلكتروني';
	@override String get roles => 'الأدوار';
	@override String get member_since => 'عضو منذ';
	@override String get role_creator => 'منشئ محتوى';
	@override String get role_advertiser => 'معلن';
	@override String get role_user => 'مستخدم';
}

// Path: security
class _TranslationsSecurityAr extends TranslationsSecurityEn {
	_TranslationsSecurityAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get nav_title => 'الأمان';
	@override String get entry_title => 'كلمة المرور والجلسات';
	@override String get entry_sub => 'تغيير كلمة المرور وإدارة الأجهزة المتصلة';
	@override String get change_password_title => 'تغيير كلمة المرور';
	@override String get password_management_title => 'كلمة المرور';
	@override String get current_password => 'كلمة المرور الحالية';
	@override String get new_password => 'كلمة المرور الجديدة';
	@override String get confirm_password => 'تأكيد كلمة المرور';
	@override String get update_password => 'تحديث كلمة المرور';
	@override String get updating_password => 'جاري التحديث…';
	@override String get password_updated => 'تم تحديث كلمة المرور.';
	@override String get password_oauth_message => 'سجّلت الدخول عبر Google أو Apple. إدارة كلمة المرور تتم عبر مزودك. لتغييرها، استخدم إعدادات حساب Google أو Apple.';
	@override String get all_fields_required => 'جميع الحقول مطلوبة.';
	@override String get password_min_length => '8 أحرف على الأقل.';
	@override String get password_same_as_current => 'يجب أن تختلف كلمة المرور الجديدة عن الحالية.';
	@override String get password_wrong_current => 'كلمة المرور الحالية غير صحيحة.';
	@override String get password_change_error => 'تعذّر تحديث كلمة المرور. حاول مرة أخرى.';
}

// Path: account_deletion
class _TranslationsAccountDeletionAr extends TranslationsAccountDeletionEn {
	_TranslationsAccountDeletionAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get nav_title => 'حذف الحساب';
	@override String get title => 'حذف حساب Wayo Ads';
	@override String get danger_zone_chip => 'منطقة الخطر';
	@override String get danger_zone_intro => 'يحذف حسابك وجميع البيانات المرتبطة به نهائيًا. بعد انتهاء فترة السماح لا يمكن التراجع عن ذلك.';
	@override String get danger_what_title => 'ما الذي سيُحذف:';
	@override String get danger_item_profile => 'ملفك الشخصي ومعلوماتك';
	@override String get danger_item_campaigns => 'جميع حملاتك وبيانات أدائها';
	@override String get danger_item_business => 'ملف عملك ومعلومات علامتك';
	@override String get danger_item_wallet => 'محفظتك كمعلن وسجل المعاملات';
	@override String get danger_item_notifications => 'إشعاراتك وتفضيلات البريد';
	@override String get danger_item_access => 'وصولك إلى Wayo Ads (لن تتمكن من تسجيل الدخول هنا مجددًا)';
	@override String get danger_wayo_note => 'يُتأثر فقط بيانات Wayo Ads. حساب Wayo (لتسجيل الدخول) يبقى نشطًا لخدمات Wayo الأخرى.';
	@override String get subtitle_warning => 'تنبيه: بعد 30 يومًا ستُحذف بيانات Wayo Ads نهائيًا. يمكنك الإلغاء في أي وقت قبل ذلك.';
	@override String get bullet_loss => 'الحملات والطلبات وبيانات الملف في التطبيق تُحذف بعد فترة السماح.';
	@override String get bullet_wallet => 'رصيد المحفظة والفواتير وسجل المعاملات المرتبطة بهذا الحساب تُزال.';
	@override String get bullet_cancel => 'نافذة إلغاء مجانية لمدة 30 يومًا من الطلب.';
	@override String get bullet_recreate => 'معرّف Wayo (تسجيل الدخول) لا يُحذف بهذه الخطوة — يمكنك تسجيل الدخول لاحقًا وبملف جديد.';
	@override String get role_advertiser => 'معلن: تتوقف الحملات النشطة عند مسح البيانات.';
	@override String get role_creator => 'مبدع: الطلبات والقنوات والأرباح في التطبيق تُحذف.';
	@override String get continue_cta => 'متابعة';
	@override String get back => 'رجوع';
	@override String get more_info_title => 'قبل المتابعة';
	@override String get more_info_body => 'رسائل البريد: تأكيد الآن، ثم تذكير قبل الحذف ببضعة أيام.\nالدعم: تواصل معنا لتصدير بياناتك أو إغلاق الحملات.';
	@override String get step_auth_title => 'تأكيد الهوية';
	@override String get status_active => 'لا يوجد حذف مجدول لهذا الحساب.';
	@override String status_pending({required Object date}) => 'الحذف مجدول بالفعل. التاريخ النهائي: ${date}';
	@override String get password_label => 'كلمة المرور';
	@override String get password_hint => '8 أحرف على الأقل';
	@override String get forgot_password => 'نسيت كلمة المرور؟';
	@override String get oauth_note => 'إذا سجّلت الدخول فقط عبر Google أو Apple، عيّن كلمة مرور أولًا (نسيت كلمة المرور).';
	@override String get oauth_deletion_intro => 'تسجّل الدخول عبر Google أو Apple. لحمايتك، ستعيد المصادقة لدى مزوّدك قبل جدولة الحذف.';
	@override String get oauth_deletion_step_hint => 'تم التحقق من هويتك عند تسجيل الدخول بـ Google أو Apple. اضغط الزر أدناه لعرض ورقة التأكيد النهائية.';
	@override String get oauth_reauth_intro => 'لحمايتك، أكّد هويتك بإعادة تسجيل الدخول عبر المزوّد الذي تستخدمه مع Wayo Ads. ستتم جدولة الحذف مباشرةً بعد ذلك.';
	@override String get oauth_reauth_google => 'إعادة المصادقة عبر Google';
	@override String get oauth_reauth_apple => 'إعادة المصادقة عبر Apple';
	@override String get oauth_reauth_cancelled => 'تم إلغاء إعادة المصادقة.';
	@override String get oauth_reauth_failed => 'فشلت إعادة المصادقة. يُرجى المحاولة مرة أخرى.';
	@override String get oauth_reauth_mismatch => 'يُرجى إعادة المصادقة بنفس الحساب الذي تستخدمه مع Wayo Ads.';
	@override String get error_reauth_required => 'إعادة المصادقة مطلوبة لحذف حسابك. يُرجى تسجيل الدخول مجددًا عبر مزوّدك.';
	@override String legal_recap({required Object date}) => 'ستبدأ فترة سماح 30 يومًا قبل الحذف النهائي. يمكنك الإلغاء حتى ${date}.';
	@override String get next_review => 'مراجعة وتأكيد';
	@override String get dialog_title => 'هل أنت متأكد؟';
	@override String get dialog_body => 'ستُجدول بيانات Wayo Ads للحذف. الحذف النهائي في:';
	@override String get dialog_cancel_hint => 'يمكنك الإلغاء في أي وقت من الإعدادات حتى ذلك التاريخ.';
	@override String get timeline_request => 'الطلب';
	@override String get timeline_reminder => 'تذكير بالبريد';
	@override String get timeline_purge => 'الحذف';
	@override String get dialog_confirm => 'نعم، جدولة الحذف';
	@override String get dialog_dismiss => 'الإبقاء على حسابي';
	@override String get success_title => 'تم جدولة الحذف';
	@override String get success_intro => 'ماذا يحدث الآن؟';
	@override String get success_use_until => 'يمكنك مواصلة استخدام Wayo Ads حتى التاريخ النهائي.';
	@override String get success_reminder => 'سنرسل تذكيرًا قبل الحذف بأيام قليلة.';
	@override String get success_cancel_anytime => 'ألغِ في أي وقت من هذه الشاشة أو الإعدادات.';
	@override String days_left({required Object n}) => 'الأيام المتبقية: ${n}';
	@override String purge_date({required Object date}) => 'الحذف النهائي: ${date}';
	@override String reminder_approx({required Object date}) => 'تذكير تقريبي: ${date}';
	@override String get cancel_request => 'إلغاء الحذف';
	@override String get go_home => 'العودة للرئيسية';
	@override String get toast_cancelled => 'أُلغي الحذف. عُاد حسابك.';
	@override String get error_load => 'تعذر تحميل حالة الحساب.';
	@override String get error_load_unauthorized => 'تعذر التحقق من جلستك مع Wayo Ads. سجّل الخروج ثم الدخول مجددًا وأعد المحاولة.';
	@override String get error_load_network => 'تحقق من الاتصال وإمكانية الوصول إلى Wayo Ads، ثم أعد المحاولة.';
	@override String get error_delete => 'حدث خطأ. حاول مجددًا.';
	@override String get error_password => 'كلمة مرور غير صحيحة. أعد المحاولة أو أعد التعيين.';
	@override String get error_superadmin => 'لا يمكن لحسابات المشرف الأعلى طلب الحذف.';
	@override String get funds_warning => 'تنبيه: سيتم حذف رصيد محفظتك وأي طلبات سحب معلّقة نهائيًا. اسحب أموالك قبل التأكيد.';
	@override String banner_line({required Object date, required Object n}) => 'سيُحذف حسابك في ${date} (${n} يومًا متبقيًا).';
	@override String get banner_cancel_dialog_title => 'إلغاء الحذف المجدول؟';
	@override String get banner_cancel_dialog_body => 'يظل ملف Wayo Ads نشطًا.';
	@override String get banner_cancel_dialog_confirm => 'الإبقاء على حسابي';
	@override String pending_danger_card_body({required Object date}) => 'حُدد حسابك للحذف النهائي في ${date}. يمكنك إلغاء هذا الطلب في أي وقت قبل ذلك.';
	@override String get pending_scheduled_status => 'حذف الحساب مجدول';
	@override String get pending_days_remaining_one => 'يوم واحد متبقي';
	@override String pending_days_remaining_plural({required Object n}) => '${n} يومًا متبقيًا';
}

// Path: onboarding
class _TranslationsOnboardingAr extends TranslationsOnboardingEn {
	_TranslationsOnboardingAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get role_gate_title => 'اختر ملفك';
	@override String get role_gate_subtitle => 'نفس الخطوة كما على موقع Wayo Ads قبل استخدام التطبيق.';
	@override String get role_creator_cta => 'مبدع';
	@override String get role_creator_desc => 'تصفح الحملات وتقدّم وتعاون مع العلامات.';
	@override String get role_advertiser_cta => 'معلن';
	@override String get role_advertiser_desc => 'أطلق الحملات وأدر المبدعين من لوحة التحكم.';
	@override String get email_code_title => 'تأكيد البريد';
	@override String email_code_subtitle({required Object email}) => 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى ${email}.';
	@override String get email_code_subtitle_prefix => 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى ';
	@override String get email_code_subtitle_suffix => '.';
	@override String get email_code_hide_my_email_warning => 'سجّلت الدخول بخيار إخفاء بريدي الإلكتروني من Apple. غالبًا لا تصل رموز التحقق إلى عناوين التوجيه. سجّل الخروج، ثم سجّل الدخول مجددًا عبر Apple واختر مشاركة بريدي الإلكتروني، أو استخدم بريد iCloud الحقيقي مع كلمة المرور.';
	@override String get email_code_otp_label => 'أدخل رمز التحقق';
	@override String get email_code_sending => 'جارٍ إرسال الرمز...';
	@override String get email_code_verifying => 'جارٍ التحقق...';
	@override String get skip => 'تخطي';
	@override String get next => 'التالي';
	@override String get done => 'حسنًا';
	@override late final _TranslationsOnboardingAdvertiserAr advertiser = _TranslationsOnboardingAdvertiserAr._(_root);
	@override late final _TranslationsOnboardingCreatorAr creator = _TranslationsOnboardingCreatorAr._(_root);
}

// Path: dashboard.balance
class _TranslationsDashboardBalanceAr extends TranslationsDashboardBalanceEn {
	_TranslationsDashboardBalanceAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'نظرة على الرصيد';
	@override String get available => 'متاح';
	@override String get locked => 'محجوز';
	@override String get spent => 'منفق';
}

// Path: dashboard.campaigns
class _TranslationsDashboardCampaignsAr extends TranslationsDashboardCampaignsEn {
	_TranslationsDashboardCampaignsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'حملاتك';
	@override String get subtitle => 'أدر حملاتك وتابع أداءها.';
	@override String get creators => '{count} مبدعين';
	@override String get empty_title => 'لا حملات بعد';
	@override String get empty_subtitle => 'أنشئ حملتك الأولى للبدء';
	@override String get create_cta => 'إنشاء حملة';
	@override String get pagination_previous => 'السابق';
	@override String get pagination_next => 'التالي';
	@override String pagination_page({required Object current, required Object total}) => 'الصفحة ${current} / ${total}';
}

// Path: dashboard.errors
class _TranslationsDashboardErrorsAr extends TranslationsDashboardErrorsEn {
	_TranslationsDashboardErrorsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get load_balance => 'تعذر تحميل الرصيد';
	@override String get load_campaigns => 'تعذر تحميل الحملات';
	@override String get retry => 'إعادة المحاولة';
}

// Path: advertiser_campaigns.browse
class _TranslationsAdvertiserCampaignsBrowseAr extends TranslationsAdvertiserCampaignsBrowseEn {
	_TranslationsAdvertiserCampaignsBrowseAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'استكشاف الحملات';
	@override String get subtitle => 'تصفّح الحملات النشطة في السوق — للمقارنة والإلهام من العلامات الأخرى.';
	@override String get search_placeholder => 'البحث عن حملة';
	@override String get empty_title => 'لا توجد حملات نشطة';
	@override String get empty_subtitle => 'تظهر الحملات الجديدة هنا عند إطلاقها.';
	@override String get empty_search_title => 'لا توجد حملات مطابقة';
	@override String get empty_search_subtitle => 'جرّب كلمة أخرى أو أعد ضبط الفلاتر.';
}

// Path: advertiser_campaigns.tabs
class _TranslationsAdvertiserCampaignsTabsAr extends TranslationsAdvertiserCampaignsTabsEn {
	_TranslationsAdvertiserCampaignsTabsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get active => 'نشطة';
	@override String get draft => 'مسودات';
	@override String get paused => 'معلّقة';
	@override String get under_review => 'قيد المراجعة';
	@override String get completed => 'مكتملة';
	@override String get cancelled => 'ملغاة';
}

// Path: advertiser_campaigns.empty
class _TranslationsAdvertiserCampaignsEmptyAr extends TranslationsAdvertiserCampaignsEmptyEn {
	_TranslationsAdvertiserCampaignsEmptyAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get none => 'لا توجد حملات';
	@override String get hint => 'لا توجد لديك حملات بهذه الحالة بعد.';
	@override String get search => 'لا نتائج مطابقة للبحث';
	@override String get search_hint => 'جرّب اسماً مختلفاً أو امسح البحث.';
}

// Path: advertiser_campaigns.card
class _TranslationsAdvertiserCampaignsCardAr extends TranslationsAdvertiserCampaignsCardEn {
	_TranslationsAdvertiserCampaignsCardAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get budget_total => 'الميزانية';
	@override String get remaining => 'المتبقي';
	@override String get locked => 'محجوز';
	@override String get spent => 'المنفق';
	@override String get cpc => 'CPC';
	@override String get cpm => 'CPM';
	@override String get badge_new => 'جديد';
	@override String get valid_engagements => '{count} مشاهدة مُصدّقة';
	@override String get list_row_views => '{count} مشاهدة';
	@override String get list_row_clicks => '{count} نقرات';
	@override String get list_row_creators => '{count} منشئين';
}

// Path: advertiser_campaigns.status
class _TranslationsAdvertiserCampaignsStatusAr extends TranslationsAdvertiserCampaignsStatusEn {
	_TranslationsAdvertiserCampaignsStatusAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get active => 'نشطة';
	@override String get paused => 'معلّقة';
	@override String get under_review => 'قيد المراجعة';
	@override String get completed => 'مكتملة';
	@override String get cancelled => 'ملغاة';
	@override String get draft => 'مسودة';
	@override String get other => 'أخرى';
}

// Path: advertiser_campaigns.platform
class _TranslationsAdvertiserCampaignsPlatformAr extends TranslationsAdvertiserCampaignsPlatformEn {
	_TranslationsAdvertiserCampaignsPlatformAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get youtube => 'YouTube';
	@override String get tiktok => 'TikTok';
	@override String get instagram => 'Instagram';
	@override String get other => 'منصة';
}

// Path: advertiser_campaigns.detail
class _TranslationsAdvertiserCampaignsDetailAr extends TranslationsAdvertiserCampaignsDetailEn {
	_TranslationsAdvertiserCampaignsDetailAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get fallback_title => 'حملة';
	@override String get metrics_title => 'الأداء';
	@override String get budget_usage_title => 'استخدام الميزانية';
	@override String get budget_usage_spent => 'المصروف';
	@override String get budget_usage_remaining => 'المتبقّي';
	@override String get valid_views => 'مشاهدات مُصدّقة';
	@override String get valid_clicks => 'نقرات صالحة';
	@override String get approved_creators => 'منشئون معتمدون';
	@override String get platform_label => 'المنصة';
	@override String get campaign_type_label => 'نوع الحملة';
	@override String get niche_label => 'المجال';
	@override String get location_label => 'الموقع';
	@override String get objective_label => 'الهدف';
	@override String get objective_awareness => 'الوعي بالعلامة';
	@override String get objective_traffic => 'الزيارات';
	@override String get objective_conversion => 'التحويل';
	@override String get cpm_metric => 'CPM (لكل 1000 مشاهدة)';
	@override String get cpm_consumed => 'CPM المستهلك (لكل 1000 مشاهدة)';
	@override String get cpc_metric => 'CPC (لكل نقرة)';
	@override String get description_title => 'الوصف';
	@override String get show_more => 'عرض المزيد';
	@override String get show_less => 'عرض أقل';
	@override String get top_creators_title => 'أفضل المنشئين';
	@override String get top_creators_subtitle => 'أفضل المنشئين لديك، مرتبين حسب المشاهدات المعتمدة.';
	@override String top_creators_views({required Object count}) => '${count} مشاهدة معتمدة';
	@override String get top_creators_earned => 'ربح';
	@override String get top_creators_empty_title => 'لا توجد نتائج بعد';
	@override String get top_creators_empty_subtitle => 'ستظهر إحصائيات المنشئين هنا بمجرد أن يبدأ المنشئون المعتمدون في تحقيق المشاهدات.';
}

// Path: advertiser_campaigns.create
class _TranslationsAdvertiserCampaignsCreateAr extends TranslationsAdvertiserCampaignsCreateEn {
	_TranslationsAdvertiserCampaignsCreateAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'حملة جديدة';
	@override String get section_basics => 'المعلومات الأساسية';
	@override String get section_budget => 'الميزانية والتسعير';
	@override String get field_type => 'نوع الحملة';
	@override String get field_objective => 'هدف الحملة';
	@override String get field_niche => 'المجال / القطاع';
	@override String get field_title => 'العنوان';
	@override String get field_description => 'الوصف (اختياري)';
	@override String get field_landing => 'رابط الصفحة المستهدفة';
	@override String get field_assets => 'رابط الموجز / الأصول';
	@override String get field_budget => 'الميزانية الإجمالية';
	@override String get field_cpm_hint => 'CPM — التكلفة لكل 1000 ظهور (بالسنت)';
	@override String get field_cpc_hint => 'CPC — التكلفة لكل نقرة (بالسنت)';
	@override String get field_video_min_duration => 'الحد الأدنى لطول الفيديو (بالدقائق)';
	@override String get field_shorts_max_duration => 'الحد الأقصى لطول القصير (بالثواني)';
	@override String get type_link => 'رابط';
	@override String get type_video => 'فيديو';
	@override String get type_shorts => 'قصير';
	@override String get landing_help => 'مطلوب لحملات الرابط (https).';
	@override String get assets_help => 'الفيديو والقصير يتطلبان رابطًا https لـ Drive أو OneDrive أو SharePoint.';
	@override String get submit_draft => 'حفظ كمسودة';
	@override String get validation_title => 'راجع الحقول.';
	@override String get assets_url_invalid => 'استخدم عنوان https لـ Google Drive أو OneDrive أو SharePoint.';
	@override String get success => 'تم إنشاء الحملة (مسودة)';
	@override String get submit_in_progress => 'جارٍ الحفظ…';
}

// Path: advertiser_campaigns.applications
class _TranslationsAdvertiserCampaignsApplicationsAr extends TranslationsAdvertiserCampaignsApplicationsEn {
	_TranslationsAdvertiserCampaignsApplicationsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'طلبات المنشئين';
	@override String pending_badge({required Object count}) => '${count} في الانتظار';
	@override String get subtitle => 'راجع واعتمد أو ارفض طلبات المنشئين';
	@override String get empty_title => 'لا توجد طلبات';
	@override String get empty_subtitle => 'عندما يقدم المنشئون طلباتهم ستظهر هنا.';
	@override String get load_error => 'تعذّر تحميل الطلبات';
	@override String trust_score({required Object score}) => 'الثقة: ${score}';
	@override String get approve_button => 'اعتماد';
	@override String get reject_button => 'رفض';
	@override String get approved_status => 'معتمد';
	@override String get rejected_status => 'مرفوض';
}

// Path: advertiser_campaigns.actions
class _TranslationsAdvertiserCampaignsActionsAr extends TranslationsAdvertiserCampaignsActionsEn {
	_TranslationsAdvertiserCampaignsActionsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get publish => 'نشر';
	@override String get pause => 'إيقاف مؤقت';
	@override String get resume => 'استئناف';
	@override String get cancel => 'إلغاء الحملة';
	@override String get edit => 'تعديل';
	@override String get more => 'المزيد';
	@override String get analytics => 'التحليلات';
	@override String get financial => 'الصحة المالية';
	@override String get financial_health => 'الصحة المالية';
	@override String get status_updated => 'تم تحديث حالة الحملة';
	@override String get status_error => 'تعذّر تحديث حالة الحملة';
	@override String get cancel_confirm_title => 'إلغاء هذه الحملة؟';
	@override String get cancel_confirm_body => 'ستُعاد الميزانية المحجوزة المتبقية إلى محفظتك.';
	@override String get dismiss => 'الإبقاء على الحملة';
	@override String get confirm => 'إلغاء الحملة';
}

// Path: creator.dashboard
class _TranslationsCreatorDashboardAr extends TranslationsCreatorDashboardEn {
	_TranslationsCreatorDashboardAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'استوديو المبدع';
	@override String get subtitle => 'تابع إحصائياتك وطلباتك وأرباحك في الوقت الفعلي.';
	@override String get coming_soon_title => 'لوحة تحكّم المبدع';
	@override String get coming_soon_subtitle => 'ستظهر هنا الإحصائيات والتحليلات والطلبات النشطة. التحديث الحي مفعَّل — لا حاجة للتحديث اليدوي.';
}

// Path: creator.wallet
class _TranslationsCreatorWalletAr extends TranslationsCreatorWalletEn {
	_TranslationsCreatorWalletAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get coming_soon_title => 'أرباحك';
	@override String get coming_soon_subtitle => 'الرصيد المتاح، المدفوعات المعلّقة وسجل Stripe ستظهر هنا.';
	@override String get connect_stripe_title => 'ربط Stripe';
	@override String get connect_stripe_subtitle => 'اربط حسابك المصرفي عبر Stripe لتفعيل السحوبات. لا نحفظ أي بيانات مصرفية.';
	@override String get withdraw_title => 'طلب سحب';
	@override String get withdraw_subtitle => 'اسحب رصيدك المتاح إلى حساب Stripe المربوط.';
	@override String get available_balance => 'المتاح';
	@override String get pending_balance => 'قيد الانتظار';
	@override String get pending_withdrawals => 'سحوبات قيد المعالجة';
	@override String get in_transit => 'قيد التحويل';
	@override String get total_earned => 'إجمالي الأرباح';
	@override String get lifetime_earnings => 'الأرباح التراكمية';
	@override String get load_error => 'تعذّر تحميل محفظتك';
	@override String get withdraw_button => 'سحب';
	@override String get withdraw_sheet_title => 'طلب سحب';
	@override String get withdraw_sheet_subtitle => 'الرصيد المتاح: {available}. ستُحوَّل الأموال إلى حساب Stripe المربوط.';
	@override String get withdraw_amount_label => 'المبلغ (USD)';
	@override String get withdraw_sheet_body => 'أدخل المبلغ الذي تريد سحبه. سيتم تحويل الأموال إلى حسابك البنكي المرتبط.';
	@override String get withdraw_quick_amounts => 'مبالغ سريعة';
	@override String get withdraw_gross_amount => 'المبلغ الإجمالي';
	@override String get withdraw_platform_fee => 'رسوم المنصة ({percent}%)';
	@override String get withdraw_tax_vat => 'ضريبة القيمة المضافة ({percent}%)';
	@override String get withdraw_net_received => 'صافي المستلم';
	@override String get withdraw_submit => 'تأكيد السحب';
	@override String get withdraw_submitting => 'جارٍ المعالجة…';
	@override String get withdraw_max => 'الحد الأقصى';
	@override String get withdraw_preset_all => 'الكل';
	@override String get withdraw_success => 'تم إرسال طلب السحب.';
	@override String get withdraw_secure_footer => 'سحب آمن — تعالجه Stripe. بياناتك المصرفية لا تصل إلينا أبدًا.';
	@override String get withdraw_error_invalid => 'أدخل مبلغًا صالحًا.';
	@override String get withdraw_error_min => 'الحد الأدنى للسحب هو {min}.';
	@override String get withdraw_error_insufficient => 'الرصيد المتاح غير كافٍ.';
	@override String get withdraw_reason_business_info => 'أكمل معلومات نشاطك التجاري قبل ربط حساب الدفع.';
	@override String get withdraw_reason_stripe => 'قم بربط Stripe لتفعيل السحب.';
	@override String get withdraw_reason_stripe_incomplete => 'أكمل إعداد Stripe لتفعيل السحب.';
	@override String get withdraw_reason_payouts_disabled => 'حساب Stripe الخاص بك غير مفعَّل للمدفوعات بعد.';
	@override String get withdraw_reason_below_min => 'الحد الأدنى للسحب هو {min}.';
	@override String get cancel_action => 'إلغاء الطلب';
	@override String get cancel_in_progress => 'جارٍ الإلغاء…';
	@override String get cancel_dialog_title => 'إلغاء هذا السحب؟';
	@override String get cancel_dialog_message => 'سيتم إلغاء السحب المعلق وإعادة المبلغ إلى رصيدك المتاح.';
	@override String get cancel_dialog_yes => 'إلغاء السحب';
	@override String get cancel_dialog_no => 'الاحتفاظ به';
	@override String get cancel_success => 'تم إلغاء السحب واستعادة المبلغ.';
	@override String get stripe_connected => 'متصل';
	@override String get stripe_onboarding_required_pill => 'إجراء مطلوب';
	@override String get stripe_connect_action => 'ربط Stripe';
	@override String get stripe_complete_action => 'إكمال الإعداد';
	@override String get stripe_open_dashboard => 'فتح لوحة Stripe';
	@override String get stripe_error => 'حدث خطأ مع Stripe. يرجى المحاولة مجددًا.';
	@override String get stripe_edit_business_action => 'تعديل بيانات النشاط';
	@override String get stripe_card_title_disconnected => 'ربط Stripe';
	@override String get stripe_card_subtitle_disconnected => 'اربط حسابك المصرفي عبر Stripe لاستلام المدفوعات.';
	@override String get stripe_card_title_incomplete => 'أكمل الإعداد';
	@override String get stripe_card_subtitle_incomplete => 'تحتاج Stripe بعض المعلومات قبل تفعيل المدفوعات.';
	@override String get stripe_card_title_connected => 'Stripe متصل';
	@override String get stripe_card_subtitle_connected => 'حساب Stripe Express نشط. المدفوعات تصل إلى بنكك.';
	@override String get history_title => 'سجل السحوبات';
	@override String get documents_cta => 'الكشوفات';
	@override String get documents_cta_subtitle => 'ملفات PDF موقعة للمدفوعات ووثائق الأرباح';
	@override String get history_empty => 'لا توجد سحوبات بعد — ستظهر هنا.';
	@override String get history_load_error => 'تعذّر تحميل سجل السحوبات.';
	@override String get history_status_pending => 'قيد الانتظار';
	@override String get history_status_processing => 'قيد المعالجة';
	@override String get history_status_succeeded => 'مدفوع';
	@override String get history_status_failed => 'فشل';
	@override String get history_status_cancelled => 'ملغى';
	@override String get conditions_title => 'شروط السحب';
	@override String get conditions_subtitle => 'معلومات مفيدة قبل طلب الدفع.';
	@override String get conditions_min_label => 'الحد الأدنى للسحب';
	@override String get conditions_fee_label => 'العمولة';
	@override String conditions_fee_value({required Object percent}) => '${percent} (بدون ضريبة)';
	@override String get conditions_processing_label => 'مدة المعالجة';
	@override String get conditions_processing_value => '2 إلى 5 أيام عمل';
}

// Path: creator.campaigns
class _TranslationsCreatorCampaignsAr extends TranslationsCreatorCampaignsEn {
	_TranslationsCreatorCampaignsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get browse_title => 'استكشاف الحملات';
	@override String get browse_subtitle => 'ابحث عن الحملات المناسبة لجمهورك وقدّم طلبك بنقرة واحدة.';
	@override String get browse_search_placeholder => 'ابحث بالاسم، النوع أو العلامة';
	@override String get browse_empty_search_title => 'لا توجد حملات مطابقة';
	@override String get browse_empty_search_subtitle => 'جرّب كلمة أخرى — الاسم، النوع (فيديو، شورتس، رابط) أو اسم المعلن.';
	@override String get applications_title => 'طلباتي';
	@override String get applications_subtitle => 'تابع حالة كل طلب: قُبل، قيد المراجعة، أو مرفوض.';
	@override String get submit_title => 'تقديم منشور';
	@override String get submit_subtitle => 'بعد الموافقة، شارك رابط فيديو علني ليراجعه المعلن.';
	@override String get details_title => 'تفاصيل الحملة';
	@override String get application_title => 'طلبي';
	@override String get not_found_title => 'الحملة غير متاحة';
	@override String get not_found_desc => 'هذه الحملة غير متاحة أو ربما أُزيلت.';
	@override String get cancelled_not_available => 'أُلغيت هذه الحملة ولم تعد متاحة.';
	@override String get completed_not_available => 'انتهت هذه الحملة ولم تعد متاحة.';
	@override String get paused_not_available => 'هذه الحملة معلّقة حالياً وغير متاحة.';
	@override String get cancelled_owner_banner => 'أُلغيت هذه الحملة.';
	@override String get load_error => 'تعذّر تحميل الحملات.';
	@override String get empty_title => 'لا توجد حملات حالياً';
	@override String get empty_subtitle => 'ستظهر هنا الحملات الجديدة فور إطلاقها من طرف المعلنين.';
	@override String get pagination_previous => 'السابق';
	@override String get pagination_next => 'التالي';
	@override String pagination_page({required Object current, required Object total}) => 'الصفحة ${current} / ${total}';
	@override String get description_title => 'الوصف';
	@override String get requirements_title => 'المتطلبات';
	@override String get assets_title => 'عناصر العلامة';
	@override String get assets_subtitle => 'حمّل ملف الموجز والشعارات واللقطات.';
	@override String get type_link => 'رابط';
	@override String get type_video => 'فيديو';
	@override String get type_shorts => 'Shorts';
	@override String get reward_cpm_label => 'الكلفة لكل 1000';
	@override String get reward_cpc_label => 'المكافأة لكل نقرة';
	@override String get reward_per_view_label => 'المكافأة لكل مشاهدة';
	@override String reward_per_view({required Object amount}) => '${amount} / مشاهدة';
	@override String reward_per_click({required Object amount}) => '${amount} / نقرة';
	@override String get budget_remaining_label => 'الميزانية المتبقية';
	@override String get earnings_card_title => 'أرباحي من هذه الحملة';
	@override String get earnings_card_subtitle => 'أداؤك وتفاصيل المدفوعات';
	@override String get earnings_net => 'صافي الأرباح';
	@override String get earnings_views => 'مشاهدات مدفوعة';
	@override String get earnings_platform_views => 'مشاهدات المنصة';
	@override String get earnings_valid_clicks => 'نقرات مدفوعة';
	@override String get earnings_recorded_clicks => 'نقرات مسجّلة';
	@override String get earnings_available_balance => 'الرصيد المتاح';
	@override String requirement_platform({required Object platform}) => 'انشر على ${platform} فقط';
	@override String requirement_min_duration({required Object minutes}) => 'أدنى مدة: ${minutes} دقيقة';
	@override String requirement_shorts_max({required Object seconds}) => 'Shorts حتى ${seconds} ثانية';
	@override String get requirement_vertical => 'صيغة عمودية (9:16) مطلوبة';
	@override String get requirement_none => 'لا توجد متطلبات خاصة.';
	@override String get apply_cta => 'قدّم طلبك لهذه الحملة';
	@override String get apply_title => 'تقديم طلب';
	@override String get apply_message_label => 'عرضك (اختياري)';
	@override String get apply_message_hint => 'اشرح للمعلن لماذا أنت المرشح المثالي…';
	@override String get apply_submit => 'إرسال الطلب';
	@override String get apply_in_progress => 'جارٍ الإرسال…';
	@override String get apply_error => 'تعذّر إرسال طلبك. حاول مرة أخرى.';
	@override String get apply_success => 'تم إرسال طلبك — ستصلك إشعار بعد المراجعة.';
	@override String get apply_pending_title => 'الطلب قيد المراجعة';
	@override String get apply_pending_subtitle => 'سنعلمك فور ردّ المعلن.';
	@override String get open_application_cta => 'فتح طلبي';
	@override String get chat_with_advertiser => 'محادثة المعلن';
	@override String get status_banner_approved_title => 'تمت الموافقة عليك!';
	@override String get status_banner_approved_subtitle => 'يمكنك الآن تقديم الفيديو ومراسلة المعلن.';
	@override String get status_banner_pending_title => 'بانتظار ردّ المعلن';
	@override String get status_banner_pending_subtitle => 'عرضك قيد المراجعة — سنخبرك هنا عند اتخاذ القرار.';
	@override String get status_banner_rejected_title => 'لم يتم اختيارك هذه المرة';
	@override String get status_banner_rejected_subtitle => 'راقب علامة الحملات — كل أسبوع حملات جديدة.';
	@override String get my_submissions_title => 'مشاركاتي';
	@override String get my_submissions_empty_approved => 'لم ترسل أي فيديو بعد. أرسل واحداً لتبدأ الربح.';
	@override String get my_submissions_empty_pending => 'تُفتح خانة الإرسال بعد قبول طلبك.';
	@override String get submit_cta => 'تقديم منشور';
	@override String get submit_platform_label => 'المنصة';
	@override String get submit_url_label => 'رابط الفيديو العلني';
	@override String get submit_url_hint => 'https://youtube.com/watch?v=…';
	@override String get submit_url_required => 'ألصق رابط الفيديو.';
	@override String get submit_url_invalid => 'أدخل رابطاً علنياً صالحاً.';
	@override String get submit_url_youtube_only => 'يُدعم حالياً فقط روابط YouTube.';
	@override String get submit_in_progress => 'جارٍ الإرسال…';
	@override String get submit_footer => 'يجب أن يبقى الفيديو علنياً طوال الحملة للتحقّق من المشاهدات.';
	@override String get submit_error => 'تعذّر إرسال الفيديو. حاول مجدداً.';
	@override String get submit_success => 'تم إرسال الفيديو — سيراجعه المعلن قريباً.';
	@override String get submit_blocked_limit => 'سبق أن أرسلت مشاركة لهذه الحملة. انتظر المراجعة.';
	@override String get youtube_connect_title => 'اربط قناة YouTube';
	@override String get youtube_connect_body => 'اربط قناتك على Wayo Ads (الويب) قبل إرسال فيديو أو Short. هذا يسمح بالتحقق من الفيديو غير المدرج.';
	@override String get youtube_reconnect_title => 'أعد ربط YouTube';
	@override String get youtube_reconnect_body => 'انتهت صلاحية ربط YouTube. افتح Wayo Ads على الويب لإعادة الربط ثم أرسل من التطبيق.';
	@override String get youtube_connect_cta => 'فتح إعدادات YouTube على الويب';
	@override String get submission_status_pending => 'قيد المراجعة';
	@override String get submission_status_approved => 'مقبول';
	@override String get submission_status_rejected => 'مرفوض';
	@override String get submission_status_flagged => 'تم الإبلاغ';
	@override String submission_views({required Object views}) => '${views} مشاهدة موثقة';
	@override String submission_pending_views({required Object views}) => '+${views} بانتظار التصديق';
	@override String submission_platform_views({required Object views}) => '${views} مشاهدة على المنصة';
	@override String get clicks_validated_label => 'نقرات معتمدة';
	@override String get clicks_recorded_label => 'نقرات مسجّلة';
	@override String get tracking_link_title => 'رابط التتبع الخاص بك';
	@override String get tracking_link_subtitle => 'شارك هذا الرابط القصير في السيرة أو المنشورات. يتم تتبع النقرات تلقائياً.';
	@override String get tracking_link_copy => 'نسخ الرابط';
	@override String get tracking_link_copied => 'تم النسخ!';
	@override String get tracking_link_preparing => 'يتم إعداد رابطك الفريد… اسحب للتحديث بعد لحظات.';
	@override String get tracking_link_error => 'تعذّر تحميل رابط التتبع.';
	@override String tracking_link_stats({required Object validated, required Object recorded}) => '${validated} نقرة مؤهلة · ${recorded} نقرة مسجّلة';
	@override String get tracking_link_destination_title => 'رابط الصفحة المستهدفة';
	@override String get tracking_link_open_destination => 'فتح الوجهة';
}

// Path: creator.stats
class _TranslationsCreatorStatsAr extends TranslationsCreatorStatsEn {
	_TranslationsCreatorStatsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get earnings_title => 'إجمالي الأرباح';
	@override String get pending => 'قيد الانتظار';
	@override String get validated_views => 'المشاهدات المعتمدة';
	@override String pending_validation({required Object count}) => '+${count} بانتظار التصديق';
	@override String get pending_validation_tooltip => 'يتم التحقق من المشاهدات عبر YouTube وسيتم تأكيدها خلال 48 ساعة قبل إضافتها إلى أرباحك.';
	@override String get total_valid_clicks => 'نقرات معتمدة';
	@override String get validation_rate => 'نسبة الاعتماد';
	@override String get approved_campaigns => 'الحملات المقبولة';
}

// Path: creator.applications
class _TranslationsCreatorApplicationsAr extends TranslationsCreatorApplicationsEn {
	_TranslationsCreatorApplicationsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get section_title => 'الطلبات النشطة';
	@override String get empty_title => 'لا توجد طلبات بعد';
	@override String get empty_subtitle => 'استعرض علامة التبويب «الحملات» وقدّم طلبك على ما يناسب جمهورك.';
	@override String get load_error => 'تعذّر تحميل طلباتك';
	@override String get status_pending => 'قيد المراجعة';
	@override String get status_approved => 'مقبولة';
	@override String get status_rejected => 'مرفوضة';
	@override String get status_withdrawn => 'مسحوبة';
	@override String get status_unknown => '—';
}

// Path: creator.business
class _TranslationsCreatorBusinessAr extends TranslationsCreatorBusinessEn {
	_TranslationsCreatorBusinessAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get cta_title => 'أكمل معلومات نشاطك التجاري';
	@override String get cta_subtitle => 'مطلوب قبل ربط حسابك المصرفي لضمان توجيه المدفوعات بشكل صحيح.';
	@override String get cta_required_pill => 'مطلوب';
	@override String get cta_button => 'Finalize your Business Information';
	@override String get dialog_title => 'معلومات النشاط التجاري';
	@override String get dialog_subtitle => 'قدّم بعض المعلومات القانونية حتى يتمكن Stripe من فتح حسابك ومعالجة المدفوعات.';
	@override String get section_type => 'نوع النشاط';
	@override String get section_company => 'الشركة';
	@override String get section_address => 'العنوان';
	@override String get section_stripe => 'بلد وعملة الدفع';
	@override String get type_personal_title => 'فرد / شخص خاص';
	@override String get type_personal_subtitle => 'أتلقى المدفوعات بصفتي فردًا.';
	@override String get type_company_title => 'شركة مسجّلة';
	@override String get type_company_subtitle => 'أعمل تحت كيان قانوني مسجّل.';
	@override String get company_name => 'اسم الشركة';
	@override String get vat_number => 'الرقم الضريبي';
	@override String get address => 'العنوان';
	@override String get address_line1 => 'العنوان (سطر 1)';
	@override String get address_line2 => 'العنوان (سطر 2، اختياري)';
	@override String get city => 'المدينة';
	@override String get postal_code => 'الرمز البريدي';
	@override String get state_region => 'المنطقة (اختياري)';
	@override String get state => 'الولاية / المقاطعة';
	@override String get country => 'البلد';
	@override String get currency => 'عملة الدفع';
	@override String get billing_currency => 'العملة المفضّلة';
	@override String get vat_optional => 'الرقم الضريبي (اختياري)';
	@override String get section_billing => 'بلد وعملة الفوترة';
	@override String get error_required => 'حقل مطلوب';
	@override String get save_and_continue => 'حفظ ومتابعة';
	@override String get submitting => 'جارٍ الحفظ…';
	@override String get footer_info => 'تُرسل هذه المعلومات إلى Stripe لتفعيل حساب الدفع. لن تصل إلينا بياناتك المصرفية أبدًا.';
	@override String get footer_info_global => 'تُستخدم للفواتير وشحن المحفظة. تتم معالجة المدفوعات بأمان عبر Stripe.';
	@override String get save_error => 'تعذّر حفظ المعلومات. يرجى المحاولة مجددًا.';
	@override late final _TranslationsCreatorBusinessValidationAr validation = _TranslationsCreatorBusinessValidationAr._(_root);
}

// Path: creator.trust
class _TranslationsCreatorTrustAr extends TranslationsCreatorTrustEn {
	_TranslationsCreatorTrustAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'درجة الثقة';
	@override String tier({required Object name}) => 'المستوى ${name}';
	@override String get verified => 'موثّق';
	@override String delta_up({required Object value}) => '+${value} هذا الأسبوع';
	@override String delta_down({required Object value}) => '-${value} هذا الأسبوع';
	@override String cpm_hint({required Object value}) => 'ارتفاع CPM محتمل: ${value}';
	@override String get breakdown_title => 'تفصيل الدرجة';
	@override String get validation_points => 'معدل التحقق';
	@override String get fraud_points => 'درجة الاحتيال';
	@override String get anomaly_points => 'درجة الشذوذ';
	@override String get open_analytics => 'عرض التحليلات';
}

// Path: creator.analytics
class _TranslationsCreatorAnalyticsAr extends TranslationsCreatorAnalyticsEn {
	_TranslationsCreatorAnalyticsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تحليلات المنشئ';
	@override String get period_7d => '7ي';
	@override String get period_30d => '30ي';
	@override String get period_90d => '90ي';
	@override String get load_error => 'تعذّر تحميل التحليلات';
	@override String get empty => 'لا توجد بيانات لهذه الفترة بعد';
	@override String get earnings => 'الأرباح';
	@override String get pending => 'قيد الانتظار';
	@override String get validated_views => 'مشاهدات موثّقة';
	@override String get validated_clicks => 'نقرات موثّقة';
	@override String get recorded_views => 'مشاهدات مسجّلة';
	@override String get recorded_clicks => 'نقرات مسجّلة';
	@override String get view_validation_rate => 'تحقق المشاهدات';
	@override String get click_validation_rate => 'تحقق النقرات';
	@override String period_meta({required Object days, required Object currency}) => 'آخر ${days} يوماً · ${currency}';
	@override String get active_campaigns => 'الحملات النشطة';
	@override String get daily_title => 'يومي';
	@override String get by_campaign => 'حسب الحملة';
	@override String get server_authority_note => 'المبالغ والمعدلات من الخادم. التطبيق لا يخترع قواعد مالية.';
}

// Path: onboarding.advertiser
class _TranslationsOnboardingAdvertiserAr extends TranslationsOnboardingAdvertiserEn {
	_TranslationsOnboardingAdvertiserAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get dashboard_title => 'لوحة التحكم';
	@override String get dashboard_subtitle => 'تابع رصيدك وحملاتك النشطة وإشعاراتك — كل التحديثات تصل فورًا.';
	@override String get campaigns_title => 'الحملات';
	@override String get campaigns_subtitle => 'أنشئ حملات جديدة، راجع الطلبات وراقب الأداء من مكان واحد.';
	@override String get wallet_title => 'المحفظة';
	@override String get wallet_subtitle => 'اشحن ميزانية رصيدك وتابع الإنفاق — محمي عبر Stripe.';
	@override String get invoices_title => 'الفواتير';
	@override String get invoices_subtitle => 'حمّل ملفات PDF المعتمدة للإيداعات وفوترة الحملات والتحويلات — كل ذلك في مكان واحد.';
	@override String get chat_title => 'الدردشة';
	@override String get chat_subtitle => 'تحدث مع المبدعين بعد اعتماد الحملة. محادثاتك متزامنة على جميع أجهزتك.';
}

// Path: onboarding.creator
class _TranslationsOnboardingCreatorAr extends TranslationsOnboardingCreatorEn {
	_TranslationsOnboardingCreatorAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get dashboard_title => 'لوحة المبدع';
	@override String get dashboard_subtitle => 'مؤشراتك الرئيسية وطلباتك النشطة وأرباحك تتحدث تلقائيًا دون الحاجة للتحديث اليدوي.';
	@override String get campaigns_title => 'تصفح وقدّم طلبك';
	@override String get campaigns_subtitle => 'اكتشف الحملات المتاحة، قدّم بنقرة واحدة وتابع حالة طلبك مباشرة.';
	@override String get wallet_title => 'الأرباح والسحوبات';
	@override String get wallet_subtitle => 'اطّلع على رصيدك واطلب تحويلاً عبر Stripe Connect واستعرض سحوباتك السابقة.';
	@override String get invoices_title => 'إيصالات الدفع';
	@override String get invoices_subtitle => 'صفِّ الأرباح والتحويلات، وحمّل ملفات PDF المعتمدة أو أرشيف ZIP — يُحدَّث تلقائياً أثناء استخدام التطبيق.';
	@override String get chat_title => 'تحدث مع المعلن';
	@override String get chat_subtitle => 'فور الاعتماد، تُفتح الدردشة للتنسيق مع المعلن حول المخرجات.';
}

// Path: creator.business.validation
class _TranslationsCreatorBusinessValidationAr extends TranslationsCreatorBusinessValidationEn {
	_TranslationsCreatorBusinessValidationAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get address_required => 'العنوان مطلوب';
	@override String get address_line_invalid => 'العنوان يحتوي على أحرف غير صالحة';
	@override String get city_required => 'المدينة مطلوبة';
	@override String get city_invalid => 'المدينة تحتوي على أحرف غير صالحة';
	@override String get postal_code_required => 'الرمز البريدي مطلوب';
	@override String get postal_code_invalid => 'الرمز البريدي غير صالح';
	@override String get country_required => 'البلد مطلوب';
	@override String get country_stripe_only => 'البلد غير مدعوم لمدفوعات Stripe';
	@override String get country_global_invalid => 'البلد غير مدعوم للفوترة';
	@override String get currency_required => 'العملة مطلوبة';
	@override String get currency_stripe_only => 'العملة غير مدعومة لمدفوعات Stripe';
	@override String get currency_global_invalid => 'العملة غير مدعومة للفوترة';
	@override String get company_name_required => 'اسم الشركة مطلوب';
	@override String get company_name_invalid => 'اسم الشركة يحتوي على أحرف غير صالحة';
	@override String get vat_number_required => 'الرقم الضريبي مطلوب';
	@override String get vat_number_invalid => 'صيغة الرقم الضريبي غير صالحة';
	@override String get state_required => 'الولاية / المقاطعة مطلوبة';
	@override String get state_invalid => 'الولاية / المنطقة غير صالحة';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'force_update.title': return 'مطلوب تحديث';
			case 'force_update.subtitle': return 'يتوفر إصدار جديد من Wayo Ads. يرجى التحديث من المتجر للمتابعة.';
			case 'force_update.action_update': return 'تحديث الآن';
			case 'force_update.checking': return 'جاري التحقق من التحديثات…';
			case 'maintenance.title': return 'سنعود قريباً';
			case 'maintenance.subtitle': return 'نقوم بترقية الخدمة بميزات جديدة. سنعود قريباً.';
			case 'maintenance.apology': return 'نعتذر عن الإزعاج ونقدّر صبركم.';
			case 'maintenance.copyright': return '© 2026 Wayo Ads. جميع الحقوق محفوظة.';
			case 'maintenance.support_email': return 'support@wayo.cloud';
			case 'maintenance.action_retry': return 'إعادة المحاولة';
			case 'connectivity.offline_title': return 'لا يوجد اتصال بالإنترنت';
			case 'connectivity.offline_subtitle': return 'تحقق من Wi‑Fi أو بيانات الجوال ثم أعد المحاولة.';
			case 'connectivity.offline_subtitle_radio_up': return 'يبدو أن الشبكة متصلة، لكننا لا نصل إلى الإنترنت أو خوادم Wayo. أعد المحاولة أو افتح إعدادات الشبكة.';
			case 'connectivity.reconnecting_title': return 'إعادة الاتصال…';
			case 'connectivity.reconnecting_subtitle': return 'جاري محاولة استعادة الاتصال.';
			case 'connectivity.weak_title': return 'اتصال ضعيف';
			case 'connectivity.weak_subtitle': return 'قد تكون بعض الإجراءات أبطأ من المعتاد.';
			case 'connectivity.restored': return 'تم استعادة الاتصال';
			case 'connectivity.action_retry': return 'إعادة المحاولة';
			case 'connectivity.action_settings': return 'إعدادات الشبكة';
			case 'connectivity.settings_unavailable': return 'تعذّر فتح إعدادات النظام.';
			case 'campaigns_explorer.filter_all_types': return 'كل الأنواع';
			case 'campaigns_explorer.filter_all_platforms': return 'كل المنصات';
			case 'campaigns_explorer.filter_all_niches': return 'كل المجالات';
			case 'campaigns_explorer.filter_all_locations': return 'كل المواقع';
			case 'campaigns_explorer.platform_youtube': return 'YouTube';
			case 'campaigns_explorer.platform_tiktok': return 'TikTok';
			case 'campaigns_explorer.platform_instagram': return 'Instagram';
			case 'campaigns_explorer.results_one': return 'حملة واحدة';
			case 'campaigns_explorer.results_many': return ({required Object n}) => '${n} حملة';
			case 'campaigns_explorer.layout_grid': return 'شبكة';
			case 'campaigns_explorer.layout_list': return 'قائمة';
			case 'campaigns_explorer.empty_filters': return 'لا توجد حملات مطابقة لهذه المرشحات.';
			case 'campaigns_explorer.empty_filters_subtitle': return 'أزل أحد المرشحات أو غيّر نوع الحملة — خيارات المجال تعرض ما ينسجم مع بقية اختياراتك.';
			case 'campaigns_explorer.search_aria': return 'البحث في الحملات';
			case 'campaigns_explorer.reset_filters': return 'إعادة ضبط المرشحات';
			case 'campaigns_explorer.toolbar_show_search_filters': return 'إظهار البحث والمرشحات';
			case 'campaigns_explorer.toolbar_hide_search_filters': return 'إخفاء البحث والمرشحات';
			case 'campaigns_explorer.filter_label_type': return 'النوع';
			case 'campaigns_explorer.filter_label_status': return 'الحالة';
			case 'campaigns_explorer.filter_label_niche': return 'المجال';
			case 'campaigns_explorer.filter_label_location': return 'الموقع';
			case 'login.brand': return 'وايو أدز';
			case 'login.headline_line1': return 'مرحبًا بك';
			case 'login.headline_line2_prefix': return 'في ';
			case 'login.headline_brand': return 'وايو أدز';
			case 'login.subtitle': return 'سجّل الدخول بحساب Wayo ID لإدارة حملاتك وتعاوناتك.';
			case 'login.cta': return 'تسجيل الدخول إلى وايو أدز';
			case 'login.secure_note': return 'مصادقة آمنة عبر Wayo ID';
			case 'login.terms_prefix': return 'بالمتابعة، فإنك توافق على ';
			case 'login.terms': return 'شروط الاستخدام';
			case 'login.and': return ' و';
			case 'login.privacy': return 'سياسة الخصوصية';
			case 'login.dot': return '.';
			case 'login.email_label': return 'البريد الإلكتروني';
			case 'login.password_label': return 'كلمة المرور';
			case 'login.show_password': return 'إظهار';
			case 'login.hide_password': return 'إخفاء';
			case 'login.email_required': return 'البريد مطلوب';
			case 'login.email_invalid': return 'بريد غير صالح';
			case 'login.password_required': return 'كلمة المرور مطلوبة';
			case 'login.password_min': return '6 أحرف على الأقل';
			case 'login.rate_limit_title': return 'يرجى الانتظار';
			case 'login.rate_limit_body': return 'محاولات تسجيل دخول كثيرة جدًا.';
			case 'login.rate_limit_remaining': return ({required Object seconds}) => 'أعد المحاولة خلال ${seconds} ث';
			case 'login.forgot_password_link': return 'نسيت كلمة المرور؟';
			case 'login.google_cta': return 'المتابعة عبر Google';
			case 'login.apple_cta': return 'تسجيل الدخول عبر Apple';
			case 'login.apple_unavailable': return 'تسجيل الدخول عبر Apple غير متاح على هذا الجهاز.';
			case 'login.apple_failed': return 'فشل تسجيل الدخول عبر Apple. حاول مرة أخرى.';
			case 'login.apple_server_not_configured': return 'تسجيل الدخول عبر Apple غير مفعّل على خادم Wayo ID بعد. اطلب من المسؤول إعداد Apple على Auth_Wayo (الإنتاج)، ثم أعد المحاولة.';
			case 'login.apple_canceled': return 'تم إلغاء تسجيل الدخول عبر Apple.';
			case 'login.apple_hide_my_email_hint': return 'لاستلام رمز التحقق، اختر مشاركة بريدي الإلكتروني — وليس إخفاء بريدي الإلكتروني عند تسجيل الدخول عبر Apple.';
			case 'login.google_not_configured': return 'لم يُضبط تسجيل الدخول عبر Google. أضف AUTH_GOOGLE_SERVER_CLIENT_ID في dart_defines.json (معرّف عميل الويب من Google ينتهي بـ .apps.googleusercontent.com) ثم أعد تشغيل التطبيق بالكامل.';
			case 'login.google_wrong_client_id': return 'يجب أن يكون AUTH_GOOGLE_SERVER_CLIENT_ID هو معرّف عميل الويب في Google Cloud (…apps.googleusercontent.com) وليس UUID عميل OAuth في Passport.';
			case 'login.google_failed': return 'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.';
			case 'login.google_channel_restart': return 'انقطع اتصال Google مع أندرويد (غالبًا بعد hot restart). أوقف التطبيق بالكامل ثم شغّله من جديد — لا تستخدم hot restart.';
			case 'login.google_android_oauth_misconfigured': return 'تعذّر على Google التحقق من التطبيق (رمز 10). في Google Cloud Console ونفس مشروع معرّف العميل للويب: أنشئ عميل OAuth من نوع Android باسم الحزمة ma.wayo.wayoadsgo وبصمة SHA-1 لبيانات الاعتماد (تطوير أو إصدار)، انتظر بضع دقائق ثم أعِد المحاولة.';
			case 'login.session_expired_snack': return 'انتهت جلستك. يُرجى تسجيل الدخول مرة أخرى.';
			case 'login.web_session_title': return 'الحساب نشط بالفعل';
			case 'login.web_session_body': return 'هذا الحساب نشط على جهاز آخر. هل تريد قطع اتصال الجهاز الآخر وتسجيل الدخول من هنا؟';
			case 'login.web_session_disconnect': return 'قطع اتصال الجهاز الآخر';
			case 'login.web_session_disconnecting': return 'جارٍ قطع الاتصال…';
			case 'login.web_session_cancel': return 'إلغاء';
			case 'signup.role_title': return 'إنشاء حساب Wayo Ads';
			case 'signup.role_subtitle': return 'اختر كيف ستستخدم Wayo Ads — نفس الخطوة على الموقع.';
			case 'signup.create_account': return 'إنشاء حساب';
			case 'signup.create_account_link': return 'إنشاء حساب';
			case 'signup.no_account_yet': return 'ليس لديك حساب؟';
			case 'signup.register_subtitle': return ({required Object role}) => 'سجّل كـ ${role} بالبريد أو تابع مع Google أو Apple.';
			case 'signup.name_label': return 'الاسم الكامل';
			case 'signup.name_required': return 'الاسم مطلوب';
			case 'signup.confirm_password_label': return 'تأكيد كلمة المرور';
			case 'signup.password_need_symbol': return 'مطلوب رمز (!@#%…)';
			case 'signup.register_cta': return 'إنشاء حساب';
			case 'signup.google_cta': return 'إنشاء حساب عبر Google';
			case 'signup.apple_cta': return 'إنشاء حساب عبر Apple';
			case 'signup.already_have_account': return 'لديك حساب بالفعل؟';
			case 'signup.sign_in_link': return 'تسجيل الدخول';
			case 'signup.verify_then_sign_in': return 'تم تأكيد البريد. سجّل الدخول بكلمة المرور.';
			case 'signup.name_taken': return 'هذا الاسم مستخدم بالفعل. يرجى اختيار اسم آخر.';
			case 'signup.email_taken': return 'هذا البريد الإلكتروني مسجّل بالفعل. سجّل الدخول بدلاً من ذلك.';
			case 'signup.disposable_email': return 'عناوين البريد الإلكتروني المؤقتة غير مسموح بها.';
			case 'signup.name_check_failed': return 'تعذّر التحقق من هذا الاسم الآن. يرجى المحاولة مرة أخرى.';
			case 'signup.email_check_failed': return 'تعذّر التحقق من هذا البريد الإلكتروني الآن. يرجى المحاولة مرة أخرى.';
			case 'signup.legal_prefix': return 'لقد قرأت وأوافق على ';
			case 'signup.terms_of_service': return 'شروط الخدمة';
			case 'signup.privacy_policy': return 'سياسة الخصوصية';
			case 'signup.cookie_policy': return 'سياسة ملفات تعريف الارتباط';
			case 'signup.legal_comma': return ' و';
			case 'signup.legal_and': return ' و';
			case 'signup.legal_dot': return '.';
			case 'signup.legal_required': return 'يرجى قبول الشروط لإنشاء حسابك.';
			case 'signup.back_cta': return 'رجوع';
			case 'verify_email.title': return 'أكّد بريدك الإلكتروني';
			case 'verify_email.subtitle': return 'يتطلب Wayo ID عنوانًا مُؤكدًا (كما على الموقع). افتح الرابط الذي أرسلناه إلى:';
			case 'verify_email.check_again': return 'تم التأكيد — متابعة';
			case 'verify_email.open_mail': return 'فتح تطبيق البريد';
			case 'verify_email.still_pending': return 'ما زالت التحقق قيد الانتظار. راجع الوارد أو الرسائل غير المرغوبة ثم أعد المحاولة.';
			case 'verify_email.open_mail_failed': return 'تعذّر فتح تطبيق البريد.';
			case 'verify_email.sign_out': return 'تسجيل الخروج';
			case 'verify.title': return 'تحقق من بريدك الإلكتروني';
			case 'verify.subtitle': return 'أرسلنا رمزًا من 6 أرقام إلى بريدك. أدخله أدناه للتحقق من حسابك.';
			case 'verify.code_label': return 'رمز التحقق';
			case 'verify.verify_btn': return 'تحقق';
			case 'verify.code_sent': return 'تم إرسال رمز التحقق إلى بريدك الإلكتروني.';
			case 'verify.or_label': return 'أو';
			case 'verify.resend': return 'إعادة إرسال الرمز';
			case 'verify.resend_in': return ({required Object seconds}) => 'إعادة إرسال الرمز (${seconds} ث)';
			case 'verify.spam': return 'لم تستلم الرمز؟ تحقق من مجلد البريد المزعج أو أعد الإرسال.';
			case 'verify.different_account': return 'تسجيل الدخول بحساب مختلف';
			case 'forgot_password.title': return 'إعادة تعيين\nكلمة المرور';
			case 'forgot_password.subtitle': return 'أدخل بريدك الإلكتروني على وايو. سنرسل لك رمزًا من 6 أرقام.';
			case 'forgot_password.email_label': return 'البريد الإلكتروني';
			case 'forgot_password.cta': return 'إرسال الرمز';
			case 'forgot_password.rate_limit_title': return 'يرجى الانتظار';
			case 'forgot_password.rate_limit_body': return 'طلبات إعادة تعيين كثيرة. أعد المحاولة بعد لحظات.';
			case 'forgot_password.rate_limit_remaining': return ({required Object seconds}) => 'أعد المحاولة خلال ${seconds} ث';
			case 'otp.title': return 'تأكيد\nالبريد';
			case 'otp.subtitle': return ({required Object email}) => 'أدخل الرمز المرسل إلى ${email}';
			case 'otp.resend': return 'إعادة إرسال الرمز';
			case 'otp.resend_in': return ({required Object seconds}) => 'إعادة الإرسال خلال ${seconds} ث';
			case 'reset_password.title': return 'كلمة مرور\nجديدة';
			case 'reset_password.subtitle': return 'اختر كلمة مرور قوية (8 أحرف على الأقل، حرف كبير، رقم).';
			case 'reset_password.new_password': return 'كلمة المرور الجديدة';
			case 'reset_password.confirm_password': return 'تأكيد كلمة المرور';
			case 'reset_password.cta': return 'تحديث كلمة المرور';
			case 'reset_password.password_updated': return 'تم تحديث كلمة المرور. يمكنك تسجيل الدخول الآن.';
			case 'validation.required': return 'مطلوب';
			case 'validation.invalid_email': return 'بريد غير صالح';
			case 'validation.min8': return '8 أحرف على الأقل';
			case 'validation.need_upper': return 'يلزم حرف كبير واحد على الأقل';
			case 'validation.need_digit': return 'يلزم رقم واحد على الأقل';
			case 'validation.mismatch': return 'كلمتا المرور غير متطابقتين';
			case 'password_req.hint': return 'يجب أن تحتوي كلمة المرور على:';
			case 'password_req.length': return '8 أحرف على الأقل';
			case 'password_req.uppercase': return 'حرف كبير واحد على الأقل (A–Z)';
			case 'password_req.lowercase': return 'حرف صغير واحد على الأقل (a–z)';
			case 'password_req.number': return 'رقم واحد على الأقل (0–9)';
			case 'password_req.symbol': return 'رمز واحد على الأقل (!@#%…)';
			case 'password_req.very_weak': return 'ضعيف جدًا';
			case 'password_req.weak': return 'ضعيف';
			case 'password_req.fair': return 'مقبول';
			case 'password_req.good': return 'جيد';
			case 'password_req.strong': return 'قوي';
			case 'home.title': return 'وايو أدز';
			case 'home.logout': return 'تسجيل الخروج';
			case 'home.session_title': return 'جلسة نشطة';
			case 'home.session_hint': return 'رمز Auth_Wayo مخزّن بأمان. طلبات API تستخدم Authorization: Bearer تلقائيًا.';
			case 'home.user_fallback': return 'مستخدم';
			case 'dashboard.title': return 'لوحة التحكم';
			case 'dashboard.welcome': return 'مرحبًا بعودتك، {name}!';
			case 'dashboard.welcome_fallback': return 'مرحبًا بعودتك!';
			case 'dashboard.subtitle': return 'إليك نظرة عامة على حملاتك الحالية.';
			case 'dashboard.account_creator': return 'حساب مبدع';
			case 'dashboard.account_advertiser': return 'حساب معلن';
			case 'dashboard.coming_soon': return 'قريبًا.';
			case 'dashboard.balance.title': return 'نظرة على الرصيد';
			case 'dashboard.balance.available': return 'متاح';
			case 'dashboard.balance.locked': return 'محجوز';
			case 'dashboard.balance.spent': return 'منفق';
			case 'dashboard.campaigns.title': return 'حملاتك';
			case 'dashboard.campaigns.subtitle': return 'أدر حملاتك وتابع أداءها.';
			case 'dashboard.campaigns.creators': return '{count} مبدعين';
			case 'dashboard.campaigns.empty_title': return 'لا حملات بعد';
			case 'dashboard.campaigns.empty_subtitle': return 'أنشئ حملتك الأولى للبدء';
			case 'dashboard.campaigns.create_cta': return 'إنشاء حملة';
			case 'dashboard.campaigns.pagination_previous': return 'السابق';
			case 'dashboard.campaigns.pagination_next': return 'التالي';
			case 'dashboard.campaigns.pagination_page': return ({required Object current, required Object total}) => 'الصفحة ${current} / ${total}';
			case 'dashboard.errors.load_balance': return 'تعذر تحميل الرصيد';
			case 'dashboard.errors.load_campaigns': return 'تعذر تحميل الحملات';
			case 'dashboard.errors.retry': return 'إعادة المحاولة';
			case 'dashboard.notifications_title': return 'الإشعارات';
			case 'dashboard.notifications_empty': return 'لا إشعارات';
			case 'dashboard.notification_incoming': return 'إشعار جديد';
			case 'dashboard.notification_view': return 'عرض';
			case 'dashboard.notifications_mark_all_read': return 'تعليم الكل كمقروء';
			case 'dashboard.notifications_mark_read': return 'تعليم كمقروء';
			case 'dashboard.notifications_dismiss': return 'تجاهل';
			case 'dashboard.notifications_view_all': return 'عرض كل الإشعارات';
			case 'dashboard.notifications_important': return 'مهم';
			case 'dashboard.notifications_earlier': return 'سابقًا';
			case 'dashboard.notifications_caught_up_title': return 'لا جديد!';
			case 'dashboard.notifications_caught_up_subtitle': return 'لا إشعارات جديدة';
			case 'dashboard.notifications_center_title': return 'مركز الإشعارات';
			case 'dashboard.notifications_unread_count': return '{count} إشعارات غير مقروءة';
			case 'dashboard.notifications_all_caught_up': return 'لا إشعارات جديدة';
			case 'dashboard.notifications_tab_all': return 'الكل';
			case 'dashboard.notifications_tab_archived': return 'الأرشيف';
			case 'dashboard.notifications_search_hint': return 'بحث في الإشعارات…';
			case 'dashboard.notifications_filter_type_all': return 'كل الأنواع';
			case 'dashboard.notifications_filter_priority_all': return 'كل الأولويات';
			case 'dashboard.notifications_priority_critical': return 'حرج';
			case 'dashboard.notifications_priority_high': return 'عالي';
			case 'dashboard.notifications_priority_normal': return 'عادي';
			case 'dashboard.notifications_priority_low': return 'منخفض';
			case 'dashboard.notifications_load_more': return 'تحميل المزيد';
			case 'dashboard.notifications_view_details': return 'عرض التفاصيل';
			case 'dashboard.notifications_archive': return 'أرشفة';
			case 'dashboard.notifications_urgent': return 'عاجل';
			case 'dashboard.notifications_just_now': return 'الآن';
			case 'dashboard.notifications_minutes_ago': return 'منذ {n} د';
			case 'dashboard.notifications_hours_ago': return 'منذ {n} س';
			case 'dashboard.notifications_days_ago': return 'منذ {n} ي';
			case 'dashboard.notifications_section_all': return 'كل الإشعارات';
			case 'dashboard.notifications_section_important': return 'تنبيهات مهمة';
			case 'dashboard.notifications_section_archived': return 'إشعارات مؤرشفة';
			case 'dashboard.application_approve': return 'قبول';
			case 'dashboard.application_reject': return 'رفض';
			case 'dashboard.application_approved': return 'تم قبول الطلب';
			case 'dashboard.application_rejected': return 'تم رفض الطلب';
			case 'dashboard.application_action_failed': return 'تعذّر تحديث الطلب. أعد المحاولة.';
			case 'dashboard.theme_toggle_tooltip': return 'التبديل بين الوضع الفاتح والداكن';
			case 'dashboard.refresh': return 'تحديث لوحة التحكم';
			case 'dashboard.shell_tour_restart': return 'إعادة جولة التعريف';
			case 'dashboard.shell_tour_restart_hint': return 'إعادة عرض الجولة التعريفية للتنقل بين لوحة التحكم والحملات والمحفظة والمحادثة';
			case 'advertiser_campaigns.title': return 'الحملات';
			case 'advertiser_campaigns.subtitle': return 'أنشئ حملات كمسودات، تابع الأداء وراجع طلبات المنشئين.';
			case 'advertiser_campaigns.view_mine': return 'حملاتي';
			case 'advertiser_campaigns.view_browse': return 'استكشاف';
			case 'advertiser_campaigns.browse.title': return 'استكشاف الحملات';
			case 'advertiser_campaigns.browse.subtitle': return 'تصفّح الحملات النشطة في السوق — للمقارنة والإلهام من العلامات الأخرى.';
			case 'advertiser_campaigns.browse.search_placeholder': return 'البحث عن حملة';
			case 'advertiser_campaigns.browse.empty_title': return 'لا توجد حملات نشطة';
			case 'advertiser_campaigns.browse.empty_subtitle': return 'تظهر الحملات الجديدة هنا عند إطلاقها.';
			case 'advertiser_campaigns.browse.empty_search_title': return 'لا توجد حملات مطابقة';
			case 'advertiser_campaigns.browse.empty_search_subtitle': return 'جرّب كلمة أخرى أو أعد ضبط الفلاتر.';
			case 'advertiser_campaigns.tabs.active': return 'نشطة';
			case 'advertiser_campaigns.tabs.draft': return 'مسودات';
			case 'advertiser_campaigns.tabs.paused': return 'معلّقة';
			case 'advertiser_campaigns.tabs.under_review': return 'قيد المراجعة';
			case 'advertiser_campaigns.tabs.completed': return 'مكتملة';
			case 'advertiser_campaigns.tabs.cancelled': return 'ملغاة';
			case 'advertiser_campaigns.search_placeholder': return 'ابحث عن حملة';
			case 'advertiser_campaigns.empty.none': return 'لا توجد حملات';
			case 'advertiser_campaigns.empty.hint': return 'لا توجد لديك حملات بهذه الحالة بعد.';
			case 'advertiser_campaigns.empty.search': return 'لا نتائج مطابقة للبحث';
			case 'advertiser_campaigns.empty.search_hint': return 'جرّب اسماً مختلفاً أو امسح البحث.';
			case 'advertiser_campaigns.card.budget_total': return 'الميزانية';
			case 'advertiser_campaigns.card.remaining': return 'المتبقي';
			case 'advertiser_campaigns.card.locked': return 'محجوز';
			case 'advertiser_campaigns.card.spent': return 'المنفق';
			case 'advertiser_campaigns.card.cpc': return 'CPC';
			case 'advertiser_campaigns.card.cpm': return 'CPM';
			case 'advertiser_campaigns.card.badge_new': return 'جديد';
			case 'advertiser_campaigns.card.valid_engagements': return '{count} مشاهدة مُصدّقة';
			case 'advertiser_campaigns.card.list_row_views': return '{count} مشاهدة';
			case 'advertiser_campaigns.card.list_row_clicks': return '{count} نقرات';
			case 'advertiser_campaigns.card.list_row_creators': return '{count} منشئين';
			case 'advertiser_campaigns.status.active': return 'نشطة';
			case 'advertiser_campaigns.status.paused': return 'معلّقة';
			case 'advertiser_campaigns.status.under_review': return 'قيد المراجعة';
			case 'advertiser_campaigns.status.completed': return 'مكتملة';
			case 'advertiser_campaigns.status.cancelled': return 'ملغاة';
			case 'advertiser_campaigns.status.draft': return 'مسودة';
			case 'advertiser_campaigns.status.other': return 'أخرى';
			case 'advertiser_campaigns.platform.youtube': return 'YouTube';
			case 'advertiser_campaigns.platform.tiktok': return 'TikTok';
			case 'advertiser_campaigns.platform.instagram': return 'Instagram';
			case 'advertiser_campaigns.platform.other': return 'منصة';
			case 'advertiser_campaigns.detail.fallback_title': return 'حملة';
			case 'advertiser_campaigns.detail.metrics_title': return 'الأداء';
			case 'advertiser_campaigns.detail.budget_usage_title': return 'استخدام الميزانية';
			case 'advertiser_campaigns.detail.budget_usage_spent': return 'المصروف';
			case 'advertiser_campaigns.detail.budget_usage_remaining': return 'المتبقّي';
			case 'advertiser_campaigns.detail.valid_views': return 'مشاهدات مُصدّقة';
			case 'advertiser_campaigns.detail.valid_clicks': return 'نقرات صالحة';
			case 'advertiser_campaigns.detail.approved_creators': return 'منشئون معتمدون';
			case 'advertiser_campaigns.detail.platform_label': return 'المنصة';
			case 'advertiser_campaigns.detail.campaign_type_label': return 'نوع الحملة';
			case 'advertiser_campaigns.detail.niche_label': return 'المجال';
			case 'advertiser_campaigns.detail.location_label': return 'الموقع';
			case 'advertiser_campaigns.detail.objective_label': return 'الهدف';
			case 'advertiser_campaigns.detail.objective_awareness': return 'الوعي بالعلامة';
			case 'advertiser_campaigns.detail.objective_traffic': return 'الزيارات';
			case 'advertiser_campaigns.detail.objective_conversion': return 'التحويل';
			case 'advertiser_campaigns.detail.cpm_metric': return 'CPM (لكل 1000 مشاهدة)';
			case 'advertiser_campaigns.detail.cpm_consumed': return 'CPM المستهلك (لكل 1000 مشاهدة)';
			case 'advertiser_campaigns.detail.cpc_metric': return 'CPC (لكل نقرة)';
			case 'advertiser_campaigns.detail.description_title': return 'الوصف';
			case 'advertiser_campaigns.detail.show_more': return 'عرض المزيد';
			case 'advertiser_campaigns.detail.show_less': return 'عرض أقل';
			case 'advertiser_campaigns.detail.top_creators_title': return 'أفضل المنشئين';
			case 'advertiser_campaigns.detail.top_creators_subtitle': return 'أفضل المنشئين لديك، مرتبين حسب المشاهدات المعتمدة.';
			case 'advertiser_campaigns.detail.top_creators_views': return ({required Object count}) => '${count} مشاهدة معتمدة';
			case 'advertiser_campaigns.detail.top_creators_earned': return 'ربح';
			case 'advertiser_campaigns.detail.top_creators_empty_title': return 'لا توجد نتائج بعد';
			case 'advertiser_campaigns.detail.top_creators_empty_subtitle': return 'ستظهر إحصائيات المنشئين هنا بمجرد أن يبدأ المنشئون المعتمدون في تحقيق المشاهدات.';
			case 'advertiser_campaigns.create.title': return 'حملة جديدة';
			case 'advertiser_campaigns.create.section_basics': return 'المعلومات الأساسية';
			case 'advertiser_campaigns.create.section_budget': return 'الميزانية والتسعير';
			case 'advertiser_campaigns.create.field_type': return 'نوع الحملة';
			case 'advertiser_campaigns.create.field_objective': return 'هدف الحملة';
			case 'advertiser_campaigns.create.field_niche': return 'المجال / القطاع';
			case 'advertiser_campaigns.create.field_title': return 'العنوان';
			case 'advertiser_campaigns.create.field_description': return 'الوصف (اختياري)';
			case 'advertiser_campaigns.create.field_landing': return 'رابط الصفحة المستهدفة';
			case 'advertiser_campaigns.create.field_assets': return 'رابط الموجز / الأصول';
			case 'advertiser_campaigns.create.field_budget': return 'الميزانية الإجمالية';
			case 'advertiser_campaigns.create.field_cpm_hint': return 'CPM — التكلفة لكل 1000 ظهور (بالسنت)';
			case 'advertiser_campaigns.create.field_cpc_hint': return 'CPC — التكلفة لكل نقرة (بالسنت)';
			case 'advertiser_campaigns.create.field_video_min_duration': return 'الحد الأدنى لطول الفيديو (بالدقائق)';
			case 'advertiser_campaigns.create.field_shorts_max_duration': return 'الحد الأقصى لطول القصير (بالثواني)';
			case 'advertiser_campaigns.create.type_link': return 'رابط';
			case 'advertiser_campaigns.create.type_video': return 'فيديو';
			case 'advertiser_campaigns.create.type_shorts': return 'قصير';
			case 'advertiser_campaigns.create.landing_help': return 'مطلوب لحملات الرابط (https).';
			case 'advertiser_campaigns.create.assets_help': return 'الفيديو والقصير يتطلبان رابطًا https لـ Drive أو OneDrive أو SharePoint.';
			case 'advertiser_campaigns.create.submit_draft': return 'حفظ كمسودة';
			case 'advertiser_campaigns.create.validation_title': return 'راجع الحقول.';
			case 'advertiser_campaigns.create.assets_url_invalid': return 'استخدم عنوان https لـ Google Drive أو OneDrive أو SharePoint.';
			case 'advertiser_campaigns.create.success': return 'تم إنشاء الحملة (مسودة)';
			case 'advertiser_campaigns.create.submit_in_progress': return 'جارٍ الحفظ…';
			case 'advertiser_campaigns.applications.title': return 'طلبات المنشئين';
			case 'advertiser_campaigns.applications.pending_badge': return ({required Object count}) => '${count} في الانتظار';
			case 'advertiser_campaigns.applications.subtitle': return 'راجع واعتمد أو ارفض طلبات المنشئين';
			case 'advertiser_campaigns.applications.empty_title': return 'لا توجد طلبات';
			case 'advertiser_campaigns.applications.empty_subtitle': return 'عندما يقدم المنشئون طلباتهم ستظهر هنا.';
			case 'advertiser_campaigns.applications.load_error': return 'تعذّر تحميل الطلبات';
			case 'advertiser_campaigns.applications.trust_score': return ({required Object score}) => 'الثقة: ${score}';
			case 'advertiser_campaigns.applications.approve_button': return 'اعتماد';
			case 'advertiser_campaigns.applications.reject_button': return 'رفض';
			case 'advertiser_campaigns.applications.approved_status': return 'معتمد';
			case 'advertiser_campaigns.applications.rejected_status': return 'مرفوض';
			case 'advertiser_campaigns.actions.publish': return 'نشر';
			case 'advertiser_campaigns.actions.pause': return 'إيقاف مؤقت';
			case 'advertiser_campaigns.actions.resume': return 'استئناف';
			case 'advertiser_campaigns.actions.cancel': return 'إلغاء الحملة';
			case 'advertiser_campaigns.actions.edit': return 'تعديل';
			case 'advertiser_campaigns.actions.more': return 'المزيد';
			case 'advertiser_campaigns.actions.analytics': return 'التحليلات';
			case 'advertiser_campaigns.actions.financial': return 'الصحة المالية';
			case 'advertiser_campaigns.actions.financial_health': return 'الصحة المالية';
			case 'advertiser_campaigns.actions.status_updated': return 'تم تحديث حالة الحملة';
			case 'advertiser_campaigns.actions.status_error': return 'تعذّر تحديث حالة الحملة';
			case 'advertiser_campaigns.actions.cancel_confirm_title': return 'إلغاء هذه الحملة؟';
			case 'advertiser_campaigns.actions.cancel_confirm_body': return 'ستُعاد الميزانية المحجوزة المتبقية إلى محفظتك.';
			case 'advertiser_campaigns.actions.dismiss': return 'الإبقاء على الحملة';
			case 'advertiser_campaigns.actions.confirm': return 'إلغاء الحملة';
			case 'advertiser_video_reviews.title': return 'مراجعة الفيديوهات';
			case 'advertiser_video_reviews.subtitle': return 'اعتمد أو ارفض فيديوهات المنشئين المقدّمة لحملاتك.';
			case 'advertiser_video_reviews.pending': return 'قيد الانتظار';
			case 'advertiser_video_reviews.approved': return 'معتمدة';
			case 'advertiser_video_reviews.rejected': return 'مرفوضة';
			case 'advertiser_video_reviews.flagged': return 'مُبلّغ عنها';
			case 'advertiser_video_reviews.empty': return 'لا توجد فيديوهات في هذه الفئة.';
			case 'advertiser_video_reviews.load_error': return 'تعذّر تحميل الفيديوهات المقدّمة';
			case 'advertiser_video_reviews.approve_button': return 'اعتماد';
			case 'advertiser_video_reviews.reject_button': return 'رفض';
			case 'advertiser_video_reviews.approve_success': return 'تم اعتماد الفيديو';
			case 'advertiser_video_reviews.reject_success': return 'تم رفض الفيديو';
			case 'advertiser_video_reviews.reject_reason_required': return 'يرجى إدخال سبب الرفض';
			case 'advertiser_video_reviews.reject_reason_hint': return 'سبب الرفض';
			case 'advertiser_video_reviews.reject_dialog_title': return 'رفض الفيديو';
			case 'advertiser_video_reviews.action_failed': return 'تعذّر تحديث الفيديو. حاول مرة أخرى.';
			case 'advertiser_video_reviews.submitted_at': return 'تاريخ التقديم';
			case 'advertiser_video_reviews.shorts_badge': return 'Short';
			case 'advertiser_video_reviews.flag_reason': return 'سبب الإبلاغ';
			case 'advertiser_video_reviews.rejection_reason': return 'سبب الرفض';
			case 'advertiser_video_reviews.status_pending': return 'قيد الانتظار';
			case 'advertiser_video_reviews.status_approved': return 'معتمدة';
			case 'advertiser_video_reviews.status_rejected': return 'مرفوضة';
			case 'advertiser_video_reviews.status_flagged': return 'مُبلّغ عنها';
			case 'nav.dashboard': return 'لوحة التحكم';
			case 'nav.campaigns': return 'الحملات';
			case 'nav.analytics': return 'التحليلات';
			case 'nav.wallet': return 'المحفظة';
			case 'nav.chat': return 'المحادثات';
			case 'nav.invoices': return 'الفواتير';
			case 'nav.invoices_creator': return 'الإيصالات';
			case 'invoices.title': return 'الفواتير';
			case 'invoices.title_creator': return 'إيصالات الدفع';
			case 'invoices.subtitle_advertiser': return 'كل إيداع وكل ميزانية حملة — في مكان واحد.';
			case 'invoices.subtitle_creator': return 'كل أرباحك وتحويلاتك — موقعة، محمية، قابلة للتنزيل.';
			case 'invoices.summary_total_paid': return 'إجمالي المدفوع';
			case 'invoices.summary_pending': return 'قيد الانتظار';
			case 'invoices.summary_count': return 'المستندات';
			case 'invoices.filter_all': return 'الكل';
			case 'invoices.filter_all_types': return 'كل الأنواع';
			case 'invoices.filter_deposits': return 'الإيداعات';
			case 'invoices.filter_billing': return 'ميزانية الحملة';
			case 'invoices.filter_payouts': return 'التحويلات';
			case 'invoices.filter_earnings': return 'الأرباح';
			case 'invoices.filter_withdrawal': return 'السحب';
			case 'invoices.filter_token_purchase': return 'شراء الرموز';
			case 'invoices.type_deposit': return 'إيداع المحفظة';
			case 'invoices.type_billing': return 'ميزانية الحملة';
			case 'invoices.type_payout': return 'تحويل المنشئ';
			case 'invoices.type_earnings': return 'أرباح الإعلانات';
			case 'invoices.type_token_purchase': return 'شراء الرموز';
			case 'invoices.type_unknown': return 'أخرى';
			case 'invoices.status_paid': return 'مدفوعة';
			case 'invoices.status_validated': return 'معتمدة';
			case 'invoices.status_pending': return 'قيد الانتظار';
			case 'invoices.status_cancelled': return 'ملغاة';
			case 'invoices.role_advertiser': return 'المعلن';
			case 'invoices.role_creator': return 'المنشئ';
			case 'invoices.search_hint': return 'ابحث برقم الفاتورة أو المرجع…';
			case 'invoices.empty_title': return 'لا توجد فواتير بعد';
			case 'invoices.empty_subtitle': return 'ستظهر هنا الإيداعات وميزانيات الحملات والتحويلات تلقائياً — دون أي خطوة يدوية.';
			case 'invoices.empty_subtitle_creator': return 'ستظهر أرباحك ومستندات التحويل هنا فور إصدارها — نفس ملفات PDF المعتمدة كما في الويب.';
			case 'invoices.empty_cta': return 'تحديث';
			case 'invoices.error_title': return 'تعذّر تحميل الفواتير';
			case 'invoices.error_subtitle': return 'اسحب للتحديث — سنحاول من جديد فوراً.';
			case 'invoices.load_more': return 'تحميل المزيد';
			case 'invoices.pagination_meta': return 'الصفحة {current} من {total}';
			case 'invoices.pagination_previous': return 'السابق';
			case 'invoices.pagination_next': return 'التالي';
			case 'invoices.date_preset_all': return 'كل التواريخ';
			case 'invoices.date_preset_30d': return '30 يومًا';
			case 'invoices.date_preset_90d': return '90 يومًا';
			case 'invoices.date_preset_custom': return 'مخصص';
			case 'invoices.details_title': return 'فاتورة {number}';
			case 'invoices.details_section_summary': return 'الملخص';
			case 'invoices.details_section_actions': return 'الإجراءات';
			case 'invoices.details_section_legal': return 'القانوني والمراجع';
			case 'invoices.details_invoice_number': return 'رقم الفاتورة';
			case 'invoices.details_issued_at': return 'صادرة في';
			case 'invoices.details_paid_at': return 'مدفوعة في';
			case 'invoices.details_type': return 'النوع';
			case 'invoices.details_status': return 'الحالة';
			case 'invoices.details_role': return 'الدور';
			case 'invoices.details_reference': return 'المرجع';
			case 'invoices.details_amount': return 'الإجمالي';
			case 'invoices.details_tax': return 'شامل ضريبة القيمة المضافة';
			case 'invoices.details_currency': return 'العملة';
			case 'invoices.action_download_pdf': return 'تنزيل PDF';
			case 'invoices.action_share_pdf': return 'مشاركة';
			case 'invoices.action_open_pdf': return 'فتح';
			case 'invoices.action_copy_number': return 'نسخ الرقم';
			case 'invoices.action_view_details': return 'عرض التفاصيل';
			case 'invoices.download_progress': return 'تحضير PDF…';
			case 'invoices.download_success': return 'تم الحفظ باسم {filename}';
			case 'invoices.download_error': return 'فشل التنزيل. حاول مرة أخرى.';
			case 'invoices.copied_to_clipboard': return 'تم نسخ رقم الفاتورة.';
			case 'invoices.share_subject': return 'فاتورة {number}';
			case 'invoices.polling_live': return 'مباشر';
			case 'invoices.polling_paused': return 'إيقاف';
			case 'invoices.summary_this_month': return 'هذا الشهر';
			case 'invoices.pagination_detail': return 'صفحة {current} من {total} · {count} فواتير';
			case 'invoices.sort_sheet_title': return 'الترتيب';
			case 'invoices.sort_date_newest': return 'الأحدث أولاً';
			case 'invoices.sort_date_oldest': return 'الأقدم أولاً';
			case 'invoices.sort_amount_high': return 'المبلغ · من الأعلى';
			case 'invoices.sort_amount_low': return 'المبلغ · من الأدنى';
			case 'invoices.sort_status_az': return 'الحالة · أ-ي';
			case 'invoices.sort_status_za': return 'الحالة · ي-أ';
			case 'invoices.date_range_title': return 'التواريخ';
			case 'invoices.date_from': return 'من';
			case 'invoices.date_to': return 'إلى';
			case 'invoices.clear_dates': return 'مسح';
			case 'invoices.date_apply': return 'تطبيق';
			case 'invoices.download_all_zip': return 'ZIP';
			case 'invoices.zip_progress': return 'جاري إنشاء ZIP…';
			case 'invoices.zip_success': return 'تم الحفظ: {filename}';
			case 'invoices.zip_error': return 'فشل تنزيل ZIP.';
			case 'push.onboarding_title': return 'ابقَ على اطلاع';
			case 'push.onboarding_subtitle': return 'استقبل تنبيهات فورية لما يهمك — حتى عندما يكون التطبيق في الخلفية.';
			case 'push.onboarding_bullet_campaigns': return 'تحديثات الحملات والطلبات والميزانيات';
			case 'push.onboarding_bullet_messages': return 'رسائل الدردشة الجديدة';
			case 'push.onboarding_bullet_system': return 'الفواتير والمدفوعات وتنبيهات المنصة';
			case 'push.onboarding_enable': return 'تفعيل الإشعارات';
			case 'push.onboarding_later': return 'ليس الآن';
			case 'push.onboarding_success': return 'تم تفعيل الإشعارات';
			case 'push.onboarding_denied_hint': return 'يمكنك تفعيلها لاحقاً من إعدادات الجهاز.';
			case 'push.onboarding_context_chat': return 'وصلتك رسالة جديدة — فعّل التنبيهات حتى لا تفوتك أي رد.';
			case 'push.onboarding_context_campaign': return 'تغيّرت حالة حملة — فعّل الإشعارات لمتابعة الطلبات والميزانيات.';
			case 'push.onboarding_context_invoice': return 'فاتورة أو تحويل جديد — احصل على تنبيه فور تحرك الأموال.';
			case 'creator.dashboard.title': return 'استوديو المبدع';
			case 'creator.dashboard.subtitle': return 'تابع إحصائياتك وطلباتك وأرباحك في الوقت الفعلي.';
			case 'creator.dashboard.coming_soon_title': return 'لوحة تحكّم المبدع';
			case 'creator.dashboard.coming_soon_subtitle': return 'ستظهر هنا الإحصائيات والتحليلات والطلبات النشطة. التحديث الحي مفعَّل — لا حاجة للتحديث اليدوي.';
			case 'creator.wallet.coming_soon_title': return 'أرباحك';
			case 'creator.wallet.coming_soon_subtitle': return 'الرصيد المتاح، المدفوعات المعلّقة وسجل Stripe ستظهر هنا.';
			case 'creator.wallet.connect_stripe_title': return 'ربط Stripe';
			case 'creator.wallet.connect_stripe_subtitle': return 'اربط حسابك المصرفي عبر Stripe لتفعيل السحوبات. لا نحفظ أي بيانات مصرفية.';
			case 'creator.wallet.withdraw_title': return 'طلب سحب';
			case 'creator.wallet.withdraw_subtitle': return 'اسحب رصيدك المتاح إلى حساب Stripe المربوط.';
			case 'creator.wallet.available_balance': return 'المتاح';
			case 'creator.wallet.pending_balance': return 'قيد الانتظار';
			case 'creator.wallet.pending_withdrawals': return 'سحوبات قيد المعالجة';
			case 'creator.wallet.in_transit': return 'قيد التحويل';
			case 'creator.wallet.total_earned': return 'إجمالي الأرباح';
			case 'creator.wallet.lifetime_earnings': return 'الأرباح التراكمية';
			case 'creator.wallet.load_error': return 'تعذّر تحميل محفظتك';
			case 'creator.wallet.withdraw_button': return 'سحب';
			case 'creator.wallet.withdraw_sheet_title': return 'طلب سحب';
			case 'creator.wallet.withdraw_sheet_subtitle': return 'الرصيد المتاح: {available}. ستُحوَّل الأموال إلى حساب Stripe المربوط.';
			case 'creator.wallet.withdraw_amount_label': return 'المبلغ (USD)';
			case 'creator.wallet.withdraw_sheet_body': return 'أدخل المبلغ الذي تريد سحبه. سيتم تحويل الأموال إلى حسابك البنكي المرتبط.';
			case 'creator.wallet.withdraw_quick_amounts': return 'مبالغ سريعة';
			case 'creator.wallet.withdraw_gross_amount': return 'المبلغ الإجمالي';
			case 'creator.wallet.withdraw_platform_fee': return 'رسوم المنصة ({percent}%)';
			case 'creator.wallet.withdraw_tax_vat': return 'ضريبة القيمة المضافة ({percent}%)';
			case 'creator.wallet.withdraw_net_received': return 'صافي المستلم';
			case 'creator.wallet.withdraw_submit': return 'تأكيد السحب';
			case 'creator.wallet.withdraw_submitting': return 'جارٍ المعالجة…';
			case 'creator.wallet.withdraw_max': return 'الحد الأقصى';
			case 'creator.wallet.withdraw_preset_all': return 'الكل';
			case 'creator.wallet.withdraw_success': return 'تم إرسال طلب السحب.';
			case 'creator.wallet.withdraw_secure_footer': return 'سحب آمن — تعالجه Stripe. بياناتك المصرفية لا تصل إلينا أبدًا.';
			case 'creator.wallet.withdraw_error_invalid': return 'أدخل مبلغًا صالحًا.';
			case 'creator.wallet.withdraw_error_min': return 'الحد الأدنى للسحب هو {min}.';
			case 'creator.wallet.withdraw_error_insufficient': return 'الرصيد المتاح غير كافٍ.';
			case 'creator.wallet.withdraw_reason_business_info': return 'أكمل معلومات نشاطك التجاري قبل ربط حساب الدفع.';
			case 'creator.wallet.withdraw_reason_stripe': return 'قم بربط Stripe لتفعيل السحب.';
			case 'creator.wallet.withdraw_reason_stripe_incomplete': return 'أكمل إعداد Stripe لتفعيل السحب.';
			case 'creator.wallet.withdraw_reason_payouts_disabled': return 'حساب Stripe الخاص بك غير مفعَّل للمدفوعات بعد.';
			case 'creator.wallet.withdraw_reason_below_min': return 'الحد الأدنى للسحب هو {min}.';
			case 'creator.wallet.cancel_action': return 'إلغاء الطلب';
			case 'creator.wallet.cancel_in_progress': return 'جارٍ الإلغاء…';
			case 'creator.wallet.cancel_dialog_title': return 'إلغاء هذا السحب؟';
			case 'creator.wallet.cancel_dialog_message': return 'سيتم إلغاء السحب المعلق وإعادة المبلغ إلى رصيدك المتاح.';
			case 'creator.wallet.cancel_dialog_yes': return 'إلغاء السحب';
			case 'creator.wallet.cancel_dialog_no': return 'الاحتفاظ به';
			case 'creator.wallet.cancel_success': return 'تم إلغاء السحب واستعادة المبلغ.';
			case 'creator.wallet.stripe_connected': return 'متصل';
			case 'creator.wallet.stripe_onboarding_required_pill': return 'إجراء مطلوب';
			case 'creator.wallet.stripe_connect_action': return 'ربط Stripe';
			case 'creator.wallet.stripe_complete_action': return 'إكمال الإعداد';
			case 'creator.wallet.stripe_open_dashboard': return 'فتح لوحة Stripe';
			case 'creator.wallet.stripe_error': return 'حدث خطأ مع Stripe. يرجى المحاولة مجددًا.';
			case 'creator.wallet.stripe_edit_business_action': return 'تعديل بيانات النشاط';
			case 'creator.wallet.stripe_card_title_disconnected': return 'ربط Stripe';
			case 'creator.wallet.stripe_card_subtitle_disconnected': return 'اربط حسابك المصرفي عبر Stripe لاستلام المدفوعات.';
			case 'creator.wallet.stripe_card_title_incomplete': return 'أكمل الإعداد';
			case 'creator.wallet.stripe_card_subtitle_incomplete': return 'تحتاج Stripe بعض المعلومات قبل تفعيل المدفوعات.';
			case 'creator.wallet.stripe_card_title_connected': return 'Stripe متصل';
			case 'creator.wallet.stripe_card_subtitle_connected': return 'حساب Stripe Express نشط. المدفوعات تصل إلى بنكك.';
			case 'creator.wallet.history_title': return 'سجل السحوبات';
			case 'creator.wallet.documents_cta': return 'الكشوفات';
			case 'creator.wallet.documents_cta_subtitle': return 'ملفات PDF موقعة للمدفوعات ووثائق الأرباح';
			case 'creator.wallet.history_empty': return 'لا توجد سحوبات بعد — ستظهر هنا.';
			case 'creator.wallet.history_load_error': return 'تعذّر تحميل سجل السحوبات.';
			case 'creator.wallet.history_status_pending': return 'قيد الانتظار';
			case 'creator.wallet.history_status_processing': return 'قيد المعالجة';
			case 'creator.wallet.history_status_succeeded': return 'مدفوع';
			case 'creator.wallet.history_status_failed': return 'فشل';
			case 'creator.wallet.history_status_cancelled': return 'ملغى';
			case 'creator.wallet.conditions_title': return 'شروط السحب';
			case 'creator.wallet.conditions_subtitle': return 'معلومات مفيدة قبل طلب الدفع.';
			case 'creator.wallet.conditions_min_label': return 'الحد الأدنى للسحب';
			case 'creator.wallet.conditions_fee_label': return 'العمولة';
			case 'creator.wallet.conditions_fee_value': return ({required Object percent}) => '${percent} (بدون ضريبة)';
			case 'creator.wallet.conditions_processing_label': return 'مدة المعالجة';
			case 'creator.wallet.conditions_processing_value': return '2 إلى 5 أيام عمل';
			case 'creator.campaigns.browse_title': return 'استكشاف الحملات';
			case 'creator.campaigns.browse_subtitle': return 'ابحث عن الحملات المناسبة لجمهورك وقدّم طلبك بنقرة واحدة.';
			case 'creator.campaigns.browse_search_placeholder': return 'ابحث بالاسم، النوع أو العلامة';
			case 'creator.campaigns.browse_empty_search_title': return 'لا توجد حملات مطابقة';
			case 'creator.campaigns.browse_empty_search_subtitle': return 'جرّب كلمة أخرى — الاسم، النوع (فيديو، شورتس، رابط) أو اسم المعلن.';
			case 'creator.campaigns.applications_title': return 'طلباتي';
			case 'creator.campaigns.applications_subtitle': return 'تابع حالة كل طلب: قُبل، قيد المراجعة، أو مرفوض.';
			case 'creator.campaigns.submit_title': return 'تقديم منشور';
			case 'creator.campaigns.submit_subtitle': return 'بعد الموافقة، شارك رابط فيديو علني ليراجعه المعلن.';
			case 'creator.campaigns.details_title': return 'تفاصيل الحملة';
			case 'creator.campaigns.application_title': return 'طلبي';
			case 'creator.campaigns.not_found_title': return 'الحملة غير متاحة';
			case 'creator.campaigns.not_found_desc': return 'هذه الحملة غير متاحة أو ربما أُزيلت.';
			case 'creator.campaigns.cancelled_not_available': return 'أُلغيت هذه الحملة ولم تعد متاحة.';
			case 'creator.campaigns.completed_not_available': return 'انتهت هذه الحملة ولم تعد متاحة.';
			case 'creator.campaigns.paused_not_available': return 'هذه الحملة معلّقة حالياً وغير متاحة.';
			case 'creator.campaigns.cancelled_owner_banner': return 'أُلغيت هذه الحملة.';
			case 'creator.campaigns.load_error': return 'تعذّر تحميل الحملات.';
			case 'creator.campaigns.empty_title': return 'لا توجد حملات حالياً';
			case 'creator.campaigns.empty_subtitle': return 'ستظهر هنا الحملات الجديدة فور إطلاقها من طرف المعلنين.';
			case 'creator.campaigns.pagination_previous': return 'السابق';
			case 'creator.campaigns.pagination_next': return 'التالي';
			case 'creator.campaigns.pagination_page': return ({required Object current, required Object total}) => 'الصفحة ${current} / ${total}';
			case 'creator.campaigns.description_title': return 'الوصف';
			case 'creator.campaigns.requirements_title': return 'المتطلبات';
			case 'creator.campaigns.assets_title': return 'عناصر العلامة';
			case 'creator.campaigns.assets_subtitle': return 'حمّل ملف الموجز والشعارات واللقطات.';
			case 'creator.campaigns.type_link': return 'رابط';
			case 'creator.campaigns.type_video': return 'فيديو';
			case 'creator.campaigns.type_shorts': return 'Shorts';
			case 'creator.campaigns.reward_cpm_label': return 'الكلفة لكل 1000';
			case 'creator.campaigns.reward_cpc_label': return 'المكافأة لكل نقرة';
			case 'creator.campaigns.reward_per_view_label': return 'المكافأة لكل مشاهدة';
			case 'creator.campaigns.reward_per_view': return ({required Object amount}) => '${amount} / مشاهدة';
			case 'creator.campaigns.reward_per_click': return ({required Object amount}) => '${amount} / نقرة';
			case 'creator.campaigns.budget_remaining_label': return 'الميزانية المتبقية';
			case 'creator.campaigns.earnings_card_title': return 'أرباحي من هذه الحملة';
			case 'creator.campaigns.earnings_card_subtitle': return 'أداؤك وتفاصيل المدفوعات';
			case 'creator.campaigns.earnings_net': return 'صافي الأرباح';
			case 'creator.campaigns.earnings_views': return 'مشاهدات مدفوعة';
			case 'creator.campaigns.earnings_platform_views': return 'مشاهدات المنصة';
			case 'creator.campaigns.earnings_valid_clicks': return 'نقرات مدفوعة';
			case 'creator.campaigns.earnings_recorded_clicks': return 'نقرات مسجّلة';
			case 'creator.campaigns.earnings_available_balance': return 'الرصيد المتاح';
			case 'creator.campaigns.requirement_platform': return ({required Object platform}) => 'انشر على ${platform} فقط';
			case 'creator.campaigns.requirement_min_duration': return ({required Object minutes}) => 'أدنى مدة: ${minutes} دقيقة';
			case 'creator.campaigns.requirement_shorts_max': return ({required Object seconds}) => 'Shorts حتى ${seconds} ثانية';
			case 'creator.campaigns.requirement_vertical': return 'صيغة عمودية (9:16) مطلوبة';
			case 'creator.campaigns.requirement_none': return 'لا توجد متطلبات خاصة.';
			case 'creator.campaigns.apply_cta': return 'قدّم طلبك لهذه الحملة';
			case 'creator.campaigns.apply_title': return 'تقديم طلب';
			case 'creator.campaigns.apply_message_label': return 'عرضك (اختياري)';
			case 'creator.campaigns.apply_message_hint': return 'اشرح للمعلن لماذا أنت المرشح المثالي…';
			case 'creator.campaigns.apply_submit': return 'إرسال الطلب';
			case 'creator.campaigns.apply_in_progress': return 'جارٍ الإرسال…';
			case 'creator.campaigns.apply_error': return 'تعذّر إرسال طلبك. حاول مرة أخرى.';
			case 'creator.campaigns.apply_success': return 'تم إرسال طلبك — ستصلك إشعار بعد المراجعة.';
			case 'creator.campaigns.apply_pending_title': return 'الطلب قيد المراجعة';
			case 'creator.campaigns.apply_pending_subtitle': return 'سنعلمك فور ردّ المعلن.';
			case 'creator.campaigns.open_application_cta': return 'فتح طلبي';
			case 'creator.campaigns.chat_with_advertiser': return 'محادثة المعلن';
			case 'creator.campaigns.status_banner_approved_title': return 'تمت الموافقة عليك!';
			case 'creator.campaigns.status_banner_approved_subtitle': return 'يمكنك الآن تقديم الفيديو ومراسلة المعلن.';
			case 'creator.campaigns.status_banner_pending_title': return 'بانتظار ردّ المعلن';
			case 'creator.campaigns.status_banner_pending_subtitle': return 'عرضك قيد المراجعة — سنخبرك هنا عند اتخاذ القرار.';
			case 'creator.campaigns.status_banner_rejected_title': return 'لم يتم اختيارك هذه المرة';
			case 'creator.campaigns.status_banner_rejected_subtitle': return 'راقب علامة الحملات — كل أسبوع حملات جديدة.';
			case 'creator.campaigns.my_submissions_title': return 'مشاركاتي';
			case 'creator.campaigns.my_submissions_empty_approved': return 'لم ترسل أي فيديو بعد. أرسل واحداً لتبدأ الربح.';
			case 'creator.campaigns.my_submissions_empty_pending': return 'تُفتح خانة الإرسال بعد قبول طلبك.';
			case 'creator.campaigns.submit_cta': return 'تقديم منشور';
			case 'creator.campaigns.submit_platform_label': return 'المنصة';
			case 'creator.campaigns.submit_url_label': return 'رابط الفيديو العلني';
			case 'creator.campaigns.submit_url_hint': return 'https://youtube.com/watch?v=…';
			case 'creator.campaigns.submit_url_required': return 'ألصق رابط الفيديو.';
			case 'creator.campaigns.submit_url_invalid': return 'أدخل رابطاً علنياً صالحاً.';
			case 'creator.campaigns.submit_url_youtube_only': return 'يُدعم حالياً فقط روابط YouTube.';
			case 'creator.campaigns.submit_in_progress': return 'جارٍ الإرسال…';
			case 'creator.campaigns.submit_footer': return 'يجب أن يبقى الفيديو علنياً طوال الحملة للتحقّق من المشاهدات.';
			case 'creator.campaigns.submit_error': return 'تعذّر إرسال الفيديو. حاول مجدداً.';
			case 'creator.campaigns.submit_success': return 'تم إرسال الفيديو — سيراجعه المعلن قريباً.';
			case 'creator.campaigns.submit_blocked_limit': return 'سبق أن أرسلت مشاركة لهذه الحملة. انتظر المراجعة.';
			case 'creator.campaigns.youtube_connect_title': return 'اربط قناة YouTube';
			case 'creator.campaigns.youtube_connect_body': return 'اربط قناتك على Wayo Ads (الويب) قبل إرسال فيديو أو Short. هذا يسمح بالتحقق من الفيديو غير المدرج.';
			case 'creator.campaigns.youtube_reconnect_title': return 'أعد ربط YouTube';
			case 'creator.campaigns.youtube_reconnect_body': return 'انتهت صلاحية ربط YouTube. افتح Wayo Ads على الويب لإعادة الربط ثم أرسل من التطبيق.';
			case 'creator.campaigns.youtube_connect_cta': return 'فتح إعدادات YouTube على الويب';
			case 'creator.campaigns.submission_status_pending': return 'قيد المراجعة';
			case 'creator.campaigns.submission_status_approved': return 'مقبول';
			case 'creator.campaigns.submission_status_rejected': return 'مرفوض';
			case 'creator.campaigns.submission_status_flagged': return 'تم الإبلاغ';
			case 'creator.campaigns.submission_views': return ({required Object views}) => '${views} مشاهدة موثقة';
			case 'creator.campaigns.submission_pending_views': return ({required Object views}) => '+${views} بانتظار التصديق';
			case 'creator.campaigns.submission_platform_views': return ({required Object views}) => '${views} مشاهدة على المنصة';
			case 'creator.campaigns.clicks_validated_label': return 'نقرات معتمدة';
			case 'creator.campaigns.clicks_recorded_label': return 'نقرات مسجّلة';
			case 'creator.campaigns.tracking_link_title': return 'رابط التتبع الخاص بك';
			case 'creator.campaigns.tracking_link_subtitle': return 'شارك هذا الرابط القصير في السيرة أو المنشورات. يتم تتبع النقرات تلقائياً.';
			case 'creator.campaigns.tracking_link_copy': return 'نسخ الرابط';
			case 'creator.campaigns.tracking_link_copied': return 'تم النسخ!';
			case 'creator.campaigns.tracking_link_preparing': return 'يتم إعداد رابطك الفريد… اسحب للتحديث بعد لحظات.';
			case 'creator.campaigns.tracking_link_error': return 'تعذّر تحميل رابط التتبع.';
			case 'creator.campaigns.tracking_link_stats': return ({required Object validated, required Object recorded}) => '${validated} نقرة مؤهلة · ${recorded} نقرة مسجّلة';
			case 'creator.campaigns.tracking_link_destination_title': return 'رابط الصفحة المستهدفة';
			case 'creator.campaigns.tracking_link_open_destination': return 'فتح الوجهة';
			case 'creator.stats.earnings_title': return 'إجمالي الأرباح';
			case 'creator.stats.pending': return 'قيد الانتظار';
			case 'creator.stats.validated_views': return 'المشاهدات المعتمدة';
			case 'creator.stats.pending_validation': return ({required Object count}) => '+${count} بانتظار التصديق';
			case 'creator.stats.pending_validation_tooltip': return 'يتم التحقق من المشاهدات عبر YouTube وسيتم تأكيدها خلال 48 ساعة قبل إضافتها إلى أرباحك.';
			case 'creator.stats.total_valid_clicks': return 'نقرات معتمدة';
			case 'creator.stats.validation_rate': return 'نسبة الاعتماد';
			case 'creator.stats.approved_campaigns': return 'الحملات المقبولة';
			case 'creator.applications.section_title': return 'الطلبات النشطة';
			case 'creator.applications.empty_title': return 'لا توجد طلبات بعد';
			case 'creator.applications.empty_subtitle': return 'استعرض علامة التبويب «الحملات» وقدّم طلبك على ما يناسب جمهورك.';
			case 'creator.applications.load_error': return 'تعذّر تحميل طلباتك';
			case 'creator.applications.status_pending': return 'قيد المراجعة';
			case 'creator.applications.status_approved': return 'مقبولة';
			case 'creator.applications.status_rejected': return 'مرفوضة';
			case 'creator.applications.status_withdrawn': return 'مسحوبة';
			case 'creator.applications.status_unknown': return '—';
			case 'creator.business.cta_title': return 'أكمل معلومات نشاطك التجاري';
			case 'creator.business.cta_subtitle': return 'مطلوب قبل ربط حسابك المصرفي لضمان توجيه المدفوعات بشكل صحيح.';
			case 'creator.business.cta_required_pill': return 'مطلوب';
			case 'creator.business.cta_button': return 'Finalize your Business Information';
			case 'creator.business.dialog_title': return 'معلومات النشاط التجاري';
			case 'creator.business.dialog_subtitle': return 'قدّم بعض المعلومات القانونية حتى يتمكن Stripe من فتح حسابك ومعالجة المدفوعات.';
			case 'creator.business.section_type': return 'نوع النشاط';
			case 'creator.business.section_company': return 'الشركة';
			case 'creator.business.section_address': return 'العنوان';
			case 'creator.business.section_stripe': return 'بلد وعملة الدفع';
			case 'creator.business.type_personal_title': return 'فرد / شخص خاص';
			case 'creator.business.type_personal_subtitle': return 'أتلقى المدفوعات بصفتي فردًا.';
			case 'creator.business.type_company_title': return 'شركة مسجّلة';
			case 'creator.business.type_company_subtitle': return 'أعمل تحت كيان قانوني مسجّل.';
			case 'creator.business.company_name': return 'اسم الشركة';
			case 'creator.business.vat_number': return 'الرقم الضريبي';
			case 'creator.business.address': return 'العنوان';
			case 'creator.business.address_line1': return 'العنوان (سطر 1)';
			case 'creator.business.address_line2': return 'العنوان (سطر 2، اختياري)';
			case 'creator.business.city': return 'المدينة';
			case 'creator.business.postal_code': return 'الرمز البريدي';
			case 'creator.business.state_region': return 'المنطقة (اختياري)';
			case 'creator.business.state': return 'الولاية / المقاطعة';
			case 'creator.business.country': return 'البلد';
			case 'creator.business.currency': return 'عملة الدفع';
			case 'creator.business.billing_currency': return 'العملة المفضّلة';
			case 'creator.business.vat_optional': return 'الرقم الضريبي (اختياري)';
			case 'creator.business.section_billing': return 'بلد وعملة الفوترة';
			case 'creator.business.error_required': return 'حقل مطلوب';
			case 'creator.business.save_and_continue': return 'حفظ ومتابعة';
			case 'creator.business.submitting': return 'جارٍ الحفظ…';
			case 'creator.business.footer_info': return 'تُرسل هذه المعلومات إلى Stripe لتفعيل حساب الدفع. لن تصل إلينا بياناتك المصرفية أبدًا.';
			case 'creator.business.footer_info_global': return 'تُستخدم للفواتير وشحن المحفظة. تتم معالجة المدفوعات بأمان عبر Stripe.';
			case 'creator.business.save_error': return 'تعذّر حفظ المعلومات. يرجى المحاولة مجددًا.';
			case 'creator.business.validation.address_required': return 'العنوان مطلوب';
			case 'creator.business.validation.address_line_invalid': return 'العنوان يحتوي على أحرف غير صالحة';
			case 'creator.business.validation.city_required': return 'المدينة مطلوبة';
			case 'creator.business.validation.city_invalid': return 'المدينة تحتوي على أحرف غير صالحة';
			case 'creator.business.validation.postal_code_required': return 'الرمز البريدي مطلوب';
			case 'creator.business.validation.postal_code_invalid': return 'الرمز البريدي غير صالح';
			case 'creator.business.validation.country_required': return 'البلد مطلوب';
			case 'creator.business.validation.country_stripe_only': return 'البلد غير مدعوم لمدفوعات Stripe';
			case 'creator.business.validation.country_global_invalid': return 'البلد غير مدعوم للفوترة';
			case 'creator.business.validation.currency_required': return 'العملة مطلوبة';
			case 'creator.business.validation.currency_stripe_only': return 'العملة غير مدعومة لمدفوعات Stripe';
			case 'creator.business.validation.currency_global_invalid': return 'العملة غير مدعومة للفوترة';
			case 'creator.business.validation.company_name_required': return 'اسم الشركة مطلوب';
			case 'creator.business.validation.company_name_invalid': return 'اسم الشركة يحتوي على أحرف غير صالحة';
			case 'creator.business.validation.vat_number_required': return 'الرقم الضريبي مطلوب';
			case 'creator.business.validation.vat_number_invalid': return 'صيغة الرقم الضريبي غير صالحة';
			case 'creator.business.validation.state_required': return 'الولاية / المقاطعة مطلوبة';
			case 'creator.business.validation.state_invalid': return 'الولاية / المنطقة غير صالحة';
			case 'creator.trust.title': return 'درجة الثقة';
			case 'creator.trust.tier': return ({required Object name}) => 'المستوى ${name}';
			case 'creator.trust.verified': return 'موثّق';
			case 'creator.trust.delta_up': return ({required Object value}) => '+${value} هذا الأسبوع';
			case 'creator.trust.delta_down': return ({required Object value}) => '-${value} هذا الأسبوع';
			case 'creator.trust.cpm_hint': return ({required Object value}) => 'ارتفاع CPM محتمل: ${value}';
			case 'creator.trust.breakdown_title': return 'تفصيل الدرجة';
			case 'creator.trust.validation_points': return 'معدل التحقق';
			case 'creator.trust.fraud_points': return 'درجة الاحتيال';
			case 'creator.trust.anomaly_points': return 'درجة الشذوذ';
			case 'creator.trust.open_analytics': return 'عرض التحليلات';
			case 'creator.analytics.title': return 'تحليلات المنشئ';
			case 'creator.analytics.period_7d': return '7ي';
			case 'creator.analytics.period_30d': return '30ي';
			case 'creator.analytics.period_90d': return '90ي';
			case 'creator.analytics.load_error': return 'تعذّر تحميل التحليلات';
			case 'creator.analytics.empty': return 'لا توجد بيانات لهذه الفترة بعد';
			case 'creator.analytics.earnings': return 'الأرباح';
			case 'creator.analytics.pending': return 'قيد الانتظار';
			case 'creator.analytics.validated_views': return 'مشاهدات موثّقة';
			case 'creator.analytics.validated_clicks': return 'نقرات موثّقة';
			case 'creator.analytics.recorded_views': return 'مشاهدات مسجّلة';
			case 'creator.analytics.recorded_clicks': return 'نقرات مسجّلة';
			case 'creator.analytics.view_validation_rate': return 'تحقق المشاهدات';
			case 'creator.analytics.click_validation_rate': return 'تحقق النقرات';
			case 'creator.analytics.period_meta': return ({required Object days, required Object currency}) => 'آخر ${days} يوماً · ${currency}';
			case 'creator.analytics.active_campaigns': return 'الحملات النشطة';
			case 'creator.analytics.daily_title': return 'يومي';
			case 'creator.analytics.by_campaign': return 'حسب الحملة';
			case 'creator.analytics.server_authority_note': return 'المبالغ والمعدلات من الخادم. التطبيق لا يخترع قواعد مالية.';
			case 'advertiser_wallet.hero_title': return 'رصيدك';
			case 'advertiser_wallet.hero_subtitle': return 'أضف رصيداً لتشغيل الحملات. تتم المعالجة بأمان عبر Stripe. يتوفر Apple Pay على iOS وGoogle Pay على Android عند دعمهما.';
			case 'advertiser_wallet.available': return 'المتاح';
			case 'advertiser_wallet.pending': return 'قيد الانتظار';
			case 'advertiser_wallet.add_funds': return 'إضافة رصيد';
			case 'advertiser_wallet.amount_label': return 'المبلغ';
			case 'advertiser_wallet.quick_50': return '50 USD';
			case 'advertiser_wallet.quick_100': return '100 USD';
			case 'advertiser_wallet.quick_250': return '500 USD';
			case 'advertiser_wallet.min_deposit': return 'الحد الأدنى للإيداع {amount}.';
			case 'advertiser_wallet.test_pay': return 'محاكاة الدفع (تطوير)';
			case 'advertiser_wallet.test_hint': return 'وضع اختباري: بدون بطاقة حقيقية.';
			case 'advertiser_wallet.pay_secure': return 'بطاقة أو Apple Pay أو Google Pay';
			case 'advertiser_wallet.pay_with_card': return 'الدفع بالبطاقة';
			case 'advertiser_wallet.pay_with_apple': return 'الدفع عبر Apple Pay';
			case 'advertiser_wallet.pay_with_google': return 'الدفع عبر Google Pay';
			case 'advertiser_wallet.google_pay_with_prefix': return 'الدفع عبر';
			case 'advertiser_wallet.or': return 'أو';
			case 'advertiser_wallet.stripe_unavailable': return 'الشحن غير متاح: لم يُضبط الدفع في الخادم.';
			case 'advertiser_wallet.stripe_keys_mismatch': return 'الدفع مُعدّ بشكل خاطئ على الخادم (خلط مفاتيح Stripe للاختبار/الإنتاج). تواصل مع الدعم.';
			case 'advertiser_wallet.apple_pay_test_hint': return 'وضع اختبار Stripe: Apple Pay يستخدم بطاقة المحفظة دون خصم حقيقي.';
			case 'advertiser_wallet.tx_title': return 'آخر الحركات';
			case 'advertiser_wallet.tx_empty': return 'لا معاملات بعد';
			case 'advertiser_wallet.tx_deposit': return 'إيداع';
			case 'advertiser_wallet.tx_withdrawal': return 'سحب';
			case 'advertiser_wallet.tx_other': return 'معاملة';
			case 'advertiser_wallet.success': return 'تم تحديث الرصيد';
			case 'advertiser_wallet.failed': return 'تعذّر إضافة الرصيد. أعد المحاولة.';
			case 'advertiser_wallet.in_progress': return 'جاري المعالجة…';
			case 'advertiser_wallet.tx_page': return ({required Object current, required Object total}) => 'الصفحة ${current} من ${total}';
			case 'advertiser_wallet.tx_prev': return 'السابق';
			case 'advertiser_wallet.tx_next': return 'التالي';
			case 'advertiser_wallet.business_profile_gate_title': return 'بيانات النشاط مطلوبة';
			case 'advertiser_wallet.business_profile_gate_body': return 'أكمل معلومات الفوترة الصالحة قبل إضافة الرصيد — متوافق مع Wayo Ads.';
			case 'advertiser_wallet.business_profile_gate_secure': return 'اتصال مشفّر والتحقق على الخادم قبل أي دفع.';
			case 'advertiser_wallet.business_profile_gate_cta': return 'إكمال بيانات النشاط';
			case 'advertiser_wallet.business_profile_error': return 'تعذّر تحميل الملف التجاري.';
			case 'advertiser_wallet.pay_locked_until_business': return 'تُفعّل طرق الدفع بعد إكمال الملف التجاري.';
			case 'advertiser_wallet.payment_title': return 'الدفع';
			case 'advertiser_wallet.payment_total': return 'الإجمالي';
			case 'advertiser_wallet.payment_deposit_amount': return 'مبلغ الإيداع';
			case 'advertiser_wallet.payment_bank_fee': return 'رسوم المعاملة البنكية (3.69%)';
			case 'advertiser_wallet.deposit_pending': return 'إيداع قيد الانتظار';
			case 'advertiser_wallet.deposit_resume_hint': return 'استئناف إيداعك بقيمة {amount} — أكمل الدفع أو اضغط إلغاء للتخلي عنه.';
			case 'advertiser_wallet.deposit_cancel': return 'إلغاء';
			case 'advertiser_wallet.funding_method_label': return 'طريقة التمويل';
			case 'advertiser_wallet.funding_card_title': return 'بطاقة';
			case 'advertiser_wallet.funding_card_badge': return 'فوري';
			case 'advertiser_wallet.funding_card_desc': return 'Visa وMastercard وAmex — تتوفر الأموال فوراً.';
			case 'advertiser_wallet.funding_ach_title': return 'خصم بنكي (ACH)';
			case 'advertiser_wallet.funding_ach_badge': return 'رسوم أقل';
			case 'advertiser_wallet.funding_ach_desc': return 'خصم مباشر من حسابك البنكي الأمريكي — رسوم أقل من البطاقة.';
			case 'advertiser_wallet.funding_ach_eta': return 'تستقر الأموال عادة خلال 1-3 أيام عمل.';
			case 'advertiser_wallet.funding_ach_usd_only': return 'ACH متاح فقط للمحافظ بالدولار الأمريكي.';
			case 'advertiser_wallet.funding_wire_title': return 'حوالة بنكية';
			case 'advertiser_wallet.funding_wire_badge': return 'مبالغ كبيرة';
			case 'advertiser_wallet.funding_wire_desc': return 'أرسل حوالة بنكية باستخدام التعليمات المقدمة.';
			case 'advertiser_wallet.funding_wire_eta': return 'تصل الأموال عادة خلال 1-3 أيام عمل.';
			case 'advertiser_wallet.funding_wire_currency_only': return 'الحوالة متاحة فقط لـ: {currencies}.';
			case 'advertiser_wallet.saved_cards_loading': return 'جارٍ تحميل البطاقات المحفوظة…';
			case 'advertiser_wallet.default_card_badge': return 'افتراضية';
			case 'advertiser_wallet.saved_card_badge': return 'محفوظة';
			case 'advertiser_wallet.use_new_card': return 'استخدام بطاقة جديدة';
			case 'advertiser_wallet.use_saved_card': return 'استخدام بطاقة محفوظة';
			case 'advertiser_wallet.change_method': return 'تغيير';
			case 'advertiser_wallet.remove_card': return 'إزالة';
			case 'advertiser_wallet.remove_card_confirm_title': return 'إزالة هذه البطاقة؟';
			case 'advertiser_wallet.remove_card_confirm_desc': return 'سيتم إزالة {brand} •••• {last4} من بطاقاتك المحفوظة.';
			case 'advertiser_wallet.remove_card_confirm_action': return 'إزالة';
			case 'advertiser_wallet.card_removed_title': return 'تمت إزالة البطاقة';
			case 'advertiser_wallet.card_removed_desc': return 'تمت إزالة •••• {last4}.';
			case 'advertiser_wallet.card_remove_failed': return 'تعذّر إزالة هذه البطاقة. أعد المحاولة.';
			case 'advertiser_wallet.refresh_saved_cards': return 'تحديث';
			case 'advertiser_wallet.pay_with_saved_card': return 'الدفع بـ {brand} •••• {last4}';
			case 'advertiser_wallet.wire_instructions_loading': return 'تجهيز تعليمات الحوالة…';
			case 'advertiser_wallet.wire_awaiting_title': return 'في انتظار حوالتك البنكية';
			case 'advertiser_wallet.wire_awaiting_desc': return 'أرسل حوالة باستخدام التفاصيل أدناه. سيتم تحديث رصيدك عند استلام الأموال.';
			case 'advertiser_wallet.wire_exact_amount': return 'المبلغ الدقيق';
			case 'advertiser_wallet.wire_reference': return 'المرجع (مطلوب)';
			case 'advertiser_wallet.wire_reference_required_hint': return 'أضف هذا المرجع في بيان الحوالة — بدونه لا يمكننا مطابقة دفعتك.';
			case 'advertiser_wallet.wire_copy_action': return 'نسخ';
			case 'advertiser_wallet.wire_copied_title': return 'تم النسخ';
			case 'advertiser_wallet.wire_copied_desc': return 'تم النسخ إلى الحافظة.';
			case 'advertiser_wallet.wire_copy_failed': return 'تعذّر النسخ. أعد المحاولة.';
			case 'advertiser_wallet.wire_network_swift': return 'حوالة SWIFT / دولية';
			case 'advertiser_wallet.wire_network_aba': return 'حوالة أمريكية محلية (ABA)';
			case 'advertiser_wallet.wire_network_iban': return 'IBAN / SEPA';
			case 'advertiser_wallet.wire_network_sort_code': return 'حوالة بنكية بريطانية';
			case 'advertiser_wallet.wire_network_other': return '{network}';
			case 'advertiser_wallet.wire_account_holder': return 'اسم صاحب الحساب';
			case 'advertiser_wallet.wire_bank_name': return 'اسم البنك';
			case 'advertiser_wallet.wire_routing_number': return 'رقم التوجيه';
			case 'advertiser_wallet.wire_sort_code': return 'Sort code';
			case 'advertiser_wallet.wire_account_number': return 'رقم الحساب';
			case 'advertiser_wallet.wire_swift_code': return 'SWIFT/BIC';
			case 'advertiser_wallet.wire_iban': return 'IBAN';
			case 'advertiser_wallet.wire_bic': return 'BIC';
			case 'advertiser_wallet.wire_hosted_instructions': return 'عرض التعليمات الكاملة';
			case 'advertiser_wallet.wire_done_button': return 'لقد أرسلت الحوالة';
			case 'advertiser_wallet.ach_processing_banner': return 'إيداع ACH بقيمة {amount} قيد المعالجة — تستقر الأموال عادة خلال 1-3 أيام عمل.';
			case 'advertiser_wallet.wire_awaiting_banner': return 'إيداع الحوالة بقيمة {amount} في انتظار حوالتك البنكية.';
			case 'advertiser_wallet.reconcile_button': return 'تحقق من الحالة';
			case 'advertiser_wallet.reconcile_success': return 'تم تحديث الحالة.';
			case 'advertiser_wallet.reconcile_still_pending': return 'لا يزال قيد المعالجة — تحقق قريباً.';
			case 'advertiser_wallet.reconcile_failed': return 'تعذّر التحقق من الحالة. أعد المحاولة.';
			case 'advertiser_wallet.continue_to_payment': return 'استمرار';
			case 'advertiser_wallet.cancel': return 'إلغاء';
			case 'chat.inbox_title': return 'الرسائل';
			case 'chat.inbox_subtitle': return 'محادثات آمنة لحملاتك';
			case 'chat.conversation_unknown': return 'محادثة';
			case 'chat.thread_fallback_title': return 'محادثة';
			case 'chat.role_creator': return 'منشئ';
			case 'chat.role_advertiser': return 'معلن';
			case 'chat.role_admin': return 'أدمن';
			case 'chat.composer_hint': return 'اكتب رسالة…';
			case 'chat.typing': return 'يكتب…';
			case 'chat.error_load_threads': return 'تعذّر تحميل محادثاتك. أعد المحاولة.';
			case 'chat.error_phone': return 'مشاركة أرقام الهاتف في الدردشة غير مسموحة.';
			case 'chat.spam_cooldown_title': return 'ترسل رسائلًا بسرعة كبيرة';
			case 'chat.spam_cooldown_body': return ({required Object seconds}) => 'انتظر ${seconds} ث قبل الإرسال مرة أخرى.';
			case 'chat.spam_cooldown_seconds': return ({required Object seconds}) => '${seconds} ث';
			case 'chat.empty_threads_title': return 'لا توجد محادثات بعد';
			case 'chat.empty_threads_hint': return 'عندما يراسلك أحدهم بخصوص حملة، ستظهر هنا.';
			case 'chat.online': return 'متصل';
			case 'chat.offline': return 'غير متصل';
			case 'chat.typing_status': return 'يكتب…';
			case 'chat.attachment': return 'مرفق';
			case 'chat.attachment_image': return 'صورة';
			case 'chat.attachment_pdf': return 'PDF';
			case 'chat.open_file': return 'فتح';
			case 'chat.pick_attachment': return 'صورة أو PDF';
			case 'chat.upload_failed': return 'تعذّر إرسال الملف. حاول مرة أخرى.';
			case 'chat.file_too_large': return 'الملف كبير جداً (حد أقصى 10 ميجا للصور، 50 ميجا لملف PDF).';
			case 'chat.search_users_hint': return 'ابحث عن شخص بالاسم…';
			case 'chat.search_users_no_results': return 'لا يوجد مستخدمون مطابقون.';
			case 'chat.search_users_min_hint': return 'اكتب حرفين على الأقل للبحث.';
			case 'chat.search_prior_chats_hint': return 'ابحث بين من راسلتهم…';
			case 'chat.search_prior_chats_no_results': return 'لا يوجد تطابق بين أشخاص محادثاتك.';
			case 'chat.search_prior_chats_min_hint': return 'اكتب حرفين على الأقل.';
			case 'chat.conversation_open_failed': return 'تعذّر فتح هذه المحادثة. حاول مرة أخرى.';
			case 'chat.file_picker_restart_hint': return 'المرفقات تحتاج إعادة تشغيل كاملة للتطبيق بعد التحديثات. أوقف التطبيق ثم شغّله من جديد (تجنّب hot restart).';
			case 'chat.attachment_type_not_allowed': return 'يُسمح فقط بالصور (JPG أو PNG أو GIF أو WebP أو BMP) أو ملفات PDF.';
			case 'chat.inbox_filter_active': return 'الوارد';
			case 'chat.inbox_filter_archived': return 'المؤرشفة';
			case 'chat.inbox_pinned': return 'مثبّتة';
			case 'chat.inbox_unpinned': return 'أُزيل التثبيت';
			case 'chat.inbox_archived': return 'مؤرشفة';
			case 'chat.inbox_unarchived': return 'أُعيدت إلى الوارد';
			case 'chat.inbox_pin_failed': return 'تعذّر تحديث التثبيت. حاول مرة أخرى.';
			case 'chat.inbox_archive_failed': return 'تعذّر تحديث الأرشفة. حاول مرة أخرى.';
			case 'chat.inbox_pin_disabled': return 'التثبيت والأرشفة غير متاحين مؤقتًا.';
			case 'chat.menu_more': return 'المزيد';
			case 'chat.menu_pin': return 'تثبيت';
			case 'chat.menu_unpin': return 'إلغاء التثبيت';
			case 'chat.menu_archive': return 'أرشفة';
			case 'chat.menu_unarchive': return 'إلغاء الأرشفة';
			case 'chat.menu_delete': return 'حذف';
			case 'chat.delete_conversation': return 'حذف المحادثة';
			case 'chat.delete_conversation_confirm_title': return 'حذف هذه المحادثة؟';
			case 'chat.delete_conversation_confirm_text': return 'سيتم حذف جميع الرسائل نهائيًا لكلا الطرفين. لا يمكن التراجع عن هذا الإجراء.';
			case 'chat.delete_conversation_confirm_cta': return 'حذف';
			case 'chat.delete_conversation_failed': return 'تعذّر حذف المحادثة. حاول مرة أخرى.';
			case 'chat.delete_conversation_done': return 'تم حذف المحادثة';
			case 'chat.empty_archived_title': return 'لا محادثات مؤرشفة';
			case 'chat.empty_archived_hint': return 'اسحب محادثة إلى اليسار لأرشفتها.';
			case 'chat.date_today': return 'اليوم';
			case 'chat.date_yesterday': return 'أمس';
			case 'chat.bubble_reply': return 'رد';
			case 'chat.reply_composer_title': return 'رد';
			case 'chat.reply_composer_you': return 'أنت';
			case 'chat.composer_reply_hint': return 'اكتب رداً…';
			case 'chat.bubble_copy': return 'نسخ';
			case 'chat.bubble_react': return 'تفاعل';
			case 'chat.bubble_delete': return 'حذف';
			case 'chat.bubble_update': return 'تعديل';
			case 'chat.bubble_delete_unavailable': return 'حذف الرسائل من التطبيق غير متاح بعد.';
			case 'chat.bubble_copied': return 'تم النسخ إلى الحافظة';
			case 'chat.bubble_forward': return 'تحويل';
			case 'chat.share_media_tooltip': return 'مشاركة';
			case 'chat.share_failed': return 'تعذر مشاركة هذا الملف. حاول مرة أخرى.';
			case 'chat.forward_sheet_title': return 'إعادة الإرسال إلى…';
			case 'chat.forward_no_other_chats': return 'يلزم محادثة أخرى مفتوحة أولاً.';
			case 'chat.forward_sending': return 'جاري التحويل…';
			case 'chat.forward_ok': return 'تم تحويل الرسالة.';
			case 'chat.forward_failed': return 'فشل التحويل.';
			case 'chat.forward_view': return 'فتح';
			case 'chat.edited': return 'معدَّل';
			case 'chat.message_deleted': return 'تم حذف هذه الرسالة';
			case 'chat.seen': return 'تمت القراءة';
			case 'chat.delivered': return 'تم التسليم';
			case 'chat.edit_mode_title': return 'تعديل الرسالة';
			case 'chat.edit_mode_cancel': return 'إلغاء';
			case 'chat.edit_mode_hint': return 'حدّث رسالتك…';
			case 'chat.edit_failed': return 'تعذّر تعديل الرسالة. حاول مرة أخرى.';
			case 'chat.edit_not_allowed': return 'يمكن تعديل رسائلك النصية فقط.';
			case 'chat.delete_failed': return 'تعذّر حذف الرسالة. حاول مرة أخرى.';
			case 'chat.delete_not_allowed': return 'يمكنك حذف رسائلك الخاصة فقط.';
			case 'chat.delete_confirm_title': return 'حذف هذه الرسالة؟';
			case 'chat.delete_confirm_text': return 'لا يمكن التراجع عن هذا الإجراء.';
			case 'chat.delete_confirm_cta': return 'حذف';
			case 'chat.delete_confirm_cancel': return 'إلغاء';
			case 'chat.scroll_to_latest': return 'الأحدث';
			case 'chat.loading_older_messages': return 'جاري تحميل الرسائل الأقدم…';
			case 'chat.load_older_failed': return 'تعذّر تحميل الرسائل الأقدم.';
			case 'chat.image_download_tooltip': return 'تنزيل الصورة';
			case 'chat.image_close_tooltip': return 'إغلاق';
			case 'chat.image_saved_to_gallery': return 'تم حفظ الصورة في معرض الصور.';
			case 'chat.image_download_failed': return 'تعذّر تنزيل هذه الصورة.';
			case 'chat.image_permission_denied': return 'تم رفض الوصول إلى الصور. فعّل الإذن من الإعدادات.';
			case 'chat.image_saved_downloads_browser': return 'تم تنزيل الصورة — تحقق من مجلد التحميلات.';
			case 'chat.peer_unavailable': return 'هذا المستخدم لم يعد متاحًا.';
			case 'common.language': return 'اللغة';
			case 'common.theme': return 'المظهر';
			case 'common.light': return 'فاتح';
			case 'common.dark': return 'داكن';
			case 'common.system': return 'النظام';
			case 'errors.rate_limited': return 'عدد كبير من المحاولات. أعد المحاولة بعد بضع دقائق.';
			case 'errors.invalid_credentials': return 'بيانات الدخول غير صحيحة.';
			case 'errors.network': return 'تعذّر الاتصال بالخادم. تحقق من اتصالك.';
			case 'errors.server_generic': return 'حدث خطأ. حاول مرة أخرى.';
			case 'errors.empty_response': return 'استجابة فارغة من الخادم.';
			case 'errors.login_failed': return 'فشل تسجيل الدخول.';
			case 'errors.unknown': return 'حدث خطأ غير متوقع.';
			case 'errors.session_invalid': return 'انتهت جلستك. سجّل الدخول من جديد.';
			case 'errors.email_not_found': return 'لا يوجد حساب بهذا البريد.';
			case 'privacy_policy.title': return 'سياسة الخصوصية';
			case 'privacy_policy.last_updated': return 'آخر تحديث: 7 أكتوبر 2025';
			case 'privacy_policy.company_legal_name': return 'AL BOUHOUTI SOFTWARE DESIGN COMPANY L.L.C';
			case 'privacy_policy.operator_intro': return 'يُدار هذا الموقع ومنصة Wayo Ads بواسطة:';
			case 'privacy_policy.company_address': return 'Al Barshaa 1، دبي، دبي، الإمارات العربية المتحدة';
			case 'privacy_policy.support_label': return 'دعم العملاء';
			case 'privacy_policy.support_email': return 'support@wayo.cloud';
			case 'privacy_policy.support_phone': return '+971 542396643';
			case 'privacy_policy.intro_title': return '1. مقدمة';
			case 'privacy_policy.intro_body': return 'في Wayo Ads نلتزم بجمع بياناتك واستخدامها بمسؤولية، وفقًا لقوانين حماية البيانات المعمول بها في الولايات القضائية التي نعمل فيها، بما في ذلك القانون الفدرالي وقوانين الولايات في الولايات المتحدة عند الاقتضاء، وللمستخدمين في المنطقة الاقتصادية الأوروبية أو المملكة المتحدة عند الاقتضاء، اللائحة العامة لحماية البيانات (GDPR) (الاتحاد الأوروبي 2016/679). باستخدامك منصتنا، فإنك توافق على جمع بياناتك ومعالجتها واستخدامها كما هو موضح في سياسة الخصوصية هذه.';
			case 'privacy_policy.data_title': return '2. البيانات التي نجمعها';
			case 'privacy_policy.data_intro': return 'نجمع فقط البيانات الضرورية، وفقًا للقانون المعمول به وعند الاقتضاء اللائحة العامة لحماية البيانات.';
			case 'privacy_policy.data_advertisers_title': return 'للمعلنين';
			case 'privacy_policy.data_advertisers_body': return 'التعريف وبيانات الاتصال: اسم الشركة، البريد الإلكتروني، رقم الهاتف.\nالملف الشخصي: شعار الشركة (إن وُجد)، وصف النشاط.\nالحملات: محتوى الحملات، الميزانيات، معايير الاستهداف، بيانات التحليلات.';
			case 'privacy_policy.data_creators_title': return 'للمبدعين';
			case 'privacy_policy.data_creators_body': return 'التعريف وبيانات الاتصال: الاسم، البريد الإلكتروني، رقم الهاتف.\nالملف الشخصي: صورة الملف (إن وُجدت)، السيرة، الخبرات، روابط وسائل التواصل.\nالمحتوى: الفيديوهات والمنشورات والمواد التي ترفعها.\nبيانات الاستخدام: التفاعل مع المنصة، إحصاءات التفاعل، بيانات الأرباح.';
			case 'privacy_policy.data_technical_title': return 'معلومات تقنية (جميع المستخدمين)';
			case 'privacy_policy.data_technical_body': return 'بيانات تقنية: عنوان IP، نوع المتصفح وإصداره، نوع الجهاز، نظام التشغيل، معرّفات الجلسة، الطوابع الزمنية، الصفحات التي زرتها، النقرات، المصادر الإحالة.\nملفات تعريف الارتباط وتقنيات مشابهة: انظر القسم 8 (ملفات تعريف الارتباط).';
			case 'privacy_policy.data_payment_title': return 'بيانات الدفع';
			case 'privacy_policy.data_payment_body': return 'المعاملات: المبالغ، العملة، التاريخ، وسيلة الدفع، عنوان الفوترة.';
			case 'privacy_policy.data_payment_note': return 'هام: تُعالج بيانات البطاقة حصريًا عبر مزود الدفع (Stripe). لا تخزّن Wayo معلومات بطاقة الائتمان.';
			case 'privacy_policy.purpose_title': return '3. أغراض استخدام بياناتك';
			case 'privacy_policy.purpose_body': return 'نستخدم بياناتك من أجل: تقديم خدماتنا وصيانتها وتحسينها؛ تخصيص التجربة واقتراح محتوى مناسب؛ إدارة العلاقات التعاقدية (الحسابات، الفوترة، الدعم)؛ إبلاغك بمعلومات الخدمة (التحديثات، التغييرات، التنبيهات)؛ ضمان أمان المنصة وسلامتها (اكتشاف إساءة الاستخدام والاحتيال)؛ إجراء تحليلات للاستخدام ببيانات مجمّعة أو مجهولة المصدر قدر الإمكان.';
			case 'privacy_policy.legal_bases_title': return '4. الأسس القانونية للمعالجة';
			case 'privacy_policy.legal_bases_body': return 'بحسب الحالة، نعتمد على: موافقتك (مثل ملفات تعريف الارتباط غير الضرورية، النشرات الإخبارية)؛ تنفيذ عقد أو إجراءات ما قبل تعاقدية (مثل التسجيل، الفوترة)؛ الامتثال لالتزام قانوني (مثل الاحتفاظ بالفواتير)؛ مصلحتنا المشروعة (مثل الأمان، تحسين الخدمة).';
			case 'privacy_policy.sharing_title': return '5. مشاركة معلوماتك';
			case 'privacy_policy.sharing_body': return 'لا تبيع Wayo بياناتك الشخصية. قد يحدث مشاركة محدودة مع: مزودي خدمات أساسيين (معالجة الدفع، الاستضافة، البريد، التحليلات)؛ لأسباب قانونية إذا طلب القانون ذلك أو استجابةً لطلب مشروع من جهة مختصة.';
			case 'privacy_policy.security_title': return '6. أمن البيانات';
			case 'privacy_policy.security_body': return 'تشفير TLS/HTTPS للبيانات أثناء النقل.\nضوابط وصول وفق مبدأ «الحاجة للمعرفة».\nنسخ احتياطي منتظم وإجراءات استعادة.\nتحديثات أمنية وتدقيقات دورية.\nتسجيل واكتشاف الأنشطة غير الاعتيادية.';
			case 'privacy_policy.content_title': return '7. مسؤوليات المستخدمين وحماية المحتوى';
			case 'privacy_policy.content_body': return 'احترم حقوق الملكية الفكرية للمبدعين ولـ Wayo. لا تنسخ أو تشارك أو تعيد توزيع أو تعيد بيع المحتوى دون إذن. قد يؤدي أي خرق إلى تعليق الحساب وإجراءات قانونية عند الاقتضاء.';
			case 'privacy_policy.cookies_title': return '8. ملفات تعريف الارتباط وتقنيات التتبع';
			case 'privacy_policy.cookies_body': return 'ملفات تعريف ارتباط ضرورية (تشغيل الموقع، الأمان، الجلسة).\nملفات تحليلية (مثل Google Analytics) لقياس الجمهور.\nلا تُفعّل ملفات غير الضرورية إلا بموافقتك عبر شريط ملفات تعريف الارتباط عند أول زيارة.';
			case 'privacy_policy.retention_title': return '9. الاحتفاظ بالبيانات';
			case 'privacy_policy.retention_body': return 'نحتفظ ببياناتك فقط للمدة اللازمة للأغراض الواردة هنا. تُحفظ بيانات الحساب طيلة عمر الحساب زائد أي مدة احتفاظ قانونية. تُحفظ بيانات المعاملات وفقًا لمتطلبات المحاسبة والضرائب.';
			case 'privacy_policy.children_title': return '10. خصوصية الأطفال';
			case 'privacy_policy.children_body': return 'خدماتنا غير موجّهة لمن دون 18 عامًا. لا نجمع عن قصد معلومات شخصية من أطفال. إذا علمنا أننا جمعنا بيانات طفل دون موافقة ولي الأمر، سنتخذ خطوات لحذفها.';
			case 'privacy_policy.changes_title': return '11. تغييرات هذه السياسة';
			case 'privacy_policy.changes_body': return 'قد نحدّث سياسة الخصوصية من وقت لآخر. سنُعلمك بأي تغييرات جوهرية بنشر السياسة الجديدة على هذه الصفحة وتحديث تاريخ «آخر تحديث».';
			case 'privacy_policy.contact_title': return '12. معلومات الاتصال';
			case 'privacy_policy.contact_controller_label': return 'مسؤول المعالجة';
			case 'privacy_policy.contact_controller': return 'Wayo، دبي، الإمارات العربية المتحدة';
			case 'privacy_policy.contact_email_label': return 'البريد الإلكتروني';
			case 'privacy_policy.contact_email': return 'info@wayo.cloud';
			case 'privacy_policy.contact_address_label': return 'العنوان';
			case 'privacy_policy.contact_address': return 'R320 Umm Hurair 2, Dubai, UAE';
			case 'terms_and_conditions.title': return 'الشروط والأحكام';
			case 'terms_and_conditions.last_updated': return 'آخر تحديث: 7 أكتوبر 2025';
			case 'terms_and_conditions.company_legal_name': return 'AL BOUHOUTI SOFTWARE DESIGN COMPANY L.L.C';
			case 'terms_and_conditions.operator_intro': return 'يُدار هذا الموقع ومنصة Wayo Ads بواسطة:';
			case 'terms_and_conditions.company_address': return 'Al Barshaa 1، دبي، دبي، الإمارات العربية المتحدة';
			case 'terms_and_conditions.support_label': return 'دعم العملاء';
			case 'terms_and_conditions.support_email': return 'support@wayo.cloud';
			case 'terms_and_conditions.support_phone': return '+971 542396643';
			case 'terms_and_conditions.back_home': return 'العودة إلى الصفحة الرئيسية';
			case 'terms_and_conditions.intro_title': return '1. مقدمة';
			case 'terms_and_conditions.intro_body': return 'مرحبًا بك في Wayo Ads، منصتك الإلكترونية التي تربط المعلنين بصنّاع المحتوى. بالوصول إلى موقعنا و/أو تطبيقنا للجوال، فإنك توافق على الالتزام بهذه الشروط والأحكام. يرجى قراءتها بعناية، فهي تحدد حقوقك والتزاماتك كمستخدم.';
			case 'terms_and_conditions.definitions_title': return '2. التعريفات';
			case 'terms_and_conditions.definitions_body': return 'Wayo — مجموعة خدمات الإعلان وسوق المبدعين المتاحة عبر الموقع وتطبيق الجوال.\nالمستخدم — أي شخص (معلن، مبدع، أو منظمة) يمتلك حسابًا على المنصة.\nالمحتوى — جميع المستندات والفيديوهات والإعلانات والحملات والمواد الأخرى المتاحة عبر المنصة.\nحقوق الاستخدام — حقوق الوصول والاستخدام للمحتوى شخصية وخاصة وغير قابلة للتحويل.';
			case 'terms_and_conditions.access_title': return '3. الوصول والاستخدام';
			case 'terms_and_conditions.access_body': return 'يجب على المستخدم إنشاء حساب بتقديم معلومات دقيقة ومحدّثة. المستخدم مسؤول عن الحفاظ على سرية بيانات تسجيل الدخول. يجب الإبلاغ فورًا عن أي استخدام غير مصرّح به.';
			case 'terms_and_conditions.content_protection_title': return '4. حماية المحتوى واستخدامه';
			case 'terms_and_conditions.content_protection_body': return 'تبقى جميع المواد والمحتوى ملكًا فكريًا لأصحابها. يُحظر منعًا باتًا النسخ أو التوزيع أو البيع أو المشاركة. أي مخالفة تؤدي إلى تعليق الحساب فورًا وقد تستوجب إجراءات قانونية.';
			case 'terms_and_conditions.features_title': return '5. الميزات والخدمات';
			case 'terms_and_conditions.features_body': return 'توفر منصتنا ميزات متعددة تشمل إنشاء الحملات، سوق المبدعين، لوحات التحليلات، معالجة الدفع، وأدوات التواصل. يوافق المستخدمون على استخدام هذه الخدمات بمسؤولية وفقًا لهذه الشروط.';
			case 'terms_and_conditions.support_title': return '6. الدعم الفني والصيانة';
			case 'terms_and_conditions.support_body': return 'الدعم متاح من الاثنين إلى الجمعة، من 9:00 صباحًا إلى 5:00 مساءً (UTC+1) عبر البريد الإلكتروني أو الدردشة المدمجة. وقت الاستجابة المقدّر من 24 إلى 48 ساعة. سيتم إخطار المستخدمين مسبقًا بأي توقف مجدول.';
			case 'terms_and_conditions.rights_title': return '7. حقوق ومسؤوليات المستخدم';
			case 'terms_and_conditions.rights_body': return 'للمعلنين الحق في إنشاء الحملات وإدارتها والوصول إلى التحليلات والتواصل مع المبدعين. للمبدعين الحق في تصفح الحملات وقبول العروض وتلقي الأجر عن العمل المنجز. يجب على جميع المستخدمين التصرف بحسن نية والامتثال لقواعد المنصة.';
			case 'terms_and_conditions.prohibited_title': return 'سلوك محظور';
			case 'terms_and_conditions.prohibited_body': return 'يُحظر منعًا باتًا الاحتيال (مثل المشاهدات الوهمية أو click fraud)، المحتوى غير القانوني أو المسيء أو الضار، الرسائل المزعجة، انتحال الهوية، وأي نشاط يضر بسلامة المنصة. أي خرق قد يؤدي إلى تعليق دائم وإجراءات قانونية.';
			case 'terms_and_conditions.ip_title': return '8. الملكية الفكرية';
			case 'terms_and_conditions.ip_body': return 'جميع العلامات التجارية والشعارات والتصاميم والأكواد والملكية الفكرية الأخرى على المنصة محمية بقوانين حقوق النشر والاتفاقيات الدولية. يحتفظ المستخدمون بملكية المحتوى الذي ينشئونه لكنهم يمنحون Wayo ترخيصًا غير حصري لاستضافته وعرضه وجعله متاحًا.';
			case 'terms_and_conditions.privacy_title': return '9. البيانات الشخصية';
			case 'terms_and_conditions.privacy_body': return 'يتم جمع البيانات ومعالجتها وفقًا لسياسة الخصوصية لدينا. للمستخدمين الحق في الوصول إلى بياناتهم الشخصية وتصحيحها وحذفها. لمزيد من المعلومات، راجع سياسة الخصوصية.';
			case 'terms_and_conditions.view_privacy_policy': return 'عرض سياسة الخصوصية';
			case 'terms_and_conditions.liability_title': return '10. تحديد المسؤولية';
			case 'terms_and_conditions.liability_body': return 'لا تتحمل Wayo المسؤولية عن: جودة أو ملاءمة المحتوى المقدّم من المستخدمين، النزاعات بين المعلنين والمبدعين، انقطاع الخدمة، فقدان البيانات، أو المشكلات التقنية. تقتصر مسؤولية Wayo على مبلغ الرسوم المدفوعة مقابل الخدمة.';
			case 'terms_and_conditions.termination_title': return '11. الإنهاء';
			case 'terms_and_conditions.termination_body': return 'يجوز لـ Wayo تعليق أو إنهاء حساب في حال مخالفة هذه الشروط. يمكن للمستخدمين إغلاق حسابهم عبر واجهة المنصة في أي وقت. عند الإنهاء، تُلغى جميع الحقوق والوصول فورًا.';
			case 'terms_and_conditions.governing_law_title': return '12. القانون الحاكم وتسوية النزاعات';
			case 'terms_and_conditions.governing_law_body': return 'القانون الحاكم: القوانين المعمول بها في الإمارات العربية المتحدة. يتفق الطرفان على السعي إلى حل ودي قبل اللجوء إلى الإجراءات القانونية.';
			case 'terms_and_conditions.amendments_title': return '13. تعديلات على الشروط';
			case 'terms_and_conditions.amendments_body': return 'يجوز لـ Wayo تعديل هذه الشروط في أي وقت. سيتم إخطار المستخدمين بأي تغييرات، وتدخل حيز التنفيذ بعد 15 يومًا من الإخطار.';
			case 'terms_and_conditions.waiver_title': return '14. التنازل والإقرار';
			case 'terms_and_conditions.waiver_body': return 'تنازل عن الدعاوى الجماعية: يجب التعامل مع جميع النزاعات على أساس فردي.\nمدة التقادم: يجب تقديم أي مطالبة خلال سنة واحدة كحد أقصى.';
			case 'terms_and_conditions.contact_title': return '15. معلومات الاتصال';
			case 'terms_and_conditions.contact_controller_label': return 'مسؤول المعالجة';
			case 'terms_and_conditions.contact_controller': return 'Wayo، دبي، الإمارات العربية المتحدة';
			case 'terms_and_conditions.contact_email_label': return 'البريد الإلكتروني';
			case 'terms_and_conditions.contact_email': return 'info@wayo.cloud';
			case 'terms_and_conditions.contact_address_label': return 'العنوان';
			case 'terms_and_conditions.contact_address': return 'R320 أم هرير 2، دبي، الإمارات العربية المتحدة';
			case 'cookie_policy.title': return 'سياسة ملفات تعريف الارتباط';
			case 'cookie_policy.last_updated': return 'آخر تحديث: 15 مايو 2025';
			case 'cookie_policy.company_legal_name': return 'AL BOUHOUTI SOFTWARE DESIGN COMPANY L.L.C';
			case 'cookie_policy.operator_intro': return 'مشغّل منصة Wayo Ads.';
			case 'cookie_policy.company_address': return 'Al Barshaa 1، دبي، دبي، الإمارات العربية المتحدة';
			case 'cookie_policy.support_label': return 'دعم العملاء';
			case 'cookie_policy.support_email': return 'support@wayo.cloud';
			case 'cookie_policy.support_phone': return '+971 542396643';
			case 'cookie_policy.back_home': return 'العودة إلى الصفحة الرئيسية';
			case 'cookie_policy.intro_title': return '1. مقدمة';
			case 'cookie_policy.intro_body': return 'توضّح سياسة ملفات تعريف الارتباط هذه كيفية استخدام Wayo Ads لملفات تعريف الارتباط وتقنيات التتبع المماثلة عند زيارتك لموقعنا. باستخدامك منصتنا، فإنك توافق على استخدام ملفات تعريف الارتباط كما هو موضّح في هذه السياسة، وفقًا لتفضيلات موافقتك.';
			case 'cookie_policy.what_are_title': return '2. ما هي ملفات تعريف الارتباط؟';
			case 'cookie_policy.what_are_body': return 'ملفات تعريف الارتباط هي ملفات نصية صغيرة تُوضَع على جهازك (كمبيوتر أو جهاز لوحي أو هاتف) عند زيارة موقع ويب. تُستخدم على نطاق واسع لجعل المواقع تعمل بكفاءة، ولتذكّر تفضيلاتك، ولتوفير معلومات لمالكي الموقع. قد تكون «ملفات جلسة» (تُحذف عند إغلاق المتصفح) أو «ملفات دائمة» (تبقى على جهازك لفترة محددة أو حتى تحذفها).';
			case 'cookie_policy.types_title': return '3. أنواع ملفات تعريف الارتباط التي نستخدمها';
			case 'cookie_policy.types_essential_title': return 'ملفات أساسية';
			case 'cookie_policy.types_essential_body': return 'هذه الملفات ضرورية لعمل الموقع بشكل صحيح. تُمكّن الوظائف الأساسية مثل الأمان وإدارة الشبكة وإمكانية الوصول. يمكنك تعطيلها من إعدادات المتصفح، لكن ذلك قد يؤثر على عمل الموقع.';
			case 'cookie_policy.types_analytics_title': return 'ملفات تحليلية';
			case 'cookie_policy.types_analytics_body': return 'تساعدنا هذه الملفات على فهم كيفية تفاعل الزوار مع موقعنا من خلال جمع المعلومات والإبلاغ عنها بشكل مجهول. نستخدم Google Analytics لقياس حركة المرور وأنماط الاستخدام. لا تُفعَّل ملفات التحليلات إلا بموافقتك عبر شريط ملفات تعريف الارتباط.';
			case 'cookie_policy.types_preferences_title': return 'ملفات التفضيلات';
			case 'cookie_policy.types_preferences_body': return 'تسمح هذه الملفات للموقع بتذكّر اختياراتك (مثل لغتك أو حالة الشريط الجانبي) لتقديم تجربة أكثر تخصيصًا.';
			case 'cookie_policy.table_title': return '4. قائمة ملفات تعريف الارتباط';
			case 'cookie_policy.table_description': return 'فيما يلي قائمة تفصيلية بملفات تعريف الارتباط التي قد نضعها على جهازك:';
			case 'cookie_policy.table_col_name': return 'اسم الملف';
			case 'cookie_policy.table_col_purpose': return 'الغرض';
			case 'cookie_policy.table_col_duration': return 'المدة';
			case 'cookie_policy.row_cookie_consent_name': return 'cookie_consent';
			case 'cookie_policy.row_cookie_consent_purpose': return 'يخزّن قرار موافقتك على ملفات تعريف الارتباط (قبول أو رفض أو تخصيص)';
			case 'cookie_policy.row_cookie_consent_duration': return 'سنة واحدة';
			case 'cookie_policy.row_cookie_preferences_name': return 'cookie_preferences';
			case 'cookie_policy.row_cookie_preferences_purpose': return 'يخزّن تفضيلات ملفات تعريف الارتباط المخصّصة (مثل تفعيل التحليلات)';
			case 'cookie_policy.row_cookie_preferences_duration': return 'سنة واحدة';
			case 'cookie_policy.row_session_token_name': return 'next-auth.session-token / __Secure-next-auth.session-token';
			case 'cookie_policy.row_session_token_purpose': return 'يحافظ على جلسة المصادقة الخاصة بك';
			case 'cookie_policy.row_session_token_duration': return 'جلسة';
			case 'cookie_policy.row_callback_url_name': return 'next-auth.callback-url';
			case 'cookie_policy.row_callback_url_purpose': return 'يخزّن الصفحة التي تُوجَّه إليها بعد تسجيل الدخول';
			case 'cookie_policy.row_callback_url_duration': return 'جلسة';
			case 'cookie_policy.row_csrf_token_name': return 'next-auth.csrf-token / __Host-next-auth.csrf-token';
			case 'cookie_policy.row_csrf_token_purpose': return 'يحمي من هجمات Cross-Site Request Forgery';
			case 'cookie_policy.row_csrf_token_duration': return 'جلسة';
			case 'cookie_policy.row_pkce_name': return '__Secure-next-auth.pkce.code_verifier';
			case 'cookie_policy.row_pkce_purpose': return 'يؤمّن تدفق مصادقة OAuth (PKCE)';
			case 'cookie_policy.row_pkce_duration': return 'جلسة';
			case 'cookie_policy.row_oauth_state_name': return 'oauth_state_id';
			case 'cookie_policy.row_oauth_state_purpose': return 'يربط بحالة تدفق OAuth لتسجيلات الدخول الاجتماعية الآمنة';
			case 'cookie_policy.row_oauth_state_duration': return '10 دقائق';
			case 'cookie_policy.row_oauth_reauth_name': return 'oauth_force_reauth';
			case 'cookie_policy.row_oauth_reauth_purpose': return 'يضمن طلب مصادقة جديد لتسجيلات الدخول الاجتماعية';
			case 'cookie_policy.row_oauth_reauth_duration': return '10 دقائق';
			case 'cookie_policy.row_yt_pkce_name': return '__yt_oauth_pkce';
			case 'cookie_policy.row_yt_pkce_purpose': return 'يؤمّن تدفق ربط OAuth لـ YouTube';
			case 'cookie_policy.row_yt_pkce_duration': return '10 دقائق';
			case 'cookie_policy.row_locale_name': return 'locale';
			case 'cookie_policy.row_locale_purpose': return 'يتذكّر تفضيل اللغة (الإنجليزية أو الفرنسية أو العربية)';
			case 'cookie_policy.row_locale_duration': return 'سنة واحدة';
			case 'cookie_policy.row_sidebar_name': return 'sidebar_state';
			case 'cookie_policy.row_sidebar_purpose': return 'يتذكّر ما إذا كنت قد طيّت الشريط الجانبي أو وسّعته';
			case 'cookie_policy.row_sidebar_duration': return '7 أيام';
			case 'cookie_policy.row_iab_dismissed_name': return 'wayo_iab_dismissed';
			case 'cookie_policy.row_iab_dismissed_purpose': return 'يتذكّر أنك أغلقت تحذير المتصفح المدمج';
			case 'cookie_policy.row_iab_dismissed_duration': return '12 ساعة';
			case 'cookie_policy.row_app_install_name': return 'wayo_app_install_dismissed';
			case 'cookie_policy.row_app_install_purpose': return 'يتذكّر أنك أغلقت مطالبة تثبيت التطبيق على الهاتف';
			case 'cookie_policy.row_app_install_duration': return '7 أيام';
			case 'cookie_policy.row_analytics_name': return '_ga, _ga_* (Google Analytics)';
			case 'cookie_policy.row_analytics_purpose': return 'يجمع إحصاءات استخدام مجهولة (الصفحات التي زُرتها، مدة الجلسة، مصادر الزيارات). يُفعَّل فقط بموافقتك.';
			case 'cookie_policy.row_analytics_duration': return 'سنتان';
			case 'cookie_policy.row_stripe_name': return 'ملفات Stripe';
			case 'cookie_policy.row_stripe_purpose': return 'تُستخدم لمعالجة المدفوعات وكشف الاحتيال وعملية الدفع';
			case 'cookie_policy.row_stripe_duration': return 'من الجلسة إلى سنة واحدة';
			case 'cookie_policy.manage_title': return '5. إدارة تفضيلات ملفات تعريف الارتباط';
			case 'cookie_policy.manage_body': return 'عند أول زيارة لموقعنا، يظهر شريط ملفات تعريف الارتباط الذي يتيح لك قبول جميع الملفات، أو رفض غير الأساسية، أو تخصيص تفضيلاتك. يمكنك تغيير تفضيلاتك في أي وقت عبر رابط «إعدادات ملفات تعريف الارتباط» في تذييل الموقع. تسمح معظم المتصفحات أيضًا بالتحكم في الملفات من إعداداتها. يمكنك عادةً: حذف الملفات المخزّنة على جهازك؛ منع تعيين ملفات جديدة؛ تحديد تفضيلات لمواقع محددة؛ التصفح في وضع خاص/التصفح المتخفي. يرجى ملاحظة أن حظر الملفات الأساسية قد يضعف بعض ميزات الموقع.';
			case 'cookie_policy.changes_title': return '6. تغييرات على سياسة ملفات تعريف الارتباط';
			case 'cookie_policy.changes_body': return 'قد نحدّث هذه السياسة من وقت لآخر لتعكس تغييرات في ممارساتنا أو لأسباب تشغيلية أو قانونية أو تنظيمية. سننشر أي تغييرات على هذه الصفحة ونحدّث تاريخ «آخر تحديث».';
			case 'cookie_policy.contact_title': return '7. معلومات الاتصال';
			case 'cookie_policy.contact_body': return 'إذا كانت لديك أسئلة حول استخدامنا لملفات تعريف الارتباط أو هذه السياسة، يرجى التواصل معنا على info@wayo.cloud.';
			case 'app_settings.title': return 'التفضيلات';
			case 'app_settings.subtitle': return 'المظهر واللغة';
			case 'app_settings.section_appearance': return 'المظهر';
			case 'app_settings.section_language': return 'اللغة';
			case 'app_settings.theme_light': return 'فاتح';
			case 'app_settings.theme_dark': return 'داكن';
			case 'app_settings.theme_system': return 'النظام';
			case 'app_settings.theme_hint': return 'اختر مظهر Wayo Ads. يتبع المظهر إعدادات هاتفك.';
			case 'app_settings.language_hint': return 'يحدّد لغة الواجهة. تتكيّف التواريخ والتنسيقات مع اللغة المختارة.';
			case 'app_settings.design_variant': return 'أسلوب اللوحة';
			case 'app_settings.design_glass': return 'زجاج ناعم';
			case 'app_settings.design_corporate': return 'احترافي بسيط';
			case 'app_settings.close': return 'إغلاق';
			case 'app_settings.open_semantics': return 'فتح التفضيلات واللغة';
			case 'app_settings.close_semantics': return 'إغلاق التفضيلات';
			case 'app_settings.profile_fallback': return 'الحساب';
			case 'app_settings.selected': return 'محدد';
			case 'app_settings.lang_en': return 'English';
			case 'app_settings.lang_fr': return 'Français';
			case 'app_settings.lang_ar': return 'العربية';
			case 'app_settings.section_notifications': return 'الإشعارات';
			case 'app_settings.notifications_toggle': return 'إشعارات الدفع';
			case 'app_settings.notifications_hint': return 'تنبيهات الحملات والمحادثات والفواتير والمدفوعات. يتطلب إذنًا في إعدادات الهاتف.';
			case 'app_settings.notifications_status_enabled': return 'مفعّلة — ستصلك التنبيهات على هذا الجهاز';
			case 'app_settings.notifications_status_disabled': return 'معطّلة داخل التطبيق';
			case 'app_settings.notifications_status_permission_denied': return 'اسمح بالإشعارات من إعدادات الهاتف';
			case 'app_settings.notifications_open_settings': return 'فتح إعدادات الهاتف';
			case 'app_settings.notifications_enable_error': return 'تعذّر تفعيل الإشعارات. تحقق من إعدادات النظام.';
			case 'app_settings.notifications_update_error': return 'تعذّر تحديث إعدادات الإشعارات. أعد المحاولة.';
			case 'app_settings.notif_prefs_entry_title': return 'تفضيلات الإشعارات';
			case 'app_settings.notif_prefs_entry_sub': return 'القنوات والفئات للتنبيهات داخل التطبيق والبريد';
			case 'app_settings.notif_prefs_title': return 'تفضيلات الإشعارات';
			case 'app_settings.notif_prefs_channels_title': return 'القنوات';
			case 'app_settings.notif_prefs_channels_sub': return 'مفاتيح رئيسية لكيفية وصول Wayo إليك.';
			case 'app_settings.notif_prefs_categories_title': return 'الفئات';
			case 'app_settings.notif_prefs_categories_sub': return 'كتم أنواع معينة دون إيقاف الكل.';
			case 'app_settings.notif_prefs_in_app': return 'داخل التطبيق';
			case 'app_settings.notif_prefs_email': return 'البريد';
			case 'app_settings.notif_prefs_sound': return 'الصوت';
			case 'app_settings.notif_prefs_load_error': return 'تعذّر تحميل التفضيلات.';
			case 'app_settings.notif_prefs_error': return 'تعذّر الحفظ. أعد المحاولة.';
			case 'app_settings.notif_prefs_retry': return 'إعادة المحاولة';
			case 'app_settings.notif_cat_video': return 'الفيديوهات';
			case 'app_settings.notif_cat_applications': return 'الطلبات';
			case 'app_settings.notif_cat_payouts': return 'المدفوعات';
			case 'app_settings.notif_cat_wallet': return 'المحفظة';
			case 'app_settings.notif_cat_tokens': return 'الرموز';
			case 'app_settings.notif_cat_campaigns': return 'الحملات';
			case 'app_settings.notif_cat_security': return 'الأمان';
			case 'app_settings.export_data_title': return 'تنزيل بياناتي';
			case 'app_settings.export_data_sub': return 'تصدير نسخة JSON من حساب Wayo Ads';
			case 'app_settings.export_data_button': return 'تنزيل التصدير';
			case 'app_settings.export_data_progress': return 'جارٍ تجهيز التصدير…';
			case 'app_settings.export_data_success': return 'تم حفظ التصدير';
			case 'app_settings.export_data_error': return 'تعذّر تصدير بياناتك. أعد المحاولة.';
			case 'app_settings.passkeys_title': return 'مفاتيح المرور';
			case 'app_settings.passkeys_sub': return 'تسجيل دخول بدون كلمة مرور';
			case 'app_settings.passkeys_web_only': return 'إدارة مفاتيح المرور تُفتح بأمان عبر Auth Wayo داخل التطبيق.';
			case 'app_settings.passkeys_manage_hint': return 'أضف أو أزل مفاتيح المرور. تتم الإدارة عبر Auth Wayo (مطلوب لـ WebAuthn).';
			case 'app_settings.passkeys_open_manage': return 'إدارة مفاتيح المرور';
			case 'app_settings.connected_accounts_title': return 'الحسابات المرتبطة';
			case 'app_settings.connected_accounts_sub': return 'Google وApple المرتبطة بحساب Wayo';
			case 'app_settings.connected_accounts_web_only': return 'اربط أو ألغِ ربط Google/Apple عبر Auth Wayo في التطبيق.';
			case 'app_settings.connected_accounts_manage_hint': return 'اربط أو ألغِ ربط Google وApple في حساب Auth Wayo.';
			case 'app_settings.connected_accounts_open_manage': return 'إدارة الحسابات المرتبطة';
			case 'app_settings.handoff_error': return 'تعذّر فتح الإدارة الآمنة. سيتم فتح المتصفح.';
			case 'app_settings.open_web_settings': return 'فتح إعدادات الويب';
			case 'app_settings.guides_title': return 'الأدلة والموارد';
			case 'app_settings.guides_sub': return 'مقالات المساعدة وأدلة منتج Wayo Ads';
			case 'app_settings.section_account': return 'الحساب';
			case 'app_settings.section_security': return 'الأمان';
			case 'app_settings.sessions_title': return 'الجلسات النشطة';
			case 'app_settings.sessions_desc': return 'الأجهزة المتصلة حالياً بحسابك. ألغِ أي جلسة لا تعرفها.';
			case 'app_settings.sessions_empty': return 'لا توجد جلسات متصفح أخرى نشطة.';
			case 'app_settings.sessions_error_load': return 'تعذّر تحميل الجلسات النشطة.';
			case 'app_settings.sessions_error_revoke': return 'تعذّر إلغاء الجلسة. حاول مرة أخرى.';
			case 'app_settings.session_unknown_device': return 'جهاز غير معروف';
			case 'app_settings.session_this_device': return 'هذا الجهاز';
			case 'app_settings.session_last_active': return 'آخر نشاط';
			case 'app_settings.session_revoke': return 'إلغاء';
			case 'app_settings.session_revoking': return 'جارٍ الإلغاء…';
			case 'app_settings.session_revoke_others': return 'تسجيل الخروج من الأجهزة الأخرى';
			case 'app_settings.session_revoke_confirm_title': return 'إلغاء الجلسة؟';
			case 'app_settings.session_revoke_confirm_desc': return 'سيتم تسجيل خروج هذا الجهاز في طلبه التالي.';
			case 'app_settings.session_revoke_others_confirm_title': return 'تسجيل الخروج من الأجهزة الأخرى؟';
			case 'app_settings.session_revoke_others_confirm_desc': return 'سيتم إغلاق جميع جلسات المتصفح الأخرى. يبقى هذا الهاتف متصلاً.';
			case 'app_settings.session_revoke_confirm': return 'إلغاء';
			case 'app_settings.session_revoke_cancel': return 'إلغاء';
			case 'app_settings.delete_account_entry': return 'حذف الحساب';
			case 'app_settings.delete_account_entry_sub': return 'فترة سماح 30 يومًا — من داخل التطبيق';
			case 'app_settings.delete_account_manage': return 'عرض تفاصيل الحذف';
			case 'app_settings.section_about': return 'حول التطبيق';
			case 'app_settings.rate_app': return 'قيّم Wayo Ads';
			case 'app_settings.rate_app_sub': return 'افتح App Store أو Google Play';
			case 'app_settings.rate_app_error': return 'تعذّر فتح المتجر. أعِد المحاولة بعد لحظات.';
			case 'app_settings.devices_nav_title': return 'أجهزة الثقة';
			case 'app_settings.devices_title': return 'الأجهزة الموثوقة';
			case 'app_settings.devices_desc': return 'الأجهزة المسموح لها بالاتصال بحسابك. انسَ أي جهاز لا تعرفه.';
			case 'app_settings.devices_empty': return 'لا توجد أجهزة موثوقة مسجلة.';
			case 'app_settings.devices_error_load': return 'تعذر تحميل الأجهزة الموثوقة.';
			case 'app_settings.devices_error_revoke': return 'تعذر نسيان الجهاز. حاول مرة أخرى.';
			case 'app_settings.device_unknown_device': return 'جهاز غير معروف';
			case 'app_settings.device_this_device': return 'هذا الجهاز';
			case 'app_settings.device_forget': return 'انسَ';
			case 'app_settings.device_revoking': return 'جارٍ النسيان…';
			case 'app_settings.device_revoke_confirm_title': return 'نسيان هذا الجهاز؟';
			case 'app_settings.device_revoke_confirm_desc': return 'سيتم إزالة هذا الجهاز من قائمة الثقة. ستحتاج إلى إعادة الموافقة عليه عند تسجيل الدخول التالي.';
			case 'app_settings.device_revoke_confirm': return 'انسَ';
			case 'app_settings.device_revoke_cancel': return 'إلغاء';
			case 'app_settings.device_revoked': return 'تم نسيان الجهاز.';
			case 'profile.nav_title': return 'الملف الشخصي';
			case 'profile.entry_title': return 'تعديل الملف الشخصي';
			case 'profile.entry_sub': return 'الصورة، الاسم المعروض ومعلومات الحساب';
			case 'profile.section_info_title': return 'معلومات الملف الشخصي';
			case 'profile.section_info_desc': return 'حدّث معلوماتك الشخصية وصورة ملفك.';
			case 'profile.section_details_title': return 'تفاصيل الحساب';
			case 'profile.section_details_desc': return 'معلومات حسابك وأدوارك.';
			case 'profile.display_name': return 'الاسم المعروض';
			case 'profile.display_name_hint': return 'كيف يراك الآخرون على Wayo Ads';
			case 'profile.display_name_required': return 'الاسم المعروض مطلوب';
			case 'profile.save_changes': return 'حفظ التغييرات';
			case 'profile.saving': return 'جارٍ الحفظ…';
			case 'profile.saved': return 'تم تحديث الملف الشخصي';
			case 'profile.save_error': return 'تعذّر حفظ الملف الشخصي. أعِد المحاولة.';
			case 'profile.load_error': return 'تعذّر تحميل الملف الشخصي.';
			case 'profile.name_taken': return 'هذا الاسم مستخدم بالفعل. يُرجى اختيار اسم آخر.';
			case 'profile.name_invalid': return 'يمزج هذا الاسم أحرفًا من أبجديات مختلفة، وهذا غير مسموح.';
			case 'profile.avatar_upload': return 'رفع صورة';
			case 'profile.avatar_remove': return 'إزالة';
			case 'profile.avatar_hint': return 'JPG أو PNG أو GIF — بحد أقصى 500 ك.ب';
			case 'profile.avatar_pick_error': return 'تعذّر اختيار الصورة.';
			case 'profile.avatar_too_large': return 'الصورة كبيرة جدًا (الحد 500 ك.ب).';
			case 'profile.email': return 'البريد الإلكتروني';
			case 'profile.roles': return 'الأدوار';
			case 'profile.member_since': return 'عضو منذ';
			case 'profile.role_creator': return 'منشئ محتوى';
			case 'profile.role_advertiser': return 'معلن';
			case 'profile.role_user': return 'مستخدم';
			case 'security.nav_title': return 'الأمان';
			case 'security.entry_title': return 'كلمة المرور والجلسات';
			case 'security.entry_sub': return 'تغيير كلمة المرور وإدارة الأجهزة المتصلة';
			case 'security.change_password_title': return 'تغيير كلمة المرور';
			case 'security.password_management_title': return 'كلمة المرور';
			case 'security.current_password': return 'كلمة المرور الحالية';
			case 'security.new_password': return 'كلمة المرور الجديدة';
			case 'security.confirm_password': return 'تأكيد كلمة المرور';
			case 'security.update_password': return 'تحديث كلمة المرور';
			case 'security.updating_password': return 'جاري التحديث…';
			case 'security.password_updated': return 'تم تحديث كلمة المرور.';
			case 'security.password_oauth_message': return 'سجّلت الدخول عبر Google أو Apple. إدارة كلمة المرور تتم عبر مزودك. لتغييرها، استخدم إعدادات حساب Google أو Apple.';
			case 'security.all_fields_required': return 'جميع الحقول مطلوبة.';
			case 'security.password_min_length': return '8 أحرف على الأقل.';
			case 'security.password_same_as_current': return 'يجب أن تختلف كلمة المرور الجديدة عن الحالية.';
			case 'security.password_wrong_current': return 'كلمة المرور الحالية غير صحيحة.';
			case 'security.password_change_error': return 'تعذّر تحديث كلمة المرور. حاول مرة أخرى.';
			case 'account_deletion.nav_title': return 'حذف الحساب';
			case 'account_deletion.title': return 'حذف حساب Wayo Ads';
			case 'account_deletion.danger_zone_chip': return 'منطقة الخطر';
			case 'account_deletion.danger_zone_intro': return 'يحذف حسابك وجميع البيانات المرتبطة به نهائيًا. بعد انتهاء فترة السماح لا يمكن التراجع عن ذلك.';
			case 'account_deletion.danger_what_title': return 'ما الذي سيُحذف:';
			case 'account_deletion.danger_item_profile': return 'ملفك الشخصي ومعلوماتك';
			case 'account_deletion.danger_item_campaigns': return 'جميع حملاتك وبيانات أدائها';
			case 'account_deletion.danger_item_business': return 'ملف عملك ومعلومات علامتك';
			case 'account_deletion.danger_item_wallet': return 'محفظتك كمعلن وسجل المعاملات';
			case 'account_deletion.danger_item_notifications': return 'إشعاراتك وتفضيلات البريد';
			case 'account_deletion.danger_item_access': return 'وصولك إلى Wayo Ads (لن تتمكن من تسجيل الدخول هنا مجددًا)';
			case 'account_deletion.danger_wayo_note': return 'يُتأثر فقط بيانات Wayo Ads. حساب Wayo (لتسجيل الدخول) يبقى نشطًا لخدمات Wayo الأخرى.';
			case 'account_deletion.subtitle_warning': return 'تنبيه: بعد 30 يومًا ستُحذف بيانات Wayo Ads نهائيًا. يمكنك الإلغاء في أي وقت قبل ذلك.';
			case 'account_deletion.bullet_loss': return 'الحملات والطلبات وبيانات الملف في التطبيق تُحذف بعد فترة السماح.';
			case 'account_deletion.bullet_wallet': return 'رصيد المحفظة والفواتير وسجل المعاملات المرتبطة بهذا الحساب تُزال.';
			case 'account_deletion.bullet_cancel': return 'نافذة إلغاء مجانية لمدة 30 يومًا من الطلب.';
			case 'account_deletion.bullet_recreate': return 'معرّف Wayo (تسجيل الدخول) لا يُحذف بهذه الخطوة — يمكنك تسجيل الدخول لاحقًا وبملف جديد.';
			case 'account_deletion.role_advertiser': return 'معلن: تتوقف الحملات النشطة عند مسح البيانات.';
			case 'account_deletion.role_creator': return 'مبدع: الطلبات والقنوات والأرباح في التطبيق تُحذف.';
			case 'account_deletion.continue_cta': return 'متابعة';
			case 'account_deletion.back': return 'رجوع';
			case 'account_deletion.more_info_title': return 'قبل المتابعة';
			case 'account_deletion.more_info_body': return 'رسائل البريد: تأكيد الآن، ثم تذكير قبل الحذف ببضعة أيام.\nالدعم: تواصل معنا لتصدير بياناتك أو إغلاق الحملات.';
			case 'account_deletion.step_auth_title': return 'تأكيد الهوية';
			case 'account_deletion.status_active': return 'لا يوجد حذف مجدول لهذا الحساب.';
			case 'account_deletion.status_pending': return ({required Object date}) => 'الحذف مجدول بالفعل. التاريخ النهائي: ${date}';
			case 'account_deletion.password_label': return 'كلمة المرور';
			case 'account_deletion.password_hint': return '8 أحرف على الأقل';
			case 'account_deletion.forgot_password': return 'نسيت كلمة المرور؟';
			case 'account_deletion.oauth_note': return 'إذا سجّلت الدخول فقط عبر Google أو Apple، عيّن كلمة مرور أولًا (نسيت كلمة المرور).';
			case 'account_deletion.oauth_deletion_intro': return 'تسجّل الدخول عبر Google أو Apple. لحمايتك، ستعيد المصادقة لدى مزوّدك قبل جدولة الحذف.';
			case 'account_deletion.oauth_deletion_step_hint': return 'تم التحقق من هويتك عند تسجيل الدخول بـ Google أو Apple. اضغط الزر أدناه لعرض ورقة التأكيد النهائية.';
			case 'account_deletion.oauth_reauth_intro': return 'لحمايتك، أكّد هويتك بإعادة تسجيل الدخول عبر المزوّد الذي تستخدمه مع Wayo Ads. ستتم جدولة الحذف مباشرةً بعد ذلك.';
			case 'account_deletion.oauth_reauth_google': return 'إعادة المصادقة عبر Google';
			case 'account_deletion.oauth_reauth_apple': return 'إعادة المصادقة عبر Apple';
			case 'account_deletion.oauth_reauth_cancelled': return 'تم إلغاء إعادة المصادقة.';
			case 'account_deletion.oauth_reauth_failed': return 'فشلت إعادة المصادقة. يُرجى المحاولة مرة أخرى.';
			case 'account_deletion.oauth_reauth_mismatch': return 'يُرجى إعادة المصادقة بنفس الحساب الذي تستخدمه مع Wayo Ads.';
			case 'account_deletion.error_reauth_required': return 'إعادة المصادقة مطلوبة لحذف حسابك. يُرجى تسجيل الدخول مجددًا عبر مزوّدك.';
			case 'account_deletion.legal_recap': return ({required Object date}) => 'ستبدأ فترة سماح 30 يومًا قبل الحذف النهائي. يمكنك الإلغاء حتى ${date}.';
			case 'account_deletion.next_review': return 'مراجعة وتأكيد';
			case 'account_deletion.dialog_title': return 'هل أنت متأكد؟';
			case 'account_deletion.dialog_body': return 'ستُجدول بيانات Wayo Ads للحذف. الحذف النهائي في:';
			case 'account_deletion.dialog_cancel_hint': return 'يمكنك الإلغاء في أي وقت من الإعدادات حتى ذلك التاريخ.';
			case 'account_deletion.timeline_request': return 'الطلب';
			case 'account_deletion.timeline_reminder': return 'تذكير بالبريد';
			case 'account_deletion.timeline_purge': return 'الحذف';
			case 'account_deletion.dialog_confirm': return 'نعم، جدولة الحذف';
			case 'account_deletion.dialog_dismiss': return 'الإبقاء على حسابي';
			case 'account_deletion.success_title': return 'تم جدولة الحذف';
			case 'account_deletion.success_intro': return 'ماذا يحدث الآن؟';
			case 'account_deletion.success_use_until': return 'يمكنك مواصلة استخدام Wayo Ads حتى التاريخ النهائي.';
			case 'account_deletion.success_reminder': return 'سنرسل تذكيرًا قبل الحذف بأيام قليلة.';
			case 'account_deletion.success_cancel_anytime': return 'ألغِ في أي وقت من هذه الشاشة أو الإعدادات.';
			case 'account_deletion.days_left': return ({required Object n}) => 'الأيام المتبقية: ${n}';
			case 'account_deletion.purge_date': return ({required Object date}) => 'الحذف النهائي: ${date}';
			case 'account_deletion.reminder_approx': return ({required Object date}) => 'تذكير تقريبي: ${date}';
			case 'account_deletion.cancel_request': return 'إلغاء الحذف';
			case 'account_deletion.go_home': return 'العودة للرئيسية';
			case 'account_deletion.toast_cancelled': return 'أُلغي الحذف. عُاد حسابك.';
			case 'account_deletion.error_load': return 'تعذر تحميل حالة الحساب.';
			case 'account_deletion.error_load_unauthorized': return 'تعذر التحقق من جلستك مع Wayo Ads. سجّل الخروج ثم الدخول مجددًا وأعد المحاولة.';
			case 'account_deletion.error_load_network': return 'تحقق من الاتصال وإمكانية الوصول إلى Wayo Ads، ثم أعد المحاولة.';
			case 'account_deletion.error_delete': return 'حدث خطأ. حاول مجددًا.';
			case 'account_deletion.error_password': return 'كلمة مرور غير صحيحة. أعد المحاولة أو أعد التعيين.';
			case 'account_deletion.error_superadmin': return 'لا يمكن لحسابات المشرف الأعلى طلب الحذف.';
			case 'account_deletion.funds_warning': return 'تنبيه: سيتم حذف رصيد محفظتك وأي طلبات سحب معلّقة نهائيًا. اسحب أموالك قبل التأكيد.';
			case 'account_deletion.banner_line': return ({required Object date, required Object n}) => 'سيُحذف حسابك في ${date} (${n} يومًا متبقيًا).';
			case 'account_deletion.banner_cancel_dialog_title': return 'إلغاء الحذف المجدول؟';
			case 'account_deletion.banner_cancel_dialog_body': return 'يظل ملف Wayo Ads نشطًا.';
			case 'account_deletion.banner_cancel_dialog_confirm': return 'الإبقاء على حسابي';
			case 'account_deletion.pending_danger_card_body': return ({required Object date}) => 'حُدد حسابك للحذف النهائي في ${date}. يمكنك إلغاء هذا الطلب في أي وقت قبل ذلك.';
			case 'account_deletion.pending_scheduled_status': return 'حذف الحساب مجدول';
			case 'account_deletion.pending_days_remaining_one': return 'يوم واحد متبقي';
			case 'account_deletion.pending_days_remaining_plural': return ({required Object n}) => '${n} يومًا متبقيًا';
			case 'onboarding.role_gate_title': return 'اختر ملفك';
			case 'onboarding.role_gate_subtitle': return 'نفس الخطوة كما على موقع Wayo Ads قبل استخدام التطبيق.';
			case 'onboarding.role_creator_cta': return 'مبدع';
			case 'onboarding.role_creator_desc': return 'تصفح الحملات وتقدّم وتعاون مع العلامات.';
			case 'onboarding.role_advertiser_cta': return 'معلن';
			case 'onboarding.role_advertiser_desc': return 'أطلق الحملات وأدر المبدعين من لوحة التحكم.';
			case 'onboarding.email_code_title': return 'تأكيد البريد';
			case 'onboarding.email_code_subtitle': return ({required Object email}) => 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى ${email}.';
			case 'onboarding.email_code_subtitle_prefix': return 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى ';
			case 'onboarding.email_code_subtitle_suffix': return '.';
			case 'onboarding.email_code_hide_my_email_warning': return 'سجّلت الدخول بخيار إخفاء بريدي الإلكتروني من Apple. غالبًا لا تصل رموز التحقق إلى عناوين التوجيه. سجّل الخروج، ثم سجّل الدخول مجددًا عبر Apple واختر مشاركة بريدي الإلكتروني، أو استخدم بريد iCloud الحقيقي مع كلمة المرور.';
			case 'onboarding.email_code_otp_label': return 'أدخل رمز التحقق';
			case 'onboarding.email_code_sending': return 'جارٍ إرسال الرمز...';
			case 'onboarding.email_code_verifying': return 'جارٍ التحقق...';
			case 'onboarding.skip': return 'تخطي';
			case 'onboarding.next': return 'التالي';
			case 'onboarding.done': return 'حسنًا';
			case 'onboarding.advertiser.dashboard_title': return 'لوحة التحكم';
			case 'onboarding.advertiser.dashboard_subtitle': return 'تابع رصيدك وحملاتك النشطة وإشعاراتك — كل التحديثات تصل فورًا.';
			case 'onboarding.advertiser.campaigns_title': return 'الحملات';
			case 'onboarding.advertiser.campaigns_subtitle': return 'أنشئ حملات جديدة، راجع الطلبات وراقب الأداء من مكان واحد.';
			case 'onboarding.advertiser.wallet_title': return 'المحفظة';
			case 'onboarding.advertiser.wallet_subtitle': return 'اشحن ميزانية رصيدك وتابع الإنفاق — محمي عبر Stripe.';
			case 'onboarding.advertiser.invoices_title': return 'الفواتير';
			case 'onboarding.advertiser.invoices_subtitle': return 'حمّل ملفات PDF المعتمدة للإيداعات وفوترة الحملات والتحويلات — كل ذلك في مكان واحد.';
			case 'onboarding.advertiser.chat_title': return 'الدردشة';
			case 'onboarding.advertiser.chat_subtitle': return 'تحدث مع المبدعين بعد اعتماد الحملة. محادثاتك متزامنة على جميع أجهزتك.';
			case 'onboarding.creator.dashboard_title': return 'لوحة المبدع';
			case 'onboarding.creator.dashboard_subtitle': return 'مؤشراتك الرئيسية وطلباتك النشطة وأرباحك تتحدث تلقائيًا دون الحاجة للتحديث اليدوي.';
			case 'onboarding.creator.campaigns_title': return 'تصفح وقدّم طلبك';
			case 'onboarding.creator.campaigns_subtitle': return 'اكتشف الحملات المتاحة، قدّم بنقرة واحدة وتابع حالة طلبك مباشرة.';
			case 'onboarding.creator.wallet_title': return 'الأرباح والسحوبات';
			case 'onboarding.creator.wallet_subtitle': return 'اطّلع على رصيدك واطلب تحويلاً عبر Stripe Connect واستعرض سحوباتك السابقة.';
			case 'onboarding.creator.invoices_title': return 'إيصالات الدفع';
			case 'onboarding.creator.invoices_subtitle': return 'صفِّ الأرباح والتحويلات، وحمّل ملفات PDF المعتمدة أو أرشيف ZIP — يُحدَّث تلقائياً أثناء استخدام التطبيق.';
			case 'onboarding.creator.chat_title': return 'تحدث مع المعلن';
			case 'onboarding.creator.chat_subtitle': return 'فور الاعتماد، تُفتح الدردشة للتنسيق مع المعلن حول المخرجات.';
			default: return null;
		}
	}
}

