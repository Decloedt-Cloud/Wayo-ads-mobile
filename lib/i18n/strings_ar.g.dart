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
	@override late final _TranslationsLoginAr login = _TranslationsLoginAr._(_root);
	@override late final _TranslationsForgotPasswordAr forgot_password = _TranslationsForgotPasswordAr._(_root);
	@override late final _TranslationsOtpAr otp = _TranslationsOtpAr._(_root);
	@override late final _TranslationsResetPasswordAr reset_password = _TranslationsResetPasswordAr._(_root);
	@override late final _TranslationsValidationAr validation = _TranslationsValidationAr._(_root);
	@override late final _TranslationsHomeAr home = _TranslationsHomeAr._(_root);
	@override late final _TranslationsDashboardAr dashboard = _TranslationsDashboardAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsAr advertiser_campaigns = _TranslationsAdvertiserCampaignsAr._(_root);
	@override late final _TranslationsNavAr nav = _TranslationsNavAr._(_root);
	@override late final _TranslationsChatAr chat = _TranslationsChatAr._(_root);
	@override late final _TranslationsCommonAr common = _TranslationsCommonAr._(_root);
	@override late final _TranslationsErrorsAr errors = _TranslationsErrorsAr._(_root);
	@override late final _TranslationsPrivacyPolicyAr privacy_policy = _TranslationsPrivacyPolicyAr._(_root);
	@override late final _TranslationsAppSettingsAr app_settings = _TranslationsAppSettingsAr._(_root);
}

// Path: login
class _TranslationsLoginAr extends TranslationsLoginEn {
	_TranslationsLoginAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get brand => 'وايو أدز';
	@override String get headline_line1 => 'مرحبًا بك';
	@override String get headline_line2_prefix => 'في ';
	@override String get headline_brand => 'وايو';
	@override String get subtitle => 'سجّل الدخول بحساب Wayo ID لإدارة حملاتك وتعاوناتك.';
	@override String get cta => 'تسجيل الدخول عبر وايو';
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
	@override String get google_not_configured => 'لم يُضبط تسجيل الدخول عبر Google. أضف AUTH_GOOGLE_SERVER_CLIENT_ID في dart_defines.json (معرّف عميل الويب من Google ينتهي بـ .apps.googleusercontent.com) ثم أعد تشغيل التطبيق بالكامل.';
	@override String get google_wrong_client_id => 'يجب أن يكون AUTH_GOOGLE_SERVER_CLIENT_ID هو معرّف عميل الويب في Google Cloud (…apps.googleusercontent.com) وليس UUID عميل OAuth في Passport.';
	@override String get google_failed => 'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.';
	@override String get google_channel_restart => 'انقطع اتصال Google مع أندرويد (غالبًا بعد hot restart). أوقف التطبيق بالكامل ثم شغّله من جديد — لا تستخدم hot restart.';
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
	@override String get theme_toggle_tooltip => 'التبديل بين الوضع الفاتح والداكن';
}

// Path: advertiser_campaigns
class _TranslationsAdvertiserCampaignsAr extends TranslationsAdvertiserCampaignsEn {
	_TranslationsAdvertiserCampaignsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الحملات';
	@override String get subtitle => 'تابع أداء حملاتك — عرض فقط.';
	@override late final _TranslationsAdvertiserCampaignsTabsAr tabs = _TranslationsAdvertiserCampaignsTabsAr._(_root);
	@override String get search_placeholder => 'ابحث عن حملة';
	@override late final _TranslationsAdvertiserCampaignsEmptyAr empty = _TranslationsAdvertiserCampaignsEmptyAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsCardAr card = _TranslationsAdvertiserCampaignsCardAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsStatusAr status = _TranslationsAdvertiserCampaignsStatusAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsPlatformAr platform = _TranslationsAdvertiserCampaignsPlatformAr._(_root);
	@override late final _TranslationsAdvertiserCampaignsDetailAr detail = _TranslationsAdvertiserCampaignsDetailAr._(_root);
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
	@override String get composer_hint => 'اكتب رسالة…';
	@override String get typing => 'يكتب…';
	@override String get error_load_threads => 'تعذّر تحميل محادثاتك. أعد المحاولة.';
	@override String get error_phone => 'مشاركة أرقام الهاتف في الدردشة غير مسموحة.';
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
	@override String get conversation_open_failed => 'تعذّر فتح هذه المحادثة. حاول مرة أخرى.';
	@override String get file_picker_restart_hint => 'المرفقات تحتاج إعادة تشغيل كاملة للتطبيق بعد التحديثات. أوقف التطبيق ثم شغّله من جديد (تجنّب hot restart).';
	@override String get attachment_type_not_allowed => 'يُسمح فقط بالصور (JPG أو PNG أو GIF أو WebP أو BMP) أو ملفات PDF.';
	@override String get inbox_swipe_soon => 'التثبيت والأرشفة من القائمة ستتوفر قريبًا.';
	@override String get date_today => 'اليوم';
	@override String get date_yesterday => 'أمس';
	@override String get bubble_reply => 'رد';
	@override String get bubble_copy => 'نسخ';
	@override String get bubble_react => 'تفاعل';
	@override String get bubble_delete => 'حذف';
	@override String get bubble_delete_unavailable => 'حذف الرسائل من التطبيق غير متاح بعد.';
	@override String get bubble_copied => 'تم النسخ إلى الحافظة';
	@override String get scroll_to_latest => 'الأحدث';
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
	@override String get intro_title => '1. مقدمة';
	@override String get intro_body => 'في Wayo Ads نلتزم بجمع بياناتك واستخدامها بمسؤولية، وفقًا للقوانين المعمول بها لحماية البيانات، بما في ذلك القانون المغربي رقم 09-08 وعند الاقتضاء اللائحة العامة لحماية البيانات (GDPR) (الاتحاد الأوروبي 2016/679). باستخدامك منصتنا، فإنك توافق على جمع بياناتك ومعالجتها واستخدامها كما هو موضح في سياسة الخصوصية هذه.';
	@override String get data_title => '2. البيانات التي نجمعها';
	@override String get data_body => 'نجمع فقط البيانات الضرورية، وفقًا للقانون 09-08 وعند الاقتضاء اللائحة العامة لحماية البيانات.\n\nللمعلنين\n• التعريف وبيانات الاتصال: اسم الشركة، البريد الإلكتروني، رقم الهاتف.\n• الملف الشخصي: شعار الشركة (إن وُجد)، وصف النشاط.\n• الحملات: محتوى الحملات، الميزانيات، معايير الاستهداف، بيانات التحليلات.\n\nللمبدعين\n• التعريف وبيانات الاتصال: الاسم، البريد الإلكتروني، رقم الهاتف.\n• الملف الشخصي: صورة الملف (إن وُجدت)، السيرة، الخبرات، روابط وسائل التواصل.\n• المحتوى: الفيديوهات والمنشورات والمواد التي ترفعها.\n• بيانات الاستخدام: التفاعل مع المنصة، إحصاءات التفاعل، بيانات الأرباح.\n\nمعلومات تقنية (جميع المستخدمين)\n• بيانات تقنية: عنوان IP، نوع المتصفح وإصداره، نوع الجهاز، نظام التشغيل، معرّفات الجلسة، الطوابع الزمنية، الصفحات التي زرتها، النقرات، المصادر الإحالة.\n• ملفات تعريف الارتباط وتقنيات مشابهة: انظر القسم 8 (ملفات تعريف الارتباط).\n\nبيانات الدفع\n• المعاملات: المبالغ، العملة، التاريخ، وسيلة الدفع، عنوان الفوترة.\n• هام: تُعالج بيانات البطاقة حصريًا عبر مزود الدفع (Stripe). لا تخزّن Wayo Ads معلومات بطاقة الائتمان.';
	@override String get purpose_title => '3. أغراض استخدام بياناتك';
	@override String get purpose_body => 'نستخدم بياناتك من أجل: تقديم خدماتنا وصيانتها وتحسينها؛ تخصيص التجربة واقتراح محتوى مناسب؛ إدارة العلاقات التعاقدية (الحسابات، الفوترة، الدعم)؛ إبلاغك بمعلومات الخدمة (التحديثات، التغييرات، التنبيهات)؛ ضمان أمان المنصة وسلامتها (اكتشاف إساءة الاستخدام والاحتيال)؛ وإجراء تحليلات للاستخدام ببيانات مجمّعة أو مجهولة المصدر قدر الإمكان.';
	@override String get legal_bases_title => '4. الأسس القانونية للمعالجة';
	@override String get legal_bases_body => 'بحسب الحالة، نعتمد على: موافقتك (مثل ملفات تعريف الارتباط غير الضرورية، النشرات الإخبارية)؛ تنفيذ عقد أو إجراءات ما قبل تعاقدية (مثل التسجيل، الفوترة)؛ الامتثال لالتزام قانوني (مثل الاحتفاظ بالفواتير)؛ ومصلحتنا المشروعة (مثل الأمان، تحسين الخدمة).';
	@override String get sharing_title => '5. مشاركة معلوماتك';
	@override String get sharing_body => 'لا تبيع Wayo Ads بياناتك الشخصية. قد يحدث مشاركة محدودة مع: مزودي خدمات أساسيين (معالجة الدفع، الاستضافة، البريد، التحليلات)؛ ولأسباب قانونية إذا طلب القانون ذلك أو استجابةً لطلب مشروع من جهة مختصة.';
	@override String get security_title => '6. أمن البيانات';
	@override String get security_body => 'نطبّق تدابير تشمل: تشفير TLS/HTTPS للبيانات أثناء النقل؛ ضوابط وصول وفق مبدأ «الحاجة للمعرفة»؛ نسخ احتياطي منتظم وإجراءات استعادة؛ تحديثات أمنية وتدقيقات دورية؛ وتسجيل واكتشاف الأنشطة غير الاعتيادية.';
	@override String get content_title => '7. مسؤوليات المستخدمين وحماية المحتوى';
	@override String get content_body => 'يجب احترام حقوق الملكية الفكرية للمبدعين ولـ Wayo Ads. لا تنسخ أو تشارك أو تعيد توزيع أو تعيد بيع المحتوى دون إذن. قد يؤدي أي خرق إلى تعليق الحساب وإجراءات قانونية عند الاقتضاء.';
	@override String get cookies_title => '8. ملفات تعريف الارتباط وتقنيات التتبع';
	@override String get cookies_body => 'نستخدم: ملفات تعريف ارتباط ضرورية (تشغيل الموقع، الأمان، الجلسة)؛ وملفات تحليلية (مثل Google Analytics) لقياس الجمهور. لا تُفعّل ملفات غير الضرورية إلا بموافقتك عبر شريط ملفات تعريف الارتباط عند أول زيارة.';
	@override String get retention_title => '9. الاحتفاظ بالبيانات';
	@override String get retention_body => 'نحتفظ ببياناتك فقط للمدة اللازمة للأغراض الواردة هنا. تُحفظ بيانات الحساب طيلة عمر الحساب زائد أي مدة احتفاظ قانونية. تُحفظ بيانات المعاملات وفقًا لمتطلبات المحاسبة والضرائب.';
	@override String get children_title => '10. خصوصية الأطفال';
	@override String get children_body => 'خدماتنا غير موجّهة لمن دون 18 عامًا. لا نجمع عن قصد معلومات شخصية من أطفال. إذا علمنا أننا جمعنا بيانات طفل دون موافقة ولي الأمر، سنتخذ خطوات لحذفها.';
	@override String get changes_title => '11. تغييرات هذه السياسة';
	@override String get changes_body => 'قد نحدّث سياسة الخصوصية من وقت لآخر. سنُعلمك بأي تغييرات جوهرية بنشر السياسة الجديدة على هذه الصفحة وتحديث تاريخ «آخر تحديث».';
	@override String get contact_title => '12. معلومات الاتصال';
	@override String get contact_body => 'مسؤول المعالجة: Wayo، دبي، الإمارات العربية المتحدة.\nالبريد الإلكتروني: info@wayo.cloud\nالعنوان: R320 أم هرير 2، دبي، الإمارات العربية المتحدة.';
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
	@override String get theme_hint => 'اختر مظهر وايو أدز. «النظام» يتبع إعداد جهازك.';
	@override String get language_hint => 'لغة الواجهة. التواريخ والتنسيقات تتبع اللغة.';
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

// Path: advertiser_campaigns.tabs
class _TranslationsAdvertiserCampaignsTabsAr extends TranslationsAdvertiserCampaignsTabsEn {
	_TranslationsAdvertiserCampaignsTabsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get active => 'نشطة';
	@override String get paused => 'معلّقة';
	@override String get completed => 'مكتملة';
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
	@override String get spent => 'المنفق';
	@override String get cpc => 'CPC';
	@override String get valid_engagements => '{count} مشاهدة مُصدّقة';
}

// Path: advertiser_campaigns.status
class _TranslationsAdvertiserCampaignsStatusAr extends TranslationsAdvertiserCampaignsStatusEn {
	_TranslationsAdvertiserCampaignsStatusAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get active => 'نشطة';
	@override String get paused => 'معلّقة';
	@override String get completed => 'مكتملة';
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
	@override String get valid_views => 'مشاهدات مُصدّقة';
	@override String get approved_creators => 'منشئون معتمدون';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'login.brand': return 'وايو أدز';
			case 'login.headline_line1': return 'مرحبًا بك';
			case 'login.headline_line2_prefix': return 'في ';
			case 'login.headline_brand': return 'وايو';
			case 'login.subtitle': return 'سجّل الدخول بحساب Wayo ID لإدارة حملاتك وتعاوناتك.';
			case 'login.cta': return 'تسجيل الدخول عبر وايو';
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
			case 'login.google_not_configured': return 'لم يُضبط تسجيل الدخول عبر Google. أضف AUTH_GOOGLE_SERVER_CLIENT_ID في dart_defines.json (معرّف عميل الويب من Google ينتهي بـ .apps.googleusercontent.com) ثم أعد تشغيل التطبيق بالكامل.';
			case 'login.google_wrong_client_id': return 'يجب أن يكون AUTH_GOOGLE_SERVER_CLIENT_ID هو معرّف عميل الويب في Google Cloud (…apps.googleusercontent.com) وليس UUID عميل OAuth في Passport.';
			case 'login.google_failed': return 'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.';
			case 'login.google_channel_restart': return 'انقطع اتصال Google مع أندرويد (غالبًا بعد hot restart). أوقف التطبيق بالكامل ثم شغّله من جديد — لا تستخدم hot restart.';
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
			case 'dashboard.errors.load_balance': return 'تعذر تحميل الرصيد';
			case 'dashboard.errors.load_campaigns': return 'تعذر تحميل الحملات';
			case 'dashboard.errors.retry': return 'إعادة المحاولة';
			case 'dashboard.notifications_title': return 'الإشعارات';
			case 'dashboard.notifications_empty': return 'لا إشعارات';
			case 'dashboard.theme_toggle_tooltip': return 'التبديل بين الوضع الفاتح والداكن';
			case 'advertiser_campaigns.title': return 'الحملات';
			case 'advertiser_campaigns.subtitle': return 'تابع أداء حملاتك — عرض فقط.';
			case 'advertiser_campaigns.tabs.active': return 'نشطة';
			case 'advertiser_campaigns.tabs.paused': return 'معلّقة';
			case 'advertiser_campaigns.tabs.completed': return 'مكتملة';
			case 'advertiser_campaigns.search_placeholder': return 'ابحث عن حملة';
			case 'advertiser_campaigns.empty.none': return 'لا توجد حملات';
			case 'advertiser_campaigns.empty.hint': return 'لا توجد لديك حملات بهذه الحالة بعد.';
			case 'advertiser_campaigns.empty.search': return 'لا نتائج مطابقة للبحث';
			case 'advertiser_campaigns.empty.search_hint': return 'جرّب اسماً مختلفاً أو امسح البحث.';
			case 'advertiser_campaigns.card.budget_total': return 'الميزانية';
			case 'advertiser_campaigns.card.remaining': return 'المتبقي';
			case 'advertiser_campaigns.card.spent': return 'المنفق';
			case 'advertiser_campaigns.card.cpc': return 'CPC';
			case 'advertiser_campaigns.card.valid_engagements': return '{count} مشاهدة مُصدّقة';
			case 'advertiser_campaigns.status.active': return 'نشطة';
			case 'advertiser_campaigns.status.paused': return 'معلّقة';
			case 'advertiser_campaigns.status.completed': return 'مكتملة';
			case 'advertiser_campaigns.status.draft': return 'مسودة';
			case 'advertiser_campaigns.status.other': return 'أخرى';
			case 'advertiser_campaigns.platform.youtube': return 'YouTube';
			case 'advertiser_campaigns.platform.tiktok': return 'TikTok';
			case 'advertiser_campaigns.platform.instagram': return 'Instagram';
			case 'advertiser_campaigns.platform.other': return 'منصة';
			case 'advertiser_campaigns.detail.fallback_title': return 'حملة';
			case 'advertiser_campaigns.detail.metrics_title': return 'الأداء';
			case 'advertiser_campaigns.detail.valid_views': return 'مشاهدات مُصدّقة';
			case 'advertiser_campaigns.detail.approved_creators': return 'منشئون معتمدون';
			case 'nav.dashboard': return 'لوحة التحكم';
			case 'nav.campaigns': return 'الحملات';
			case 'nav.analytics': return 'التحليلات';
			case 'nav.wallet': return 'المحفظة';
			case 'nav.chat': return 'المحادثات';
			case 'chat.inbox_title': return 'الرسائل';
			case 'chat.inbox_subtitle': return 'محادثات آمنة لحملاتك';
			case 'chat.conversation_unknown': return 'محادثة';
			case 'chat.thread_fallback_title': return 'محادثة';
			case 'chat.composer_hint': return 'اكتب رسالة…';
			case 'chat.typing': return 'يكتب…';
			case 'chat.error_load_threads': return 'تعذّر تحميل محادثاتك. أعد المحاولة.';
			case 'chat.error_phone': return 'مشاركة أرقام الهاتف في الدردشة غير مسموحة.';
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
			case 'chat.conversation_open_failed': return 'تعذّر فتح هذه المحادثة. حاول مرة أخرى.';
			case 'chat.file_picker_restart_hint': return 'المرفقات تحتاج إعادة تشغيل كاملة للتطبيق بعد التحديثات. أوقف التطبيق ثم شغّله من جديد (تجنّب hot restart).';
			case 'chat.attachment_type_not_allowed': return 'يُسمح فقط بالصور (JPG أو PNG أو GIF أو WebP أو BMP) أو ملفات PDF.';
			case 'chat.inbox_swipe_soon': return 'التثبيت والأرشفة من القائمة ستتوفر قريبًا.';
			case 'chat.date_today': return 'اليوم';
			case 'chat.date_yesterday': return 'أمس';
			case 'chat.bubble_reply': return 'رد';
			case 'chat.bubble_copy': return 'نسخ';
			case 'chat.bubble_react': return 'تفاعل';
			case 'chat.bubble_delete': return 'حذف';
			case 'chat.bubble_delete_unavailable': return 'حذف الرسائل من التطبيق غير متاح بعد.';
			case 'chat.bubble_copied': return 'تم النسخ إلى الحافظة';
			case 'chat.scroll_to_latest': return 'الأحدث';
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
			case 'privacy_policy.intro_title': return '1. مقدمة';
			case 'privacy_policy.intro_body': return 'في Wayo Ads نلتزم بجمع بياناتك واستخدامها بمسؤولية، وفقًا للقوانين المعمول بها لحماية البيانات، بما في ذلك القانون المغربي رقم 09-08 وعند الاقتضاء اللائحة العامة لحماية البيانات (GDPR) (الاتحاد الأوروبي 2016/679). باستخدامك منصتنا، فإنك توافق على جمع بياناتك ومعالجتها واستخدامها كما هو موضح في سياسة الخصوصية هذه.';
			case 'privacy_policy.data_title': return '2. البيانات التي نجمعها';
			case 'privacy_policy.data_body': return 'نجمع فقط البيانات الضرورية، وفقًا للقانون 09-08 وعند الاقتضاء اللائحة العامة لحماية البيانات.\n\nللمعلنين\n• التعريف وبيانات الاتصال: اسم الشركة، البريد الإلكتروني، رقم الهاتف.\n• الملف الشخصي: شعار الشركة (إن وُجد)، وصف النشاط.\n• الحملات: محتوى الحملات، الميزانيات، معايير الاستهداف، بيانات التحليلات.\n\nللمبدعين\n• التعريف وبيانات الاتصال: الاسم، البريد الإلكتروني، رقم الهاتف.\n• الملف الشخصي: صورة الملف (إن وُجدت)، السيرة، الخبرات، روابط وسائل التواصل.\n• المحتوى: الفيديوهات والمنشورات والمواد التي ترفعها.\n• بيانات الاستخدام: التفاعل مع المنصة، إحصاءات التفاعل، بيانات الأرباح.\n\nمعلومات تقنية (جميع المستخدمين)\n• بيانات تقنية: عنوان IP، نوع المتصفح وإصداره، نوع الجهاز، نظام التشغيل، معرّفات الجلسة، الطوابع الزمنية، الصفحات التي زرتها، النقرات، المصادر الإحالة.\n• ملفات تعريف الارتباط وتقنيات مشابهة: انظر القسم 8 (ملفات تعريف الارتباط).\n\nبيانات الدفع\n• المعاملات: المبالغ، العملة، التاريخ، وسيلة الدفع، عنوان الفوترة.\n• هام: تُعالج بيانات البطاقة حصريًا عبر مزود الدفع (Stripe). لا تخزّن Wayo Ads معلومات بطاقة الائتمان.';
			case 'privacy_policy.purpose_title': return '3. أغراض استخدام بياناتك';
			case 'privacy_policy.purpose_body': return 'نستخدم بياناتك من أجل: تقديم خدماتنا وصيانتها وتحسينها؛ تخصيص التجربة واقتراح محتوى مناسب؛ إدارة العلاقات التعاقدية (الحسابات، الفوترة، الدعم)؛ إبلاغك بمعلومات الخدمة (التحديثات، التغييرات، التنبيهات)؛ ضمان أمان المنصة وسلامتها (اكتشاف إساءة الاستخدام والاحتيال)؛ وإجراء تحليلات للاستخدام ببيانات مجمّعة أو مجهولة المصدر قدر الإمكان.';
			case 'privacy_policy.legal_bases_title': return '4. الأسس القانونية للمعالجة';
			case 'privacy_policy.legal_bases_body': return 'بحسب الحالة، نعتمد على: موافقتك (مثل ملفات تعريف الارتباط غير الضرورية، النشرات الإخبارية)؛ تنفيذ عقد أو إجراءات ما قبل تعاقدية (مثل التسجيل، الفوترة)؛ الامتثال لالتزام قانوني (مثل الاحتفاظ بالفواتير)؛ ومصلحتنا المشروعة (مثل الأمان، تحسين الخدمة).';
			case 'privacy_policy.sharing_title': return '5. مشاركة معلوماتك';
			case 'privacy_policy.sharing_body': return 'لا تبيع Wayo Ads بياناتك الشخصية. قد يحدث مشاركة محدودة مع: مزودي خدمات أساسيين (معالجة الدفع، الاستضافة، البريد، التحليلات)؛ ولأسباب قانونية إذا طلب القانون ذلك أو استجابةً لطلب مشروع من جهة مختصة.';
			case 'privacy_policy.security_title': return '6. أمن البيانات';
			case 'privacy_policy.security_body': return 'نطبّق تدابير تشمل: تشفير TLS/HTTPS للبيانات أثناء النقل؛ ضوابط وصول وفق مبدأ «الحاجة للمعرفة»؛ نسخ احتياطي منتظم وإجراءات استعادة؛ تحديثات أمنية وتدقيقات دورية؛ وتسجيل واكتشاف الأنشطة غير الاعتيادية.';
			case 'privacy_policy.content_title': return '7. مسؤوليات المستخدمين وحماية المحتوى';
			case 'privacy_policy.content_body': return 'يجب احترام حقوق الملكية الفكرية للمبدعين ولـ Wayo Ads. لا تنسخ أو تشارك أو تعيد توزيع أو تعيد بيع المحتوى دون إذن. قد يؤدي أي خرق إلى تعليق الحساب وإجراءات قانونية عند الاقتضاء.';
			case 'privacy_policy.cookies_title': return '8. ملفات تعريف الارتباط وتقنيات التتبع';
			case 'privacy_policy.cookies_body': return 'نستخدم: ملفات تعريف ارتباط ضرورية (تشغيل الموقع، الأمان، الجلسة)؛ وملفات تحليلية (مثل Google Analytics) لقياس الجمهور. لا تُفعّل ملفات غير الضرورية إلا بموافقتك عبر شريط ملفات تعريف الارتباط عند أول زيارة.';
			case 'privacy_policy.retention_title': return '9. الاحتفاظ بالبيانات';
			case 'privacy_policy.retention_body': return 'نحتفظ ببياناتك فقط للمدة اللازمة للأغراض الواردة هنا. تُحفظ بيانات الحساب طيلة عمر الحساب زائد أي مدة احتفاظ قانونية. تُحفظ بيانات المعاملات وفقًا لمتطلبات المحاسبة والضرائب.';
			case 'privacy_policy.children_title': return '10. خصوصية الأطفال';
			case 'privacy_policy.children_body': return 'خدماتنا غير موجّهة لمن دون 18 عامًا. لا نجمع عن قصد معلومات شخصية من أطفال. إذا علمنا أننا جمعنا بيانات طفل دون موافقة ولي الأمر، سنتخذ خطوات لحذفها.';
			case 'privacy_policy.changes_title': return '11. تغييرات هذه السياسة';
			case 'privacy_policy.changes_body': return 'قد نحدّث سياسة الخصوصية من وقت لآخر. سنُعلمك بأي تغييرات جوهرية بنشر السياسة الجديدة على هذه الصفحة وتحديث تاريخ «آخر تحديث».';
			case 'privacy_policy.contact_title': return '12. معلومات الاتصال';
			case 'privacy_policy.contact_body': return 'مسؤول المعالجة: Wayo، دبي، الإمارات العربية المتحدة.\nالبريد الإلكتروني: info@wayo.cloud\nالعنوان: R320 أم هرير 2، دبي، الإمارات العربية المتحدة.';
			case 'app_settings.title': return 'التفضيلات';
			case 'app_settings.subtitle': return 'المظهر واللغة';
			case 'app_settings.section_appearance': return 'المظهر';
			case 'app_settings.section_language': return 'اللغة';
			case 'app_settings.theme_light': return 'فاتح';
			case 'app_settings.theme_dark': return 'داكن';
			case 'app_settings.theme_system': return 'النظام';
			case 'app_settings.theme_hint': return 'اختر مظهر وايو أدز. «النظام» يتبع إعداد جهازك.';
			case 'app_settings.language_hint': return 'لغة الواجهة. التواريخ والتنسيقات تتبع اللغة.';
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
			default: return null;
		}
	}
}

