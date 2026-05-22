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
class TranslationsFr extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsFr _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsConnectivityFr connectivity = _TranslationsConnectivityFr._(_root);
	@override late final _TranslationsCampaignsExplorerFr campaigns_explorer = _TranslationsCampaignsExplorerFr._(_root);
	@override late final _TranslationsLoginFr login = _TranslationsLoginFr._(_root);
	@override late final _TranslationsVerifyEmailFr verify_email = _TranslationsVerifyEmailFr._(_root);
	@override late final _TranslationsForgotPasswordFr forgot_password = _TranslationsForgotPasswordFr._(_root);
	@override late final _TranslationsOtpFr otp = _TranslationsOtpFr._(_root);
	@override late final _TranslationsResetPasswordFr reset_password = _TranslationsResetPasswordFr._(_root);
	@override late final _TranslationsValidationFr validation = _TranslationsValidationFr._(_root);
	@override late final _TranslationsHomeFr home = _TranslationsHomeFr._(_root);
	@override late final _TranslationsDashboardFr dashboard = _TranslationsDashboardFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsFr advertiser_campaigns = _TranslationsAdvertiserCampaignsFr._(_root);
	@override late final _TranslationsNavFr nav = _TranslationsNavFr._(_root);
	@override late final _TranslationsInvoicesFr invoices = _TranslationsInvoicesFr._(_root);
	@override late final _TranslationsPushFr push = _TranslationsPushFr._(_root);
	@override late final _TranslationsCreatorFr creator = _TranslationsCreatorFr._(_root);
	@override late final _TranslationsAdvertiserWalletFr advertiser_wallet = _TranslationsAdvertiserWalletFr._(_root);
	@override late final _TranslationsChatFr chat = _TranslationsChatFr._(_root);
	@override late final _TranslationsCommonFr common = _TranslationsCommonFr._(_root);
	@override late final _TranslationsErrorsFr errors = _TranslationsErrorsFr._(_root);
	@override late final _TranslationsPrivacyPolicyFr privacy_policy = _TranslationsPrivacyPolicyFr._(_root);
	@override late final _TranslationsAppSettingsFr app_settings = _TranslationsAppSettingsFr._(_root);
	@override late final _TranslationsAccountDeletionFr account_deletion = _TranslationsAccountDeletionFr._(_root);
	@override late final _TranslationsOnboardingFr onboarding = _TranslationsOnboardingFr._(_root);
}

// Path: connectivity
class _TranslationsConnectivityFr extends TranslationsConnectivityEn {
	_TranslationsConnectivityFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get offline_title => 'Aucune connexion Internet';
	@override String get offline_subtitle => 'Vérifiez votre réseau puis réessayez.';
	@override String get reconnecting_title => 'Reconnexion…';
	@override String get reconnecting_subtitle => 'Nous essayons de rétablir votre connexion.';
	@override String get weak_title => 'Connexion faible';
	@override String get weak_subtitle => 'Certaines actions peuvent être plus lentes que d’habitude.';
	@override String get restored => 'Connexion rétablie';
	@override String get action_retry => 'Réessayer';
	@override String get action_settings => 'Réglages';
}

// Path: campaigns_explorer
class _TranslationsCampaignsExplorerFr extends TranslationsCampaignsExplorerEn {
	_TranslationsCampaignsExplorerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get filter_all_types => 'Tous les types';
	@override String get filter_all_platforms => 'Toutes les plateformes';
	@override String get filter_all_niches => 'Toutes les niches';
	@override String get filter_all_locations => 'Tous les lieux';
	@override String get platform_youtube => 'YouTube';
	@override String get platform_tiktok => 'TikTok';
	@override String get platform_instagram => 'Instagram';
	@override String get results_one => '1 campagne';
	@override String results_many({required Object n}) => '${n} campagnes';
	@override String get layout_grid => 'Grille';
	@override String get layout_list => 'Liste';
	@override String get empty_filters => 'Aucune campagne ne correspond à ces filtres.';
	@override String get empty_filters_subtitle => 'Retirez un filtre ou changez le type — les niches listées correspondent à vos autres choix.';
	@override String get search_aria => 'Rechercher des campagnes';
	@override String get reset_filters => 'Réinitialiser les filtres';
	@override String get toolbar_show_search_filters => 'Afficher recherche et filtres';
	@override String get toolbar_hide_search_filters => 'Masquer recherche et filtres';
	@override String get filter_label_type => 'Type';
	@override String get filter_label_status => 'Statut';
	@override String get filter_label_niche => 'Niche';
	@override String get filter_label_location => 'Lieu';
}

// Path: login
class _TranslationsLoginFr extends TranslationsLoginEn {
	_TranslationsLoginFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get brand => 'Wayo Ads';
	@override String get headline_line1 => 'Bienvenue';
	@override String get headline_line2_prefix => 'sur ';
	@override String get headline_brand => 'Wayo Ads';
	@override String get subtitle => 'Connectez-vous avec votre compte Wayo ID pour gérer vos campagnes et vos collaborations.';
	@override String get cta => 'Se connecter à Wayo Ads';
	@override String get secure_note => 'Authentification sécurisée via Wayo ID';
	@override String get terms_prefix => 'En continuant, vous acceptez nos ';
	@override String get terms => 'CGU';
	@override String get and => ' et ';
	@override String get privacy => 'Politique de confidentialité';
	@override String get dot => '.';
	@override String get email_label => 'Email';
	@override String get password_label => 'Mot de passe';
	@override String get show_password => 'Afficher';
	@override String get hide_password => 'Masquer';
	@override String get email_required => 'Email requis';
	@override String get email_invalid => 'Email invalide';
	@override String get password_required => 'Mot de passe requis';
	@override String get password_min => 'Au moins 6 caractères';
	@override String get rate_limit_title => 'Patience';
	@override String get rate_limit_body => 'Trop de tentatives de connexion.';
	@override String rate_limit_remaining({required Object seconds}) => 'Réessayez dans ${seconds} s';
	@override String get forgot_password_link => 'Mot de passe oublié ?';
	@override String get google_cta => 'Continuer avec Google';
	@override String get apple_cta => 'Se connecter avec Apple';
	@override String get apple_unavailable => 'Connexion avec Apple indisponible sur cet appareil.';
	@override String get apple_failed => 'Échec de la connexion avec Apple. Réessayez.';
	@override String get apple_canceled => 'Connexion avec Apple annulée.';
	@override String get google_not_configured => 'Connexion Google non configurée. Ajoutez AUTH_GOOGLE_SERVER_CLIENT_ID dans dart_defines.json (ID client Web Google se terminant par .apps.googleusercontent.com), puis redémarrez complètement l’app.';
	@override String get google_wrong_client_id => 'AUTH_GOOGLE_SERVER_CLIENT_ID doit être l’ID client Web Google Cloud (…apps.googleusercontent.com), pas l’UUID du client OAuth Passport.';
	@override String get google_failed => 'Échec de la connexion Google. Réessayez.';
	@override String get google_channel_restart => 'Connexion Google interrompue avec Android (souvent après un hot restart). Arrêtez complètement l’app puis Relancer — évitez le hot restart.';
	@override String get google_android_oauth_misconfigured => 'Google n’a pas pu vérifier l’app (code 10). Dans Google Cloud Console, même projet que l’ID client Web : ajoutez un client OAuth de type Android avec le package ma.wayo.wayoadsgo et l’empreinte SHA-1 du keystore (debug ou release), attendez quelques minutes puis réessayez.';
	@override String get session_expired_snack => 'Votre session a expiré. Veuillez vous reconnecter.';
}

// Path: verify_email
class _TranslationsVerifyEmailFr extends TranslationsVerifyEmailEn {
	_TranslationsVerifyEmailFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Confirmez votre email';
	@override String get subtitle => 'Wayo ID exige une adresse vérifiée (comme sur le site). Ouvrez le lien envoyé à :';
	@override String get check_again => 'C’est fait — continuer';
	@override String get open_mail => 'Ouvrir l’application mail';
	@override String get still_pending => 'Vérification toujours en attente. Vérifiez la boîte de réception ou les spams, puis réessayez.';
	@override String get open_mail_failed => 'Impossible d’ouvrir l’application mail.';
	@override String get sign_out => 'Se déconnecter';
}

// Path: forgot_password
class _TranslationsForgotPasswordFr extends TranslationsForgotPasswordEn {
	_TranslationsForgotPasswordFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Réinitialiser\nle mot de passe';
	@override String get subtitle => 'Entrez votre email Wayo. Nous vous enverrons un code à 6 chiffres.';
	@override String get email_label => 'Email';
	@override String get cta => 'Envoyer le code';
	@override String get rate_limit_title => 'Patience';
	@override String get rate_limit_body => 'Trop de demandes de réinitialisation. Réessayez dans un instant.';
	@override String rate_limit_remaining({required Object seconds}) => 'Réessayez dans ${seconds} s';
}

// Path: otp
class _TranslationsOtpFr extends TranslationsOtpEn {
	_TranslationsOtpFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vérifiez\nvotre email';
	@override String subtitle({required Object email}) => 'Saisissez le code envoyé à ${email}';
	@override String get resend => 'Renvoyer le code';
	@override String resend_in({required Object seconds}) => 'Renvoi dans ${seconds} s';
}

// Path: reset_password
class _TranslationsResetPasswordFr extends TranslationsResetPasswordEn {
	_TranslationsResetPasswordFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nouveau\nmot de passe';
	@override String get subtitle => 'Choisissez un mot de passe solide (min. 8 caractères, 1 majuscule, 1 chiffre).';
	@override String get new_password => 'Nouveau mot de passe';
	@override String get confirm_password => 'Confirmer le mot de passe';
	@override String get cta => 'Mettre à jour le mot de passe';
	@override String get password_updated => 'Mot de passe mis à jour. Vous pouvez vous connecter.';
}

// Path: validation
class _TranslationsValidationFr extends TranslationsValidationEn {
	_TranslationsValidationFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get required => 'Champ requis';
	@override String get invalid_email => 'Email invalide';
	@override String get min8 => 'Au moins 8 caractères';
	@override String get need_upper => 'Une majuscule est requise';
	@override String get need_digit => 'Un chiffre est requis';
	@override String get mismatch => 'Les mots de passe ne correspondent pas';
}

// Path: home
class _TranslationsHomeFr extends TranslationsHomeEn {
	_TranslationsHomeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wayo Ads';
	@override String get logout => 'Déconnexion';
	@override String get session_title => 'Session active';
	@override String get session_hint => 'Jeton Auth_Wayo stocké de façon sécurisée. Les appels API utilisent Authorization: Bearer automatiquement.';
	@override String get user_fallback => 'Utilisateur';
}

// Path: dashboard
class _TranslationsDashboardFr extends TranslationsDashboardEn {
	_TranslationsDashboardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tableau de bord';
	@override String get welcome => 'Bon retour, {name} !';
	@override String get welcome_fallback => 'Bon retour !';
	@override String get subtitle => 'Voici l’aperçu de vos campagnes.';
	@override String get account_creator => 'Compte créateur';
	@override String get account_advertiser => 'Compte annonceur';
	@override String get coming_soon => 'Bientôt disponible.';
	@override late final _TranslationsDashboardBalanceFr balance = _TranslationsDashboardBalanceFr._(_root);
	@override late final _TranslationsDashboardCampaignsFr campaigns = _TranslationsDashboardCampaignsFr._(_root);
	@override late final _TranslationsDashboardErrorsFr errors = _TranslationsDashboardErrorsFr._(_root);
	@override String get notifications_title => 'Notifications';
	@override String get notifications_empty => 'Aucune notification';
	@override String get notification_incoming => 'Nouvelle notification';
	@override String get notification_view => 'Voir';
	@override String get notifications_mark_all_read => 'Tout marquer comme lu';
	@override String get notifications_mark_read => 'Marquer comme lu';
	@override String get notifications_dismiss => 'Ignorer';
	@override String get notifications_view_all => 'Voir toutes les notifications';
	@override String get notifications_important => 'Important';
	@override String get notifications_earlier => 'Plus ancien';
	@override String get notifications_caught_up_title => 'Vous êtes à jour !';
	@override String get notifications_caught_up_subtitle => 'Aucune nouvelle notification';
	@override String get notifications_center_title => 'Centre de notifications';
	@override String get notifications_unread_count => '{count} notifications non lues';
	@override String get notifications_all_caught_up => 'Vous êtes à jour';
	@override String get notifications_tab_all => 'Tout';
	@override String get notifications_tab_archived => 'Archive';
	@override String get notifications_search_hint => 'Recherche de notifications…';
	@override String get notifications_filter_type_all => 'Tous les types';
	@override String get notifications_filter_priority_all => 'Toutes les priorités';
	@override String get notifications_priority_critical => 'Critique';
	@override String get notifications_priority_high => 'Haute';
	@override String get notifications_priority_normal => 'Normale';
	@override String get notifications_priority_low => 'Basse';
	@override String get notifications_load_more => 'Charger plus';
	@override String get notifications_view_details => 'Voir les détails';
	@override String get notifications_archive => 'Archiver';
	@override String get notifications_urgent => 'Urgent';
	@override String get notifications_just_now => 'À l\'instant';
	@override String get notifications_minutes_ago => 'Il y a {n} min';
	@override String get notifications_hours_ago => 'Il y a {n} h';
	@override String get notifications_days_ago => 'Il y a {n} j';
	@override String get notifications_section_all => 'Toutes les notifications';
	@override String get notifications_section_important => 'Alertes importantes';
	@override String get notifications_section_archived => 'Notifications archivées';
	@override String get application_approve => 'Approuver';
	@override String get application_reject => 'Refuser';
	@override String get application_approved => 'Candidature approuvée';
	@override String get application_rejected => 'Candidature refusée';
	@override String get application_action_failed => 'Impossible de mettre à jour la candidature. Réessayez.';
	@override String get theme_toggle_tooltip => 'Basculer entre thème clair et sombre';
	@override String get refresh => 'Actualiser le tableau de bord';
	@override String get shell_tour_restart => 'Revoir le tour d’onboarding';
	@override String get shell_tour_restart_hint => 'Relancer la visite guidée de la navigation Tableau de bord, Campagnes, Portefeuille et Messages';
}

// Path: advertiser_campaigns
class _TranslationsAdvertiserCampaignsFr extends TranslationsAdvertiserCampaignsEn {
	_TranslationsAdvertiserCampaignsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Campagnes';
	@override String get subtitle => 'Créez des campagnes brouillon, suivez les performances et examinez les candidatures.';
	@override late final _TranslationsAdvertiserCampaignsTabsFr tabs = _TranslationsAdvertiserCampaignsTabsFr._(_root);
	@override String get search_placeholder => 'Rechercher une campagne';
	@override late final _TranslationsAdvertiserCampaignsEmptyFr empty = _TranslationsAdvertiserCampaignsEmptyFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsCardFr card = _TranslationsAdvertiserCampaignsCardFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsStatusFr status = _TranslationsAdvertiserCampaignsStatusFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsPlatformFr platform = _TranslationsAdvertiserCampaignsPlatformFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsDetailFr detail = _TranslationsAdvertiserCampaignsDetailFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsCreateFr create = _TranslationsAdvertiserCampaignsCreateFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsApplicationsFr applications = _TranslationsAdvertiserCampaignsApplicationsFr._(_root);
}

// Path: nav
class _TranslationsNavFr extends TranslationsNavEn {
	_TranslationsNavFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get dashboard => 'Tableau de bord';
	@override String get campaigns => 'Campagnes';
	@override String get analytics => 'Analytique';
	@override String get wallet => 'Portefeuille';
	@override String get chat => 'Messages';
	@override String get invoices => 'Factures';
	@override String get invoices_creator => 'Relevés';
}

// Path: invoices
class _TranslationsInvoicesFr extends TranslationsInvoicesEn {
	_TranslationsInvoicesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Factures';
	@override String get title_creator => 'Relevés de paiement';
	@override String get subtitle_advertiser => 'Chaque dépôt et chaque budget campagne — réunis en un seul endroit.';
	@override String get subtitle_creator => 'Chaque revenu et chaque virement — sécurisés, téléchargeables, signés.';
	@override String get summary_total_paid => 'Total payé';
	@override String get summary_total_validated => 'Total validé';
	@override String get summary_pending => 'En attente';
	@override String get summary_count => 'Documents';
	@override String get filter_all => 'Tout';
	@override String get filter_deposits => 'Dépôts';
	@override String get filter_billing => 'Budget campagne';
	@override String get filter_payouts => 'Virements';
	@override String get filter_earnings => 'Revenus';
	@override String get type_deposit => 'Dépôt portefeuille';
	@override String get type_billing => 'Budget campagne';
	@override String get type_payout => 'Virement créateur';
	@override String get type_earnings => 'Revenus publicitaires';
	@override String get type_unknown => 'Autre';
	@override String get status_paid => 'Payée';
	@override String get status_validated => 'Validée';
	@override String get status_pending => 'En attente';
	@override String get status_cancelled => 'Annulée';
	@override String get role_advertiser => 'Annonceur';
	@override String get role_creator => 'Créateur';
	@override String get search_hint => 'Rechercher par numéro, référence…';
	@override String get empty_title => 'Aucune facture pour l\'instant';
	@override String get empty_subtitle => 'Vos dépôts, budgets campagne et virements apparaîtront ici automatiquement — sans aucune action manuelle.';
	@override String get empty_subtitle_creator => 'Vos revenus et documents de virement s’affichent dès qu’ils sont émis — mêmes PDF signés que sur le web.';
	@override String get empty_cta => 'Actualiser';
	@override String get error_title => 'Impossible de charger les factures';
	@override String get error_subtitle => 'Tirez pour rafraîchir — nous réessayons immédiatement.';
	@override String get load_more => 'Charger plus';
	@override String get pagination_meta => 'Page {current} sur {total}';
	@override String get pagination_previous => 'Précédent';
	@override String get pagination_next => 'Suivant';
	@override String get date_preset_all => 'Toutes les dates';
	@override String get date_preset_30d => '30 jours';
	@override String get date_preset_90d => '90 jours';
	@override String get date_preset_custom => 'Personnalisé';
	@override String get details_title => 'Facture {number}';
	@override String get details_section_summary => 'Résumé';
	@override String get details_section_actions => 'Actions';
	@override String get details_section_legal => 'Légal & références';
	@override String get details_invoice_number => 'Numéro de facture';
	@override String get details_issued_at => 'Émise le';
	@override String get details_paid_at => 'Payée le';
	@override String get details_type => 'Type';
	@override String get details_status => 'Statut';
	@override String get details_role => 'Rôle';
	@override String get details_reference => 'Référence';
	@override String get details_amount => 'Total';
	@override String get details_tax => 'TVA incluse';
	@override String get details_currency => 'Devise';
	@override String get action_download_pdf => 'Télécharger le PDF';
	@override String get action_share_pdf => 'Partager';
	@override String get action_open_pdf => 'Ouvrir';
	@override String get action_copy_number => 'Copier le numéro';
	@override String get action_view_details => 'Voir le détail';
	@override String get download_progress => 'Préparation du PDF…';
	@override String get download_success => 'Enregistré sous {filename}';
	@override String get download_error => 'Échec du téléchargement. Réessayez.';
	@override String get copied_to_clipboard => 'Numéro de facture copié.';
	@override String get share_subject => 'Facture {number}';
	@override String get polling_live => 'Live';
	@override String get polling_paused => 'En pause';
	@override String get summary_this_month => 'Ce mois-ci';
	@override String get pagination_detail => 'Page {current} sur {total} · {count} factures';
	@override String get sort_sheet_title => 'Trier';
	@override String get sort_date_newest => 'Plus récent';
	@override String get sort_date_oldest => 'Plus ancien';
	@override String get sort_amount_high => 'Montant · décroissant';
	@override String get sort_amount_low => 'Montant · croissant';
	@override String get sort_status_az => 'Statut · A à Z';
	@override String get sort_status_za => 'Statut · Z à A';
	@override String get date_range_title => 'Dates';
	@override String get date_from => 'Du';
	@override String get date_to => 'Au';
	@override String get clear_dates => 'Effacer';
	@override String get date_apply => 'Appliquer';
	@override String get download_all_zip => 'ZIP';
	@override String get zip_progress => 'Création du ZIP…';
	@override String get zip_success => 'Enregistré : {filename}';
	@override String get zip_error => 'Échec du téléchargement ZIP.';
}

// Path: push
class _TranslationsPushFr extends TranslationsPushEn {
	_TranslationsPushFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get onboarding_title => 'Restez informé';
	@override String get onboarding_subtitle => 'Recevez des alertes instantanées pour l’essentiel — même lorsque Wayo Ads est en arrière-plan.';
	@override String get onboarding_bullet_campaigns => 'Campagnes, candidatures et budgets';
	@override String get onboarding_bullet_messages => 'Nouveaux messages dans le chat';
	@override String get onboarding_bullet_system => 'Factures, virements et alertes plateforme';
	@override String get onboarding_enable => 'Activer les notifications';
	@override String get onboarding_later => 'Pas maintenant';
	@override String get onboarding_success => 'Notifications activées';
	@override String get onboarding_denied_hint => 'Vous pourrez les activer plus tard dans les réglages du téléphone.';
	@override String get onboarding_context_chat => 'Vous venez de recevoir un message — activez les alertes pour ne plus manquer une réponse.';
	@override String get onboarding_context_campaign => 'Le statut d\'une campagne a changé — activez les notifications pour suivre candidatures et budgets.';
	@override String get onboarding_context_invoice => 'Une facture ou un virement vient d\'être mis à jour — soyez alerté dès que l\'argent bouge.';
}

// Path: creator
class _TranslationsCreatorFr extends TranslationsCreatorEn {
	_TranslationsCreatorFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsCreatorDashboardFr dashboard = _TranslationsCreatorDashboardFr._(_root);
	@override late final _TranslationsCreatorWalletFr wallet = _TranslationsCreatorWalletFr._(_root);
	@override late final _TranslationsCreatorCampaignsFr campaigns = _TranslationsCreatorCampaignsFr._(_root);
	@override late final _TranslationsCreatorStatsFr stats = _TranslationsCreatorStatsFr._(_root);
	@override late final _TranslationsCreatorApplicationsFr applications = _TranslationsCreatorApplicationsFr._(_root);
	@override late final _TranslationsCreatorBusinessFr business = _TranslationsCreatorBusinessFr._(_root);
}

// Path: advertiser_wallet
class _TranslationsAdvertiserWalletFr extends TranslationsAdvertiserWalletEn {
	_TranslationsAdvertiserWalletFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hero_title => 'Votre solde';
	@override String get hero_subtitle => 'Ajoutez des fonds pour lancer des campagnes. Paiements sécurisés via Stripe. Apple Pay (iOS) et Google Pay (Android) sont proposés lorsqu’ils sont disponibles.';
	@override String get available => 'Disponible';
	@override String get pending => 'En attente';
	@override String get add_funds => 'Ajouter des fonds';
	@override String get amount_label => 'Montant';
	@override String get quick_50 => '50 €';
	@override String get quick_100 => '100 €';
	@override String get quick_250 => '250 €';
	@override String get min_deposit => 'Dépôt minimum : 50,00 dans la devise affichée.';
	@override String get test_pay => 'Simuler le paiement (dev)';
	@override String get test_hint => 'Mode test : pas de vraie carte. Crédit portefeuille de dev pour QA.';
	@override String get pay_secure => 'Carte, Apple Pay ou Google Pay';
	@override String get pay_with_card => 'Payer par carte';
	@override String get pay_with_apple => 'Payer avec Apple Pay';
	@override String get pay_with_google => 'Payer avec Google Pay';
	@override String get or => 'ou';
	@override String get stripe_unavailable => 'Rechargement indisponible : le paiement n’est pas configuré côté serveur.';
	@override String get tx_title => 'Activité récente';
	@override String get tx_empty => 'Aucune transaction';
	@override String get tx_deposit => 'Dépôt';
	@override String get tx_withdrawal => 'Retrait';
	@override String get tx_other => 'Opération';
	@override String get success => 'Solde mis à jour';
	@override String get failed => 'Impossible d’ajouter des fonds. Réessayez.';
	@override String get in_progress => 'Traitement…';
	@override String tx_page({required Object current, required Object total}) => 'Page ${current} sur ${total}';
	@override String get tx_prev => 'Précédent';
	@override String get tx_next => 'Suivant';
	@override String get business_profile_gate_title => 'Informations d’entreprise requises';
	@override String get business_profile_gate_body => 'Renseignez des coordonnées de facturation valides avant d’ajouter des fonds — conformité et facturation Wayo Ads.';
	@override String get business_profile_gate_secure => 'Connexion chiffrée — contrôle côté serveur avant tout paiement.';
	@override String get business_profile_gate_cta => 'Renseigner mon activité';
	@override String get business_profile_error => 'Impossible de charger le profil entreprise.';
	@override String get pay_locked_until_business => 'Le paiement sera disponible une fois le profil complété.';
	@override String get payment_title => 'Paiement';
	@override String get payment_total => 'TOTAL';
	@override String get payment_deposit_amount => 'Montant du dépôt';
	@override String get payment_bank_fee => 'Frais de transaction bancaire (3.69%)';
}

// Path: chat
class _TranslationsChatFr extends TranslationsChatEn {
	_TranslationsChatFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get inbox_title => 'Messages';
	@override String get inbox_subtitle => 'Conversations sécurisées pour vos campagnes';
	@override String get conversation_unknown => 'Conversation';
	@override String get thread_fallback_title => 'Chat';
	@override String get composer_hint => 'Écrire un message…';
	@override String get typing => 'En train d’écrire…';
	@override String get error_load_threads => 'Impossible de charger vos conversations. Réessayez.';
	@override String get error_phone => 'Le partage de numéros de téléphone dans le chat n’est pas autorisé.';
	@override String get spam_cooldown_title => 'Vous envoyez trop de messages';
	@override String spam_cooldown_body({required Object seconds}) => 'Patientez ${seconds} s avant d’envoyer à nouveau.';
	@override String spam_cooldown_seconds({required Object seconds}) => '${seconds} s';
	@override String get empty_threads_title => 'Aucune conversation';
	@override String get empty_threads_hint => 'Quand quelqu’un vous écrit au sujet d’une campagne, ce sera ici.';
	@override String get online => 'En ligne';
	@override String get offline => 'Hors ligne';
	@override String get typing_status => 'En train d’écrire…';
	@override String get attachment => 'Pièce jointe';
	@override String get attachment_image => 'Photo';
	@override String get attachment_pdf => 'PDF';
	@override String get open_file => 'Ouvrir';
	@override String get pick_attachment => 'Image ou PDF';
	@override String get upload_failed => 'Envoi du fichier impossible. Réessayez.';
	@override String get file_too_large => 'Fichier trop volumineux (max 10 Mo pour les images, 50 Mo pour le PDF).';
	@override String get search_users_hint => 'Rechercher une personne par nom…';
	@override String get search_users_no_results => 'Aucun utilisateur ne correspond.';
	@override String get search_users_min_hint => 'Saisissez au moins 2 caractères pour lancer la recherche.';
	@override String get search_prior_chats_hint => 'Rechercher parmi les personnes avec qui vous avez échangé…';
	@override String get search_prior_chats_no_results => 'Personne ne correspond dans vos conversations.';
	@override String get search_prior_chats_min_hint => 'Saisissez au moins 2 caractères.';
	@override String get conversation_open_failed => 'Impossible d’ouvrir cette conversation. Réessayez.';
	@override String get file_picker_restart_hint => 'Les pièces jointes nécessitent un redémarrage complet de l’app après une mise à jour. Arrêtez l’app puis relancez-la (évitez le hot restart).';
	@override String get attachment_type_not_allowed => 'Seules les images (JPG, PNG, GIF, WebP, BMP) ou les PDF sont autorisées.';
	@override String get inbox_swipe_soon => 'Épingler et archiver depuis la liste arrivent bientôt.';
	@override String get date_today => 'Aujourd\'hui';
	@override String get date_yesterday => 'Hier';
	@override String get bubble_reply => 'Répondre';
	@override String get reply_composer_title => 'Répondre';
	@override String get reply_composer_you => 'Vous';
	@override String get composer_reply_hint => 'Écrivez une réponse…';
	@override String get bubble_copy => 'Copier';
	@override String get bubble_react => 'Réagir';
	@override String get bubble_delete => 'Supprimer';
	@override String get bubble_update => 'Modifier';
	@override String get bubble_delete_unavailable => 'La suppression des messages depuis l\'app n\'est pas encore disponible.';
	@override String get bubble_copied => 'Copié dans le presse-papiers';
	@override String get bubble_forward => 'Transférer';
	@override String get share_media_tooltip => 'Partager';
	@override String get share_failed => 'Impossible de partager ce fichier. Réessayez.';
	@override String get forward_sheet_title => 'Envoyer vers…';
	@override String get forward_no_other_chats => 'Ouvrez ou créez une autre conversation d’abord.';
	@override String get forward_sending => 'Transfert…';
	@override String get forward_ok => 'Message transféré.';
	@override String get forward_failed => 'Échec du transfert.';
	@override String get forward_view => 'Ouvrir';
	@override String get edited => 'modifié';
	@override String get seen => 'Vu';
	@override String get delivered => 'Livré';
	@override String get edit_mode_title => 'Modification du message';
	@override String get edit_mode_cancel => 'Annuler';
	@override String get edit_mode_hint => 'Modifier votre message…';
	@override String get edit_failed => 'Impossible de modifier ce message. Réessayez.';
	@override String get edit_not_allowed => 'Seuls vos messages texte peuvent être modifiés.';
	@override String get delete_failed => 'Impossible de supprimer ce message. Réessayez.';
	@override String get delete_not_allowed => 'Vous ne pouvez supprimer que vos propres messages.';
	@override String get delete_confirm_title => 'Supprimer ce message ?';
	@override String get delete_confirm_text => 'Cette action est irréversible.';
	@override String get delete_confirm_cta => 'Supprimer';
	@override String get delete_confirm_cancel => 'Annuler';
	@override String get scroll_to_latest => 'Récent';
	@override String get loading_older_messages => 'Chargement des messages plus anciens…';
	@override String get load_older_failed => 'Impossible de charger les messages plus anciens.';
	@override String get image_download_tooltip => 'Télécharger la photo';
	@override String get image_close_tooltip => 'Fermer';
	@override String get image_saved_to_gallery => 'Photo enregistrée dans la galerie.';
	@override String get image_download_failed => 'Impossible de télécharger cette photo.';
	@override String get image_permission_denied => 'Accès aux photos refusé. Activez-la dans les réglages.';
	@override String get image_saved_downloads_browser => 'Photo téléchargée — vérifiez votre dossier Téléchargements.';
}

// Path: common
class _TranslationsCommonFr extends TranslationsCommonEn {
	_TranslationsCommonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get language => 'Langue';
	@override String get theme => 'Thème';
	@override String get light => 'Clair';
	@override String get dark => 'Sombre';
	@override String get system => 'Système';
}

// Path: errors
class _TranslationsErrorsFr extends TranslationsErrorsEn {
	_TranslationsErrorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get rate_limited => 'Trop de tentatives. Réessayez dans quelques minutes.';
	@override String get invalid_credentials => 'Identifiants incorrects.';
	@override String get network => 'Impossible de joindre le serveur. Vérifiez votre connexion.';
	@override String get server_generic => 'Une erreur s\'est produite. Réessayez.';
	@override String get empty_response => 'Réponse vide du serveur.';
	@override String get login_failed => 'Échec de la connexion.';
	@override String get unknown => 'Une erreur inattendue s\'est produite.';
	@override String get session_invalid => 'Votre session a expiré. Veuillez vous reconnecter.';
	@override String get email_not_found => 'Aucun compte pour cet email.';
}

// Path: privacy_policy
class _TranslationsPrivacyPolicyFr extends TranslationsPrivacyPolicyEn {
	_TranslationsPrivacyPolicyFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Politique de confidentialité';
	@override String get last_updated => 'Dernière mise à jour : 7 octobre 2025';
	@override String get intro_title => '1. Introduction';
	@override String get intro_body => 'Chez Wayo Ads, nous nous engageons à collecter et à utiliser vos données de manière responsable, conformément aux lois applicables en matière de protection des données, notamment la loi marocaine n° 09-08 et, le cas échéant, le RGPD (UE 2016/679). En utilisant notre plateforme, vous acceptez la collecte, le traitement et l’utilisation de vos données tel que décrit dans la présente politique de confidentialité.';
	@override String get data_title => '2. Données que nous collectons';
	@override String get data_body => 'Nous ne collectons que les données nécessaires, conformément à la loi 09-08 et, le cas échéant, au RGPD.\n\nPour les annonceurs\n• Identification et contact : raison sociale, adresse e-mail, numéro de téléphone.\n• Profil : logo d’entreprise (si fourni), description de l’entreprise.\n• Campagnes : contenu des campagnes, budgets, critères de ciblage, données analytiques.\n\nPour les créateurs\n• Identification et contact : nom, adresse e-mail, numéro de téléphone.\n• Profil : photo de profil (si fournie), biographie, domaines d’expertise, liens vers les réseaux sociaux.\n• Contenu : vidéos, publications et supports que vous téléversez.\n• Données d’usage : interactions avec la plateforme, statistiques d’engagement, données de rémunération.\n\nInformations techniques (tous les utilisateurs)\n• Données techniques : adresse IP, type et version du navigateur, type d’appareil, système d’exploitation, identifiants de session, horodatages, pages visitées, clics, référents.\n• Cookies et technologies similaires : voir la section 8 (Cookies).\n\nDonnées de paiement\n• Transactions : montants, devise, date, moyen de paiement, adresse de facturation.\n• Important : les données de carte bancaire sont traitées exclusivement par notre prestataire de paiement (Stripe). Wayo Ads ne stocke pas les informations de carte bancaire.';
	@override String get purpose_title => '3. Finalités du traitement';
	@override String get purpose_body => 'Nous utilisons vos données pour : fournir, maintenir et améliorer nos services ; personnaliser l’expérience et recommander du contenu pertinent ; gérer la relation contractuelle (comptes, facturation, support) ; communiquer des informations relatives au service (mises à jour, changements, alertes) ; assurer la sécurité et l’intégrité de la plateforme (détection d’abus et de fraude) ; et réaliser des analyses d’usage avec des données agrégées ou anonymisées lorsque cela est possible.';
	@override String get legal_bases_title => '4. Bases juridiques du traitement';
	@override String get legal_bases_body => 'Selon les cas, nous nous appuyons sur : votre consentement (par exemple, cookies non essentiels, newsletters) ; l’exécution d’un contrat ou de mesures précontractuelles (par exemple, inscription, facturation) ; le respect d’une obligation légale (par exemple, conservation des factures) ; et notre intérêt légitime (par exemple, sécurité, amélioration du service).';
	@override String get sharing_title => '5. Partage de vos informations';
	@override String get sharing_body => 'Wayo Ads ne vend pas vos données personnelles. Un partage limité peut avoir lieu avec : des prestataires essentiels (processeurs de paiement, hébergeurs, outils d’e-mailing, analytique) ; et pour des motifs légaux si la loi l’exige ou en réponse à une demande légitime d’une autorité compétente.';
	@override String get security_title => '6. Sécurité des données';
	@override String get security_body => 'Nous mettons en œuvre notamment : le chiffrement TLS/HTTPS pour les données en transit ; des contrôles d’accès selon le principe du besoin d’en connaître ; des sauvegardes régulières et des procédures de restauration ; des mises à jour de sécurité et des audits périodiques ; ainsi que la journalisation et la détection d’activités anormales.';
	@override String get content_title => '7. Responsabilités des utilisateurs et protection du contenu';
	@override String get content_body => 'Vous devez respecter les droits de propriété intellectuelle des créateurs et de Wayo Ads. Ne copiez, ne partagez, ne redistribuez et ne revendez pas de contenu sans autorisation. Toute violation peut entraîner la suspension du compte et, le cas échéant, des poursuites.';
	@override String get cookies_title => '8. Cookies et technologies de suivi';
	@override String get cookies_body => 'Nous utilisons : des cookies essentiels (fonctionnement du site, sécurité, session) ; et des cookies analytiques (par exemple, Google Analytics) pour la mesure d’audience. Les cookies non essentiels ne sont déposés qu’avec votre consentement via une bannière cookies lors de votre première visite.';
	@override String get retention_title => '9. Conservation des données';
	@override String get retention_body => 'Nous conservons vos données uniquement le temps nécessaire aux finalités décrites dans la présente politique. Les données de compte sont conservées pendant la durée de vie du compte, augmentée de toute période légale de conservation. Les données de transaction sont conservées conformément aux obligations comptables et fiscales.';
	@override String get children_title => '10. Vie privée des enfants';
	@override String get children_body => 'Nos services ne s’adressent pas aux mineurs de moins de 18 ans. Nous ne collectons pas sciemment d’informations personnelles auprès d’enfants. Si nous apprenons que des données ont été collectées auprès d’un enfant sans le consentement parental, nous prendrons des mesures pour les supprimer.';
	@override String get changes_title => '11. Modifications de la présente politique';
	@override String get changes_body => 'Nous pouvons mettre à jour cette politique de confidentialité occasionnellement. Nous vous informerons des changements importants en publiant la nouvelle politique sur cette page et en mettant à jour la date de « Dernière mise à jour ».';
	@override String get contact_title => '12. Coordonnées';
	@override String get contact_body => 'Responsable du traitement : Wayo, Dubaï, Émirats arabes unis.\nE-mail : info@wayo.cloud\nAdresse : R320 Umm Hurair 2, Dubaï, Émirats arabes unis.';
}

// Path: app_settings
class _TranslationsAppSettingsFr extends TranslationsAppSettingsEn {
	_TranslationsAppSettingsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Préférences';
	@override String get subtitle => 'Apparence et langue';
	@override String get section_appearance => 'Apparence';
	@override String get section_language => 'Langue';
	@override String get theme_light => 'Clair';
	@override String get theme_dark => 'Sombre';
	@override String get theme_system => 'Système';
	@override String get theme_hint => 'Choisissez l’apparence de Wayo Ads. Système suit le réglage du téléphone.';
	@override String get language_hint => 'Langue de l’interface. Dates et formats suivent la locale.';
	@override String get design_variant => 'Style du panneau';
	@override String get design_glass => 'Verre doux';
	@override String get design_corporate => 'Corporate';
	@override String get close => 'Fermer';
	@override String get open_semantics => 'Ouvrir préférences et langue';
	@override String get close_semantics => 'Fermer les préférences';
	@override String get profile_fallback => 'Compte';
	@override String get selected => 'Sélectionné';
	@override String get lang_en => 'English';
	@override String get lang_fr => 'Français';
	@override String get lang_ar => 'العربية';
	@override String get section_notifications => 'Notifications';
	@override String get notifications_toggle => 'Notifications push';
	@override String get notifications_hint => 'Alertes campagnes, chat, factures et paiements. Autorisation requise dans les réglages du téléphone.';
	@override String get notifications_status_enabled => 'Activées — vous recevrez les alertes sur cet appareil';
	@override String get notifications_status_disabled => 'Désactivées dans l’application';
	@override String get notifications_status_permission_denied => 'Autorisez les notifications dans les réglages du téléphone';
	@override String get notifications_open_settings => 'Ouvrir les réglages';
	@override String get notifications_enable_error => 'Impossible d’activer les notifications. Vérifiez les réglages système.';
	@override String get notifications_update_error => 'Impossible de mettre à jour les notifications. Réessayez.';
	@override String get section_account => 'Compte';
	@override String get delete_account_entry => 'Supprimer le compte';
	@override String get delete_account_entry_sub => 'Délai de 30 jours — suppression dans l’app';
	@override String get section_about => 'À propos';
	@override String get rate_app => 'Noter Wayo Ads';
	@override String get rate_app_sub => 'Ouvre l’App Store ou Google Play';
}

// Path: account_deletion
class _TranslationsAccountDeletionFr extends TranslationsAccountDeletionEn {
	_TranslationsAccountDeletionFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get nav_title => 'Suppression de compte';
	@override String get title => 'Supprimer mon compte Wayo Ads';
	@override String get danger_zone_chip => 'Zone de danger';
	@override String get danger_zone_intro => 'Supprime définitivement votre compte et toutes les données associées. À l’issue de la période de grâce, cette action ne pourra pas être annulée.';
	@override String get danger_what_title => 'Ce qui sera supprimé :';
	@override String get danger_item_profile => 'Votre profil et vos informations personnelles';
	@override String get danger_item_campaigns => 'Toutes vos campagnes et leurs données de performance';
	@override String get danger_item_business => 'Votre profil entreprise et les informations de marque';
	@override String get danger_item_wallet => 'Votre portefeuille annonceur et l’historique des transactions';
	@override String get danger_item_notifications => 'Vos notifications et préférences e-mail';
	@override String get danger_item_access => 'Votre accès à Wayo Ads (vous ne pourrez plus vous connecter ici)';
	@override String get danger_wayo_note => 'Seules les données Wayo Ads sont concernées. Votre compte Wayo (utilisé pour vous connecter) reste actif pour les autres services Wayo.';
	@override String get subtitle_warning => 'Important : au bout de 30 jours, vos données Wayo Ads seront supprimées définitivement. Vous pouvez annuler à tout moment avant cette date.';
	@override String get bullet_loss => 'Campagnes, candidatures et données de profil côté application seront supprimées après le délai.';
	@override String get bullet_wallet => 'Solde portefeuille, factures et historique des transactions liés à ce compte seront supprimés.';
	@override String get bullet_cancel => 'Annulation gratuite pendant 30 jours à compter de la demande.';
	@override String get bullet_recreate => 'Votre Wayo ID (connexion) n’est pas supprimé par cette étape — vous pourrez vous reconnecter avec un nouveau profil applicatif.';
	@override String get role_advertiser => 'Annonceur : les campagnes actives s’arrêtent lorsque les données sont purgées.';
	@override String get role_creator => 'Créateur : candidatures, chaînes et gains dans l’app seront supprimés.';
	@override String get continue_cta => 'Continuer';
	@override String get back => 'Retour';
	@override String get more_info_title => 'Avant de continuer';
	@override String get more_info_body => 'E-mails : confirmation immédiate, puis un rappel environ 3 jours avant la suppression.\nSupport : contactez-nous pour exporter des données ou clôturer des campagnes.';
	@override String get step_auth_title => 'Confirmer votre identité';
	@override String get status_active => 'Aucune suppression en cours pour ce compte.';
	@override String status_pending({required Object date}) => 'Suppression déjà planifiée. Date finale : ${date}';
	@override String get password_label => 'Mot de passe';
	@override String get password_hint => 'Au moins 8 caractères';
	@override String get forgot_password => 'Mot de passe oublié ?';
	@override String get oauth_note => 'Si vous utilisez uniquement Google ou Apple, définissez d’abord un mot de passe (Mot de passe oublié).';
	@override String get oauth_deletion_intro => 'Vous vous connectez avec Google ou Apple. Après « Continuer », confirmez à l’étape suivante — aucun mot de passe requis.';
	@override String get oauth_deletion_step_hint => 'Votre identité a été vérifiée à la connexion Google ou Apple. Touchez le bouton ci-dessous pour afficher la feuille de confirmation finale.';
	@override String legal_recap({required Object date}) => 'Vous lancez une période de grâce de 30 jours avant suppression définitive. Vous pouvez annuler jusqu’au ${date}.';
	@override String get next_review => 'Vérifier et confirmer';
	@override String get dialog_title => 'Confirmer ?';
	@override String get dialog_body => 'Vos données Wayo Ads seront planifiées pour suppression. Suppression définitive le :';
	@override String get dialog_cancel_hint => 'Vous pouvez annuler à tout moment dans les paramètres jusqu’à cette date.';
	@override String get timeline_request => 'Demande';
	@override String get timeline_reminder => 'Rappel e-mail';
	@override String get timeline_purge => 'Suppression';
	@override String get dialog_confirm => 'Oui, planifier la suppression';
	@override String get dialog_dismiss => 'Garder mon compte';
	@override String get success_title => 'Suppression planifiée';
	@override String get success_intro => 'Que se passe-t-il maintenant ?';
	@override String get success_use_until => 'Vous pouvez continuer à utiliser Wayo Ads jusqu’à la date limite.';
	@override String get success_reminder => 'Nous vous enverrons un rappel quelques jours avant la suppression.';
	@override String get success_cancel_anytime => 'Annulez à tout moment depuis cet écran ou les paramètres.';
	@override String days_left({required Object n}) => 'Jours restants : ${n}';
	@override String purge_date({required Object date}) => 'Suppression définitive : ${date}';
	@override String reminder_approx({required Object date}) => 'Rappel vers le : ${date}';
	@override String get cancel_request => 'Annuler la suppression';
	@override String get go_home => 'Retour à l’accueil';
	@override String get toast_cancelled => 'Suppression annulée. Votre compte est rétabli.';
	@override String get error_load => 'Impossible de charger le statut du compte.';
	@override String get error_load_unauthorized => 'Impossible de vérifier votre session Wayo Ads. Déconnectez-vous, reconnectez-vous, puis réessayez.';
	@override String get error_load_network => 'Vérifiez votre connexion et l’accessibilité de Wayo Ads, puis réessayez.';
	@override String get error_delete => 'Une erreur s’est produite. Réessayez.';
	@override String get error_password => 'Mot de passe incorrect. Réessayez ou réinitialisez votre mot de passe.';
	@override String banner_line({required Object date, required Object n}) => 'Votre compte sera supprimé le ${date} (${n} jours restants).';
	@override String get banner_cancel_dialog_title => 'Annuler la suppression planifiée ?';
	@override String get banner_cancel_dialog_body => 'Votre profil Wayo Ads restera actif.';
	@override String get banner_cancel_dialog_confirm => 'Garder mon compte';
	@override String pending_danger_card_body({required Object date}) => 'Votre compte est programmé pour une suppression définitive le ${date}. Vous pouvez annuler cette demande à tout moment avant cette date.';
	@override String get pending_scheduled_status => 'Suppression du compte planifiée';
	@override String get pending_days_remaining_one => 'Il reste 1 jour';
	@override String pending_days_remaining_plural({required Object n}) => 'Il reste ${n} jours';
}

// Path: onboarding
class _TranslationsOnboardingFr extends TranslationsOnboardingEn {
	_TranslationsOnboardingFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get role_gate_title => 'Choisissez votre profil';
	@override String get role_gate_subtitle => 'Même étape que sur le site Wayo Ads avant d’utiliser l’app.';
	@override String get role_creator_cta => 'Créateur';
	@override String get role_creator_desc => 'Parcourez les campagnes, postulez et collaborez avec les marques.';
	@override String get role_advertiser_cta => 'Annonceur';
	@override String get role_advertiser_desc => 'Lancez des campagnes et pilotez les créateurs depuis votre tableau de bord.';
	@override String get email_code_title => 'Vérifiez votre email';
	@override String email_code_subtitle({required Object email}) => 'Saisissez le code à 6 chiffres envoyé à ${email}.';
	@override String get skip => 'Passer';
	@override String get next => 'Suivant';
	@override String get done => 'Compris';
	@override late final _TranslationsOnboardingAdvertiserFr advertiser = _TranslationsOnboardingAdvertiserFr._(_root);
	@override late final _TranslationsOnboardingCreatorFr creator = _TranslationsOnboardingCreatorFr._(_root);
}

// Path: dashboard.balance
class _TranslationsDashboardBalanceFr extends TranslationsDashboardBalanceEn {
	_TranslationsDashboardBalanceFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Aperçu du solde';
	@override String get available => 'Disponible';
	@override String get locked => 'Bloqué';
	@override String get spent => 'Dépensé';
}

// Path: dashboard.campaigns
class _TranslationsDashboardCampaignsFr extends TranslationsDashboardCampaignsEn {
	_TranslationsDashboardCampaignsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vos campagnes';
	@override String get subtitle => 'Gérez vos campagnes et suivez leurs performances.';
	@override String get creators => '{count} créateurs';
	@override String get empty_title => 'Aucune campagne';
	@override String get empty_subtitle => 'Créez votre première campagne pour commencer';
	@override String get create_cta => 'Créer une campagne';
	@override String get pagination_previous => 'Précédent';
	@override String get pagination_next => 'Suivant';
	@override String pagination_page({required Object current, required Object total}) => 'Page ${current} / ${total}';
}

// Path: dashboard.errors
class _TranslationsDashboardErrorsFr extends TranslationsDashboardErrorsEn {
	_TranslationsDashboardErrorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get load_balance => 'Impossible de charger le solde';
	@override String get load_campaigns => 'Impossible de charger les campagnes';
	@override String get retry => 'Réessayer';
}

// Path: advertiser_campaigns.tabs
class _TranslationsAdvertiserCampaignsTabsFr extends TranslationsAdvertiserCampaignsTabsEn {
	_TranslationsAdvertiserCampaignsTabsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get active => 'Actives';
	@override String get draft => 'Brouillons';
	@override String get paused => 'En pause';
	@override String get completed => 'Terminées';
}

// Path: advertiser_campaigns.empty
class _TranslationsAdvertiserCampaignsEmptyFr extends TranslationsAdvertiserCampaignsEmptyEn {
	_TranslationsAdvertiserCampaignsEmptyFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Aucune campagne';
	@override String get hint => 'Vous n\'avez pas encore de campagne pour ce statut.';
	@override String get search => 'Aucun résultat pour cette recherche';
	@override String get search_hint => 'Essayez un autre nom ou effacez la recherche.';
}

// Path: advertiser_campaigns.card
class _TranslationsAdvertiserCampaignsCardFr extends TranslationsAdvertiserCampaignsCardEn {
	_TranslationsAdvertiserCampaignsCardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get budget_total => 'Budget';
	@override String get remaining => 'Restant';
	@override String get locked => 'Engagé';
	@override String get spent => 'Dépensé';
	@override String get cpc => 'CPC';
	@override String get valid_engagements => '{count} vues validées';
	@override String get list_row_views => '{count} vues';
	@override String get list_row_clicks => '{count} clics';
	@override String get list_row_creators => '{count} créateurs';
}

// Path: advertiser_campaigns.status
class _TranslationsAdvertiserCampaignsStatusFr extends TranslationsAdvertiserCampaignsStatusEn {
	_TranslationsAdvertiserCampaignsStatusFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get active => 'Active';
	@override String get paused => 'En pause';
	@override String get completed => 'Terminée';
	@override String get draft => 'Brouillon';
	@override String get other => 'Autre';
}

// Path: advertiser_campaigns.platform
class _TranslationsAdvertiserCampaignsPlatformFr extends TranslationsAdvertiserCampaignsPlatformEn {
	_TranslationsAdvertiserCampaignsPlatformFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get youtube => 'YouTube';
	@override String get tiktok => 'TikTok';
	@override String get instagram => 'Instagram';
	@override String get other => 'Plateforme';
}

// Path: advertiser_campaigns.detail
class _TranslationsAdvertiserCampaignsDetailFr extends TranslationsAdvertiserCampaignsDetailEn {
	_TranslationsAdvertiserCampaignsDetailFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fallback_title => 'Campagne';
	@override String get metrics_title => 'Performance';
	@override String get valid_views => 'Vues validées';
	@override String get valid_clicks => 'Clics valides';
	@override String get approved_creators => 'Créateurs approuvés';
	@override String get platform_label => 'Plateforme';
	@override String get campaign_type_label => 'Type de campagne';
	@override String get niche_label => 'Niche';
	@override String get location_label => 'Lieu cible';
	@override String get objective_label => 'Objectif';
	@override String get objective_awareness => 'Notoriété';
	@override String get objective_traffic => 'Trafic';
	@override String get objective_conversion => 'Conversion';
	@override String get cpm_metric => 'CPM (pour 1k vues)';
	@override String get cpc_metric => 'CPC (par clic)';
	@override String get description_title => 'Description';
	@override String get show_more => 'Voir plus';
	@override String get show_less => 'Voir moins';
}

// Path: advertiser_campaigns.create
class _TranslationsAdvertiserCampaignsCreateFr extends TranslationsAdvertiserCampaignsCreateEn {
	_TranslationsAdvertiserCampaignsCreateFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nouvelle campagne';
	@override String get section_basics => 'Informations';
	@override String get section_budget => 'Budget et enchères';
	@override String get field_type => 'Type de campagne';
	@override String get field_objective => 'Objectif';
	@override String get field_niche => 'Niche / secteur';
	@override String get field_title => 'Titre';
	@override String get field_description => 'Description (optionnel)';
	@override String get field_landing => 'URL de la page cible';
	@override String get field_assets => 'Lien brief / assets';
	@override String get field_budget => 'Budget total';
	@override String get field_cpm_hint => 'CPM — coût pour 1 000 impressions (centimes)';
	@override String get field_cpc_hint => 'CPC — coût par clic (centimes)';
	@override String get field_video_min_duration => 'Durée minimum de la vidéo (minutes)';
	@override String get field_shorts_max_duration => 'Durée max des shorts (secondes)';
	@override String get type_link => 'Lien';
	@override String get type_video => 'Vidéo';
	@override String get type_shorts => 'Shorts';
	@override String get landing_help => 'Obligatoire pour les campagnes lien (https).';
	@override String get assets_help => 'Vidéo et shorts : lien https Google Drive, OneDrive ou SharePoint.';
	@override String get submit_draft => 'Enregistrer en brouillon';
	@override String get validation_title => 'Vérifiez les champs.';
	@override String get assets_url_invalid => 'Utilisez une URL https Google Drive, OneDrive ou SharePoint.';
	@override String get success => 'Campagne créée (brouillon)';
	@override String get submit_in_progress => 'Enregistrement…';
}

// Path: advertiser_campaigns.applications
class _TranslationsAdvertiserCampaignsApplicationsFr extends TranslationsAdvertiserCampaignsApplicationsEn {
	_TranslationsAdvertiserCampaignsApplicationsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Candidatures des créateurs';
	@override String pending_badge({required Object count}) => '${count} en attente';
	@override String get subtitle => 'Examinez et approuvez ou refusez les candidatures';
	@override String get empty_title => 'Aucune candidature';
	@override String get empty_subtitle => 'Quand des créateurs postuleront, ils apparaîtront ici.';
	@override String get load_error => 'Impossible de charger les candidatures';
	@override String trust_score({required Object score}) => 'Confiance : ${score}';
	@override String get approve_button => 'Approuver';
	@override String get reject_button => 'Refuser';
	@override String get approved_status => 'Approuvée';
	@override String get rejected_status => 'Refusée';
}

// Path: creator.dashboard
class _TranslationsCreatorDashboardFr extends TranslationsCreatorDashboardEn {
	_TranslationsCreatorDashboardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Studio Créateur';
	@override String get subtitle => 'Suivez vos statistiques, candidatures et gains en temps réel.';
	@override String get coming_soon_title => 'Votre tableau de bord créateur';
	@override String get coming_soon_subtitle => 'Statistiques, analyses et candidatures actives s’afficheront ici. Mises à jour en temps réel déjà branchées — pas besoin de rafraîchir.';
}

// Path: creator.wallet
class _TranslationsCreatorWalletFr extends TranslationsCreatorWalletEn {
	_TranslationsCreatorWalletFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get coming_soon_title => 'Vos gains';
	@override String get coming_soon_subtitle => 'Solde disponible, virements en attente et historique Stripe s’afficheront ici.';
	@override String get connect_stripe_title => 'Connecter Stripe';
	@override String get connect_stripe_subtitle => 'Associez votre compte bancaire via Stripe pour activer les retraits. Vos données financières ne sont jamais stockées.';
	@override String get withdraw_title => 'Demander un retrait';
	@override String get withdraw_subtitle => 'Retirez votre solde disponible vers votre compte Stripe connecté.';
	@override String get available_balance => 'Disponible';
	@override String get pending_balance => 'En attente';
	@override String get total_earned => 'Total gagné';
	@override String get load_error => 'Impossible de charger votre portefeuille';
	@override String get withdraw_button => 'Retirer';
	@override String get withdraw_sheet_title => 'Demander un retrait';
	@override String get withdraw_sheet_subtitle => 'Solde disponible : {available}. Les fonds seront envoyés vers votre compte Stripe.';
	@override String get withdraw_amount_label => 'Montant (USD)';
	@override String get withdraw_sheet_body => 'Entrez le montant que vous souhaitez retirer. Les fonds seront envoyés sur votre compte bancaire connecté.';
	@override String get withdraw_quick_amounts => 'Montants rapides';
	@override String get withdraw_gross_amount => 'Montant brut';
	@override String get withdraw_platform_fee => 'Frais de plateforme ({percent}%)';
	@override String get withdraw_tax_vat => 'TVA ({percent}%)';
	@override String get withdraw_net_received => 'Net reçu';
	@override String get withdraw_submit => 'Confirmer le retrait';
	@override String get withdraw_submitting => 'Traitement…';
	@override String get withdraw_max => 'Max';
	@override String get withdraw_preset_all => 'Tout';
	@override String get withdraw_success => 'Demande de retrait envoyée.';
	@override String get withdraw_secure_footer => 'Paiement sécurisé — traité par Stripe. Vos coordonnées bancaires ne nous sont jamais transmises.';
	@override String get withdraw_error_invalid => 'Saisissez un montant valide.';
	@override String get withdraw_error_min => 'Retrait minimum : {min}.';
	@override String get withdraw_error_insufficient => 'Solde disponible insuffisant.';
	@override String get withdraw_reason_business_info => 'Finalisez vos informations commerciales avant de connecter un compte de paiement.';
	@override String get withdraw_reason_stripe => 'Connectez Stripe pour activer les retraits.';
	@override String get withdraw_reason_stripe_incomplete => 'Terminez l’onboarding Stripe pour activer les retraits.';
	@override String get withdraw_reason_payouts_disabled => 'Votre compte Stripe n’est pas encore validé pour les paiements.';
	@override String get withdraw_reason_below_min => 'Retrait minimum : {min}.';
	@override String get cancel_action => 'Annuler la demande';
	@override String get cancel_in_progress => 'Annulation…';
	@override String get cancel_dialog_title => 'Annuler ce retrait ?';
	@override String get cancel_dialog_message => 'Le retrait en attente sera annulé et les fonds reversés à votre solde disponible.';
	@override String get cancel_dialog_yes => 'Annuler le retrait';
	@override String get cancel_dialog_no => 'Conserver';
	@override String get cancel_success => 'Retrait annulé, les fonds ont été restaurés.';
	@override String get stripe_connected => 'Connecté';
	@override String get stripe_onboarding_required_pill => 'Action requise';
	@override String get stripe_connect_action => 'Connecter Stripe';
	@override String get stripe_complete_action => 'Terminer l’onboarding';
	@override String get stripe_open_dashboard => 'Ouvrir le tableau Stripe';
	@override String get stripe_error => 'Un souci est survenu avec Stripe. Veuillez réessayer.';
	@override String get stripe_edit_business_action => 'Corriger mes infos';
	@override String get stripe_card_title_disconnected => 'Connecter Stripe';
	@override String get stripe_card_subtitle_disconnected => 'Associez votre compte bancaire via Stripe pour recevoir vos paiements.';
	@override String get stripe_card_title_incomplete => 'Terminez votre onboarding';
	@override String get stripe_card_subtitle_incomplete => 'Stripe a encore besoin de quelques infos avant d’activer les paiements.';
	@override String get stripe_card_title_connected => 'Stripe est connecté';
	@override String get stripe_card_subtitle_connected => 'Votre compte Stripe Express est actif. Les paiements arrivent sur votre banque.';
	@override String get history_title => 'Historique des retraits';
	@override String get history_empty => 'Aucun retrait pour le moment — l’historique s’affichera ici.';
	@override String get history_load_error => 'Impossible de charger l’historique des retraits.';
	@override String get history_status_pending => 'En attente';
	@override String get history_status_processing => 'En cours';
	@override String get history_status_succeeded => 'Payé';
	@override String get history_status_failed => 'Échec';
	@override String get history_status_cancelled => 'Annulé';
	@override String get conditions_title => 'Conditions de retrait';
	@override String get conditions_subtitle => 'À savoir avant de demander un paiement.';
	@override String get conditions_min_label => 'Retrait minimum';
	@override String get conditions_fee_label => 'Frais';
	@override String conditions_fee_value({required Object percent}) => '${percent} (hors TVA)';
	@override String get conditions_processing_label => 'Délai de traitement';
	@override String get conditions_processing_value => '2 à 5 jours ouvrés';
}

// Path: creator.campaigns
class _TranslationsCreatorCampaignsFr extends TranslationsCreatorCampaignsEn {
	_TranslationsCreatorCampaignsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get browse_title => 'Explorer les campagnes';
	@override String get browse_subtitle => 'Trouvez des campagnes adaptées à votre audience et postulez en un tap.';
	@override String get browse_search_placeholder => 'Rechercher par nom, type ou marque';
	@override String get browse_empty_search_title => 'Aucune campagne correspondante';
	@override String get browse_empty_search_subtitle => 'Essayez un autre mot-clé — nom, type (vidéo, shorts, lien) ou marque annonceur.';
	@override String get applications_title => 'Mes candidatures';
	@override String get applications_subtitle => 'Suivez le statut — approuvée, en attente, refusée — de chaque campagne.';
	@override String get submit_title => 'Soumettre un post';
	@override String get submit_subtitle => 'Une fois approuvé, partagez une URL vidéo publique pour que l\'annonceur la valide.';
	@override String get details_title => 'Détails de la campagne';
	@override String get application_title => 'Ma candidature';
	@override String get load_error => 'Impossible de charger les campagnes.';
	@override String get empty_title => 'Aucune campagne active';
	@override String get empty_subtitle => 'Les nouvelles campagnes apparaîtront ici dès qu\'un annonceur les lancera.';
	@override String get pagination_previous => 'Précédent';
	@override String get pagination_next => 'Suivant';
	@override String pagination_page({required Object current, required Object total}) => 'Page ${current} / ${total}';
	@override String get description_title => 'Brief';
	@override String get requirements_title => 'Exigences';
	@override String get assets_title => 'Assets de la marque';
	@override String get assets_subtitle => 'Téléchargez le brief, les logos et les rushs.';
	@override String get type_link => 'Lien';
	@override String get type_video => 'Vidéo';
	@override String get type_shorts => 'Shorts';
	@override String get reward_cpm_label => 'CPM';
	@override String get reward_cpc_label => 'Rémunération par clic';
	@override String get reward_per_view_label => 'Rémunération par vue';
	@override String reward_per_view({required Object amount}) => '${amount} / vue';
	@override String reward_per_click({required Object amount}) => '${amount} / clic';
	@override String get budget_remaining_label => 'Budget restant';
	@override String requirement_platform({required Object platform}) => 'Publiez uniquement sur ${platform}';
	@override String requirement_min_duration({required Object minutes}) => 'Durée minimale : ${minutes} min';
	@override String requirement_shorts_max({required Object seconds}) => 'Shorts jusqu\'à ${seconds} s';
	@override String get requirement_vertical => 'Format vertical (9:16) requis';
	@override String get requirement_none => 'Aucune exigence particulière.';
	@override String get apply_cta => 'Postuler à cette campagne';
	@override String get apply_title => 'Postuler';
	@override String get apply_message_label => 'Pitch (facultatif)';
	@override String get apply_message_hint => 'Expliquez pourquoi vous êtes le bon profil…';
	@override String get apply_submit => 'Envoyer la candidature';
	@override String get apply_in_progress => 'Envoi…';
	@override String get apply_error => 'Impossible d\'envoyer votre candidature. Réessayez.';
	@override String get apply_success => 'Candidature envoyée — vous serez notifié dès la décision.';
	@override String get apply_pending_title => 'Candidature en revue';
	@override String get apply_pending_subtitle => 'Nous vous préviendrons dès que l\'annonceur aura répondu.';
	@override String get open_application_cta => 'Ouvrir ma candidature';
	@override String get chat_with_advertiser => 'Discuter avec l\'annonceur';
	@override String get status_banner_approved_title => 'Vous êtes approuvé !';
	@override String get status_banner_approved_subtitle => 'Vous pouvez soumettre votre vidéo et chatter avec l\'annonceur.';
	@override String get status_banner_pending_title => 'En attente de l\'annonceur';
	@override String get status_banner_pending_subtitle => 'Votre pitch est en revue — vous recevrez une notification ici.';
	@override String get status_banner_rejected_title => 'Non retenu cette fois';
	@override String get status_banner_rejected_subtitle => 'Gardez un œil sur l\'onglet Campagnes — de nouveaux briefs arrivent chaque semaine.';
	@override String get my_submissions_title => 'Mes soumissions';
	@override String get my_submissions_empty_approved => 'Aucune vidéo soumise. Envoyez-en une pour commencer à gagner.';
	@override String get my_submissions_empty_pending => 'Les soumissions se débloquent une fois votre candidature approuvée.';
	@override String get submit_cta => 'Soumettre un post';
	@override String get submit_platform_label => 'Plateforme';
	@override String get submit_url_label => 'URL publique de la vidéo';
	@override String get submit_url_hint => 'https://youtube.com/watch?v=…';
	@override String get submit_url_required => 'Collez l\'URL de la vidéo.';
	@override String get submit_url_invalid => 'Saisissez une URL publique valide.';
	@override String get submit_url_youtube_only => 'Seules les URLs YouTube sont supportées pour l\'instant.';
	@override String get submit_in_progress => 'Envoi…';
	@override String get submit_footer => 'Votre vidéo doit rester publique pendant la campagne pour valider les vues.';
	@override String get submit_error => 'Impossible d\'envoyer votre vidéo. Réessayez.';
	@override String get submit_success => 'Vidéo envoyée — l\'annonceur la validera sous peu.';
	@override String get submit_blocked_limit => 'Vous avez déjà soumis pour cette campagne. Attendez la revue.';
	@override String get submission_status_pending => 'En revue';
	@override String get submission_status_approved => 'Approuvé';
	@override String get submission_status_rejected => 'Refusé';
	@override String get submission_status_flagged => 'Signalé';
	@override String submission_views({required Object views}) => '${views} vues validées';
}

// Path: creator.stats
class _TranslationsCreatorStatsFr extends TranslationsCreatorStatsEn {
	_TranslationsCreatorStatsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get earnings_title => 'Gains totaux';
	@override String get pending => 'En attente';
	@override String get validated_views => 'Vues validées';
	@override String get validation_rate => 'Taux de validation';
	@override String get approved_campaigns => 'Campagnes approuvées';
}

// Path: creator.applications
class _TranslationsCreatorApplicationsFr extends TranslationsCreatorApplicationsEn {
	_TranslationsCreatorApplicationsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get section_title => 'Candidatures actives';
	@override String get empty_title => 'Aucune candidature';
	@override String get empty_subtitle => 'Parcourez l’onglet Campagnes et postulez à celles qui correspondent à votre audience.';
	@override String get load_error => 'Impossible de charger vos candidatures';
	@override String get status_pending => 'En attente';
	@override String get status_approved => 'Approuvée';
	@override String get status_rejected => 'Refusée';
	@override String get status_withdrawn => 'Retirée';
	@override String get status_unknown => '—';
}

// Path: creator.business
class _TranslationsCreatorBusinessFr extends TranslationsCreatorBusinessEn {
	_TranslationsCreatorBusinessFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get cta_title => 'Finalisez vos informations commerciales';
	@override String get cta_subtitle => 'Obligatoire avant de connecter votre compte bancaire — pour router correctement vos paiements.';
	@override String get cta_required_pill => 'REQUIS';
	@override String get cta_button => 'Finalize your Business Information';
	@override String get dialog_title => 'Informations commerciales';
	@override String get dialog_subtitle => 'Quelques infos légales pour que Stripe puisse ouvrir votre compte et traiter les paiements.';
	@override String get section_type => 'Type d\'entreprise';
	@override String get section_company => 'Société';
	@override String get section_address => 'Adresse';
	@override String get section_stripe => 'Pays et devise de paiement';
	@override String get type_personal_title => 'Particulier / Personne privée';
	@override String get type_personal_subtitle => 'Je reçois les paiements en tant que particulier.';
	@override String get type_company_title => 'Société enregistrée';
	@override String get type_company_subtitle => 'J’opère sous une entité juridique enregistrée.';
	@override String get company_name => 'Nom de la société';
	@override String get vat_number => 'Numéro de TVA';
	@override String get address_line1 => 'Adresse ligne 1';
	@override String get address_line2 => 'Adresse ligne 2 (optionnel)';
	@override String get city => 'Ville';
	@override String get postal_code => 'Code postal';
	@override String get state_region => 'Région (optionnel)';
	@override String get country => 'Pays';
	@override String get currency => 'Devise de paiement';
	@override String get error_required => 'Champ requis';
	@override String get save_and_continue => 'Enregistrer et continuer';
	@override String get submitting => 'Enregistrement…';
	@override String get footer_info => 'Ces informations sont transmises à Stripe pour activer votre compte de paiement. Vos coordonnées bancaires ne nous sont jamais transmises.';
	@override String get save_error => 'Impossible d’enregistrer vos infos. Veuillez réessayer.';
}

// Path: onboarding.advertiser
class _TranslationsOnboardingAdvertiserFr extends TranslationsOnboardingAdvertiserEn {
	_TranslationsOnboardingAdvertiserFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get dashboard_title => 'Votre tableau de bord';
	@override String get dashboard_subtitle => 'Suivez votre solde, vos campagnes actives et vos notifications — tout se met à jour en temps réel.';
	@override String get campaigns_title => 'Campagnes';
	@override String get campaigns_subtitle => 'Créez de nouvelles campagnes, examinez les candidatures et suivez les performances au même endroit.';
	@override String get wallet_title => 'Portefeuille';
	@override String get wallet_subtitle => 'Rechargez votre budget et suivez vos dépenses — sécurisé par Stripe.';
	@override String get invoices_title => 'Factures';
	@override String get invoices_subtitle => 'Téléchargez vos PDF signés : dépôts, facturation des campagnes et virements — tout au même endroit.';
	@override String get chat_title => 'Chat';
	@override String get chat_subtitle => 'Discutez avec vos créateurs une fois la campagne validée. Vos conversations restent synchronisées.';
}

// Path: onboarding.creator
class _TranslationsOnboardingCreatorFr extends TranslationsOnboardingCreatorEn {
	_TranslationsOnboardingCreatorFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get dashboard_title => 'Dashboard créateur';
	@override String get dashboard_subtitle => 'Vos KPIs, candidatures actives et revenus se rafraîchissent automatiquement — sans geste de votre part.';
	@override String get campaigns_title => 'Parcourir & postuler';
	@override String get campaigns_subtitle => 'Découvrez les campagnes éligibles, postulez en un clic et suivez l\'état de vos candidatures en direct.';
	@override String get wallet_title => 'Revenus & retraits';
	@override String get wallet_subtitle => 'Consultez votre solde, demandez un retrait via Stripe Connect et retrouvez vos paiements.';
	@override String get invoices_title => 'Relevés de paiement';
	@override String get invoices_subtitle => 'Filtrez revenus et virements, téléchargez des PDF signés ou un ZIP — tout se met à jour automatiquement.';
	@override String get chat_title => 'Discuter avec l\'annonceur';
	@override String get chat_subtitle => 'Dès l\'approbation, le chat s\'ouvre pour vous aligner avec l\'annonceur sur la livraison.';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'connectivity.offline_title': return 'Aucune connexion Internet';
			case 'connectivity.offline_subtitle': return 'Vérifiez votre réseau puis réessayez.';
			case 'connectivity.reconnecting_title': return 'Reconnexion…';
			case 'connectivity.reconnecting_subtitle': return 'Nous essayons de rétablir votre connexion.';
			case 'connectivity.weak_title': return 'Connexion faible';
			case 'connectivity.weak_subtitle': return 'Certaines actions peuvent être plus lentes que d’habitude.';
			case 'connectivity.restored': return 'Connexion rétablie';
			case 'connectivity.action_retry': return 'Réessayer';
			case 'connectivity.action_settings': return 'Réglages';
			case 'campaigns_explorer.filter_all_types': return 'Tous les types';
			case 'campaigns_explorer.filter_all_platforms': return 'Toutes les plateformes';
			case 'campaigns_explorer.filter_all_niches': return 'Toutes les niches';
			case 'campaigns_explorer.filter_all_locations': return 'Tous les lieux';
			case 'campaigns_explorer.platform_youtube': return 'YouTube';
			case 'campaigns_explorer.platform_tiktok': return 'TikTok';
			case 'campaigns_explorer.platform_instagram': return 'Instagram';
			case 'campaigns_explorer.results_one': return '1 campagne';
			case 'campaigns_explorer.results_many': return ({required Object n}) => '${n} campagnes';
			case 'campaigns_explorer.layout_grid': return 'Grille';
			case 'campaigns_explorer.layout_list': return 'Liste';
			case 'campaigns_explorer.empty_filters': return 'Aucune campagne ne correspond à ces filtres.';
			case 'campaigns_explorer.empty_filters_subtitle': return 'Retirez un filtre ou changez le type — les niches listées correspondent à vos autres choix.';
			case 'campaigns_explorer.search_aria': return 'Rechercher des campagnes';
			case 'campaigns_explorer.reset_filters': return 'Réinitialiser les filtres';
			case 'campaigns_explorer.toolbar_show_search_filters': return 'Afficher recherche et filtres';
			case 'campaigns_explorer.toolbar_hide_search_filters': return 'Masquer recherche et filtres';
			case 'campaigns_explorer.filter_label_type': return 'Type';
			case 'campaigns_explorer.filter_label_status': return 'Statut';
			case 'campaigns_explorer.filter_label_niche': return 'Niche';
			case 'campaigns_explorer.filter_label_location': return 'Lieu';
			case 'login.brand': return 'Wayo Ads';
			case 'login.headline_line1': return 'Bienvenue';
			case 'login.headline_line2_prefix': return 'sur ';
			case 'login.headline_brand': return 'Wayo Ads';
			case 'login.subtitle': return 'Connectez-vous avec votre compte Wayo ID pour gérer vos campagnes et vos collaborations.';
			case 'login.cta': return 'Se connecter à Wayo Ads';
			case 'login.secure_note': return 'Authentification sécurisée via Wayo ID';
			case 'login.terms_prefix': return 'En continuant, vous acceptez nos ';
			case 'login.terms': return 'CGU';
			case 'login.and': return ' et ';
			case 'login.privacy': return 'Politique de confidentialité';
			case 'login.dot': return '.';
			case 'login.email_label': return 'Email';
			case 'login.password_label': return 'Mot de passe';
			case 'login.show_password': return 'Afficher';
			case 'login.hide_password': return 'Masquer';
			case 'login.email_required': return 'Email requis';
			case 'login.email_invalid': return 'Email invalide';
			case 'login.password_required': return 'Mot de passe requis';
			case 'login.password_min': return 'Au moins 6 caractères';
			case 'login.rate_limit_title': return 'Patience';
			case 'login.rate_limit_body': return 'Trop de tentatives de connexion.';
			case 'login.rate_limit_remaining': return ({required Object seconds}) => 'Réessayez dans ${seconds} s';
			case 'login.forgot_password_link': return 'Mot de passe oublié ?';
			case 'login.google_cta': return 'Continuer avec Google';
			case 'login.apple_cta': return 'Se connecter avec Apple';
			case 'login.apple_unavailable': return 'Connexion avec Apple indisponible sur cet appareil.';
			case 'login.apple_failed': return 'Échec de la connexion avec Apple. Réessayez.';
			case 'login.apple_canceled': return 'Connexion avec Apple annulée.';
			case 'login.google_not_configured': return 'Connexion Google non configurée. Ajoutez AUTH_GOOGLE_SERVER_CLIENT_ID dans dart_defines.json (ID client Web Google se terminant par .apps.googleusercontent.com), puis redémarrez complètement l’app.';
			case 'login.google_wrong_client_id': return 'AUTH_GOOGLE_SERVER_CLIENT_ID doit être l’ID client Web Google Cloud (…apps.googleusercontent.com), pas l’UUID du client OAuth Passport.';
			case 'login.google_failed': return 'Échec de la connexion Google. Réessayez.';
			case 'login.google_channel_restart': return 'Connexion Google interrompue avec Android (souvent après un hot restart). Arrêtez complètement l’app puis Relancer — évitez le hot restart.';
			case 'login.google_android_oauth_misconfigured': return 'Google n’a pas pu vérifier l’app (code 10). Dans Google Cloud Console, même projet que l’ID client Web : ajoutez un client OAuth de type Android avec le package ma.wayo.wayoadsgo et l’empreinte SHA-1 du keystore (debug ou release), attendez quelques minutes puis réessayez.';
			case 'login.session_expired_snack': return 'Votre session a expiré. Veuillez vous reconnecter.';
			case 'verify_email.title': return 'Confirmez votre email';
			case 'verify_email.subtitle': return 'Wayo ID exige une adresse vérifiée (comme sur le site). Ouvrez le lien envoyé à :';
			case 'verify_email.check_again': return 'C’est fait — continuer';
			case 'verify_email.open_mail': return 'Ouvrir l’application mail';
			case 'verify_email.still_pending': return 'Vérification toujours en attente. Vérifiez la boîte de réception ou les spams, puis réessayez.';
			case 'verify_email.open_mail_failed': return 'Impossible d’ouvrir l’application mail.';
			case 'verify_email.sign_out': return 'Se déconnecter';
			case 'forgot_password.title': return 'Réinitialiser\nle mot de passe';
			case 'forgot_password.subtitle': return 'Entrez votre email Wayo. Nous vous enverrons un code à 6 chiffres.';
			case 'forgot_password.email_label': return 'Email';
			case 'forgot_password.cta': return 'Envoyer le code';
			case 'forgot_password.rate_limit_title': return 'Patience';
			case 'forgot_password.rate_limit_body': return 'Trop de demandes de réinitialisation. Réessayez dans un instant.';
			case 'forgot_password.rate_limit_remaining': return ({required Object seconds}) => 'Réessayez dans ${seconds} s';
			case 'otp.title': return 'Vérifiez\nvotre email';
			case 'otp.subtitle': return ({required Object email}) => 'Saisissez le code envoyé à ${email}';
			case 'otp.resend': return 'Renvoyer le code';
			case 'otp.resend_in': return ({required Object seconds}) => 'Renvoi dans ${seconds} s';
			case 'reset_password.title': return 'Nouveau\nmot de passe';
			case 'reset_password.subtitle': return 'Choisissez un mot de passe solide (min. 8 caractères, 1 majuscule, 1 chiffre).';
			case 'reset_password.new_password': return 'Nouveau mot de passe';
			case 'reset_password.confirm_password': return 'Confirmer le mot de passe';
			case 'reset_password.cta': return 'Mettre à jour le mot de passe';
			case 'reset_password.password_updated': return 'Mot de passe mis à jour. Vous pouvez vous connecter.';
			case 'validation.required': return 'Champ requis';
			case 'validation.invalid_email': return 'Email invalide';
			case 'validation.min8': return 'Au moins 8 caractères';
			case 'validation.need_upper': return 'Une majuscule est requise';
			case 'validation.need_digit': return 'Un chiffre est requis';
			case 'validation.mismatch': return 'Les mots de passe ne correspondent pas';
			case 'home.title': return 'Wayo Ads';
			case 'home.logout': return 'Déconnexion';
			case 'home.session_title': return 'Session active';
			case 'home.session_hint': return 'Jeton Auth_Wayo stocké de façon sécurisée. Les appels API utilisent Authorization: Bearer automatiquement.';
			case 'home.user_fallback': return 'Utilisateur';
			case 'dashboard.title': return 'Tableau de bord';
			case 'dashboard.welcome': return 'Bon retour, {name} !';
			case 'dashboard.welcome_fallback': return 'Bon retour !';
			case 'dashboard.subtitle': return 'Voici l’aperçu de vos campagnes.';
			case 'dashboard.account_creator': return 'Compte créateur';
			case 'dashboard.account_advertiser': return 'Compte annonceur';
			case 'dashboard.coming_soon': return 'Bientôt disponible.';
			case 'dashboard.balance.title': return 'Aperçu du solde';
			case 'dashboard.balance.available': return 'Disponible';
			case 'dashboard.balance.locked': return 'Bloqué';
			case 'dashboard.balance.spent': return 'Dépensé';
			case 'dashboard.campaigns.title': return 'Vos campagnes';
			case 'dashboard.campaigns.subtitle': return 'Gérez vos campagnes et suivez leurs performances.';
			case 'dashboard.campaigns.creators': return '{count} créateurs';
			case 'dashboard.campaigns.empty_title': return 'Aucune campagne';
			case 'dashboard.campaigns.empty_subtitle': return 'Créez votre première campagne pour commencer';
			case 'dashboard.campaigns.create_cta': return 'Créer une campagne';
			case 'dashboard.campaigns.pagination_previous': return 'Précédent';
			case 'dashboard.campaigns.pagination_next': return 'Suivant';
			case 'dashboard.campaigns.pagination_page': return ({required Object current, required Object total}) => 'Page ${current} / ${total}';
			case 'dashboard.errors.load_balance': return 'Impossible de charger le solde';
			case 'dashboard.errors.load_campaigns': return 'Impossible de charger les campagnes';
			case 'dashboard.errors.retry': return 'Réessayer';
			case 'dashboard.notifications_title': return 'Notifications';
			case 'dashboard.notifications_empty': return 'Aucune notification';
			case 'dashboard.notification_incoming': return 'Nouvelle notification';
			case 'dashboard.notification_view': return 'Voir';
			case 'dashboard.notifications_mark_all_read': return 'Tout marquer comme lu';
			case 'dashboard.notifications_mark_read': return 'Marquer comme lu';
			case 'dashboard.notifications_dismiss': return 'Ignorer';
			case 'dashboard.notifications_view_all': return 'Voir toutes les notifications';
			case 'dashboard.notifications_important': return 'Important';
			case 'dashboard.notifications_earlier': return 'Plus ancien';
			case 'dashboard.notifications_caught_up_title': return 'Vous êtes à jour !';
			case 'dashboard.notifications_caught_up_subtitle': return 'Aucune nouvelle notification';
			case 'dashboard.notifications_center_title': return 'Centre de notifications';
			case 'dashboard.notifications_unread_count': return '{count} notifications non lues';
			case 'dashboard.notifications_all_caught_up': return 'Vous êtes à jour';
			case 'dashboard.notifications_tab_all': return 'Tout';
			case 'dashboard.notifications_tab_archived': return 'Archive';
			case 'dashboard.notifications_search_hint': return 'Recherche de notifications…';
			case 'dashboard.notifications_filter_type_all': return 'Tous les types';
			case 'dashboard.notifications_filter_priority_all': return 'Toutes les priorités';
			case 'dashboard.notifications_priority_critical': return 'Critique';
			case 'dashboard.notifications_priority_high': return 'Haute';
			case 'dashboard.notifications_priority_normal': return 'Normale';
			case 'dashboard.notifications_priority_low': return 'Basse';
			case 'dashboard.notifications_load_more': return 'Charger plus';
			case 'dashboard.notifications_view_details': return 'Voir les détails';
			case 'dashboard.notifications_archive': return 'Archiver';
			case 'dashboard.notifications_urgent': return 'Urgent';
			case 'dashboard.notifications_just_now': return 'À l\'instant';
			case 'dashboard.notifications_minutes_ago': return 'Il y a {n} min';
			case 'dashboard.notifications_hours_ago': return 'Il y a {n} h';
			case 'dashboard.notifications_days_ago': return 'Il y a {n} j';
			case 'dashboard.notifications_section_all': return 'Toutes les notifications';
			case 'dashboard.notifications_section_important': return 'Alertes importantes';
			case 'dashboard.notifications_section_archived': return 'Notifications archivées';
			case 'dashboard.application_approve': return 'Approuver';
			case 'dashboard.application_reject': return 'Refuser';
			case 'dashboard.application_approved': return 'Candidature approuvée';
			case 'dashboard.application_rejected': return 'Candidature refusée';
			case 'dashboard.application_action_failed': return 'Impossible de mettre à jour la candidature. Réessayez.';
			case 'dashboard.theme_toggle_tooltip': return 'Basculer entre thème clair et sombre';
			case 'dashboard.refresh': return 'Actualiser le tableau de bord';
			case 'dashboard.shell_tour_restart': return 'Revoir le tour d’onboarding';
			case 'dashboard.shell_tour_restart_hint': return 'Relancer la visite guidée de la navigation Tableau de bord, Campagnes, Portefeuille et Messages';
			case 'advertiser_campaigns.title': return 'Campagnes';
			case 'advertiser_campaigns.subtitle': return 'Créez des campagnes brouillon, suivez les performances et examinez les candidatures.';
			case 'advertiser_campaigns.tabs.active': return 'Actives';
			case 'advertiser_campaigns.tabs.draft': return 'Brouillons';
			case 'advertiser_campaigns.tabs.paused': return 'En pause';
			case 'advertiser_campaigns.tabs.completed': return 'Terminées';
			case 'advertiser_campaigns.search_placeholder': return 'Rechercher une campagne';
			case 'advertiser_campaigns.empty.none': return 'Aucune campagne';
			case 'advertiser_campaigns.empty.hint': return 'Vous n\'avez pas encore de campagne pour ce statut.';
			case 'advertiser_campaigns.empty.search': return 'Aucun résultat pour cette recherche';
			case 'advertiser_campaigns.empty.search_hint': return 'Essayez un autre nom ou effacez la recherche.';
			case 'advertiser_campaigns.card.budget_total': return 'Budget';
			case 'advertiser_campaigns.card.remaining': return 'Restant';
			case 'advertiser_campaigns.card.locked': return 'Engagé';
			case 'advertiser_campaigns.card.spent': return 'Dépensé';
			case 'advertiser_campaigns.card.cpc': return 'CPC';
			case 'advertiser_campaigns.card.valid_engagements': return '{count} vues validées';
			case 'advertiser_campaigns.card.list_row_views': return '{count} vues';
			case 'advertiser_campaigns.card.list_row_clicks': return '{count} clics';
			case 'advertiser_campaigns.card.list_row_creators': return '{count} créateurs';
			case 'advertiser_campaigns.status.active': return 'Active';
			case 'advertiser_campaigns.status.paused': return 'En pause';
			case 'advertiser_campaigns.status.completed': return 'Terminée';
			case 'advertiser_campaigns.status.draft': return 'Brouillon';
			case 'advertiser_campaigns.status.other': return 'Autre';
			case 'advertiser_campaigns.platform.youtube': return 'YouTube';
			case 'advertiser_campaigns.platform.tiktok': return 'TikTok';
			case 'advertiser_campaigns.platform.instagram': return 'Instagram';
			case 'advertiser_campaigns.platform.other': return 'Plateforme';
			case 'advertiser_campaigns.detail.fallback_title': return 'Campagne';
			case 'advertiser_campaigns.detail.metrics_title': return 'Performance';
			case 'advertiser_campaigns.detail.valid_views': return 'Vues validées';
			case 'advertiser_campaigns.detail.valid_clicks': return 'Clics valides';
			case 'advertiser_campaigns.detail.approved_creators': return 'Créateurs approuvés';
			case 'advertiser_campaigns.detail.platform_label': return 'Plateforme';
			case 'advertiser_campaigns.detail.campaign_type_label': return 'Type de campagne';
			case 'advertiser_campaigns.detail.niche_label': return 'Niche';
			case 'advertiser_campaigns.detail.location_label': return 'Lieu cible';
			case 'advertiser_campaigns.detail.objective_label': return 'Objectif';
			case 'advertiser_campaigns.detail.objective_awareness': return 'Notoriété';
			case 'advertiser_campaigns.detail.objective_traffic': return 'Trafic';
			case 'advertiser_campaigns.detail.objective_conversion': return 'Conversion';
			case 'advertiser_campaigns.detail.cpm_metric': return 'CPM (pour 1k vues)';
			case 'advertiser_campaigns.detail.cpc_metric': return 'CPC (par clic)';
			case 'advertiser_campaigns.detail.description_title': return 'Description';
			case 'advertiser_campaigns.detail.show_more': return 'Voir plus';
			case 'advertiser_campaigns.detail.show_less': return 'Voir moins';
			case 'advertiser_campaigns.create.title': return 'Nouvelle campagne';
			case 'advertiser_campaigns.create.section_basics': return 'Informations';
			case 'advertiser_campaigns.create.section_budget': return 'Budget et enchères';
			case 'advertiser_campaigns.create.field_type': return 'Type de campagne';
			case 'advertiser_campaigns.create.field_objective': return 'Objectif';
			case 'advertiser_campaigns.create.field_niche': return 'Niche / secteur';
			case 'advertiser_campaigns.create.field_title': return 'Titre';
			case 'advertiser_campaigns.create.field_description': return 'Description (optionnel)';
			case 'advertiser_campaigns.create.field_landing': return 'URL de la page cible';
			case 'advertiser_campaigns.create.field_assets': return 'Lien brief / assets';
			case 'advertiser_campaigns.create.field_budget': return 'Budget total';
			case 'advertiser_campaigns.create.field_cpm_hint': return 'CPM — coût pour 1 000 impressions (centimes)';
			case 'advertiser_campaigns.create.field_cpc_hint': return 'CPC — coût par clic (centimes)';
			case 'advertiser_campaigns.create.field_video_min_duration': return 'Durée minimum de la vidéo (minutes)';
			case 'advertiser_campaigns.create.field_shorts_max_duration': return 'Durée max des shorts (secondes)';
			case 'advertiser_campaigns.create.type_link': return 'Lien';
			case 'advertiser_campaigns.create.type_video': return 'Vidéo';
			case 'advertiser_campaigns.create.type_shorts': return 'Shorts';
			case 'advertiser_campaigns.create.landing_help': return 'Obligatoire pour les campagnes lien (https).';
			case 'advertiser_campaigns.create.assets_help': return 'Vidéo et shorts : lien https Google Drive, OneDrive ou SharePoint.';
			case 'advertiser_campaigns.create.submit_draft': return 'Enregistrer en brouillon';
			case 'advertiser_campaigns.create.validation_title': return 'Vérifiez les champs.';
			case 'advertiser_campaigns.create.assets_url_invalid': return 'Utilisez une URL https Google Drive, OneDrive ou SharePoint.';
			case 'advertiser_campaigns.create.success': return 'Campagne créée (brouillon)';
			case 'advertiser_campaigns.create.submit_in_progress': return 'Enregistrement…';
			case 'advertiser_campaigns.applications.title': return 'Candidatures des créateurs';
			case 'advertiser_campaigns.applications.pending_badge': return ({required Object count}) => '${count} en attente';
			case 'advertiser_campaigns.applications.subtitle': return 'Examinez et approuvez ou refusez les candidatures';
			case 'advertiser_campaigns.applications.empty_title': return 'Aucune candidature';
			case 'advertiser_campaigns.applications.empty_subtitle': return 'Quand des créateurs postuleront, ils apparaîtront ici.';
			case 'advertiser_campaigns.applications.load_error': return 'Impossible de charger les candidatures';
			case 'advertiser_campaigns.applications.trust_score': return ({required Object score}) => 'Confiance : ${score}';
			case 'advertiser_campaigns.applications.approve_button': return 'Approuver';
			case 'advertiser_campaigns.applications.reject_button': return 'Refuser';
			case 'advertiser_campaigns.applications.approved_status': return 'Approuvée';
			case 'advertiser_campaigns.applications.rejected_status': return 'Refusée';
			case 'nav.dashboard': return 'Tableau de bord';
			case 'nav.campaigns': return 'Campagnes';
			case 'nav.analytics': return 'Analytique';
			case 'nav.wallet': return 'Portefeuille';
			case 'nav.chat': return 'Messages';
			case 'nav.invoices': return 'Factures';
			case 'nav.invoices_creator': return 'Relevés';
			case 'invoices.title': return 'Factures';
			case 'invoices.title_creator': return 'Relevés de paiement';
			case 'invoices.subtitle_advertiser': return 'Chaque dépôt et chaque budget campagne — réunis en un seul endroit.';
			case 'invoices.subtitle_creator': return 'Chaque revenu et chaque virement — sécurisés, téléchargeables, signés.';
			case 'invoices.summary_total_paid': return 'Total payé';
			case 'invoices.summary_total_validated': return 'Total validé';
			case 'invoices.summary_pending': return 'En attente';
			case 'invoices.summary_count': return 'Documents';
			case 'invoices.filter_all': return 'Tout';
			case 'invoices.filter_deposits': return 'Dépôts';
			case 'invoices.filter_billing': return 'Budget campagne';
			case 'invoices.filter_payouts': return 'Virements';
			case 'invoices.filter_earnings': return 'Revenus';
			case 'invoices.type_deposit': return 'Dépôt portefeuille';
			case 'invoices.type_billing': return 'Budget campagne';
			case 'invoices.type_payout': return 'Virement créateur';
			case 'invoices.type_earnings': return 'Revenus publicitaires';
			case 'invoices.type_unknown': return 'Autre';
			case 'invoices.status_paid': return 'Payée';
			case 'invoices.status_validated': return 'Validée';
			case 'invoices.status_pending': return 'En attente';
			case 'invoices.status_cancelled': return 'Annulée';
			case 'invoices.role_advertiser': return 'Annonceur';
			case 'invoices.role_creator': return 'Créateur';
			case 'invoices.search_hint': return 'Rechercher par numéro, référence…';
			case 'invoices.empty_title': return 'Aucune facture pour l\'instant';
			case 'invoices.empty_subtitle': return 'Vos dépôts, budgets campagne et virements apparaîtront ici automatiquement — sans aucune action manuelle.';
			case 'invoices.empty_subtitle_creator': return 'Vos revenus et documents de virement s’affichent dès qu’ils sont émis — mêmes PDF signés que sur le web.';
			case 'invoices.empty_cta': return 'Actualiser';
			case 'invoices.error_title': return 'Impossible de charger les factures';
			case 'invoices.error_subtitle': return 'Tirez pour rafraîchir — nous réessayons immédiatement.';
			case 'invoices.load_more': return 'Charger plus';
			case 'invoices.pagination_meta': return 'Page {current} sur {total}';
			case 'invoices.pagination_previous': return 'Précédent';
			case 'invoices.pagination_next': return 'Suivant';
			case 'invoices.date_preset_all': return 'Toutes les dates';
			case 'invoices.date_preset_30d': return '30 jours';
			case 'invoices.date_preset_90d': return '90 jours';
			case 'invoices.date_preset_custom': return 'Personnalisé';
			case 'invoices.details_title': return 'Facture {number}';
			case 'invoices.details_section_summary': return 'Résumé';
			case 'invoices.details_section_actions': return 'Actions';
			case 'invoices.details_section_legal': return 'Légal & références';
			case 'invoices.details_invoice_number': return 'Numéro de facture';
			case 'invoices.details_issued_at': return 'Émise le';
			case 'invoices.details_paid_at': return 'Payée le';
			case 'invoices.details_type': return 'Type';
			case 'invoices.details_status': return 'Statut';
			case 'invoices.details_role': return 'Rôle';
			case 'invoices.details_reference': return 'Référence';
			case 'invoices.details_amount': return 'Total';
			case 'invoices.details_tax': return 'TVA incluse';
			case 'invoices.details_currency': return 'Devise';
			case 'invoices.action_download_pdf': return 'Télécharger le PDF';
			case 'invoices.action_share_pdf': return 'Partager';
			case 'invoices.action_open_pdf': return 'Ouvrir';
			case 'invoices.action_copy_number': return 'Copier le numéro';
			case 'invoices.action_view_details': return 'Voir le détail';
			case 'invoices.download_progress': return 'Préparation du PDF…';
			case 'invoices.download_success': return 'Enregistré sous {filename}';
			case 'invoices.download_error': return 'Échec du téléchargement. Réessayez.';
			case 'invoices.copied_to_clipboard': return 'Numéro de facture copié.';
			case 'invoices.share_subject': return 'Facture {number}';
			case 'invoices.polling_live': return 'Live';
			case 'invoices.polling_paused': return 'En pause';
			case 'invoices.summary_this_month': return 'Ce mois-ci';
			case 'invoices.pagination_detail': return 'Page {current} sur {total} · {count} factures';
			case 'invoices.sort_sheet_title': return 'Trier';
			case 'invoices.sort_date_newest': return 'Plus récent';
			case 'invoices.sort_date_oldest': return 'Plus ancien';
			case 'invoices.sort_amount_high': return 'Montant · décroissant';
			case 'invoices.sort_amount_low': return 'Montant · croissant';
			case 'invoices.sort_status_az': return 'Statut · A à Z';
			case 'invoices.sort_status_za': return 'Statut · Z à A';
			case 'invoices.date_range_title': return 'Dates';
			case 'invoices.date_from': return 'Du';
			case 'invoices.date_to': return 'Au';
			case 'invoices.clear_dates': return 'Effacer';
			case 'invoices.date_apply': return 'Appliquer';
			case 'invoices.download_all_zip': return 'ZIP';
			case 'invoices.zip_progress': return 'Création du ZIP…';
			case 'invoices.zip_success': return 'Enregistré : {filename}';
			case 'invoices.zip_error': return 'Échec du téléchargement ZIP.';
			case 'push.onboarding_title': return 'Restez informé';
			case 'push.onboarding_subtitle': return 'Recevez des alertes instantanées pour l’essentiel — même lorsque Wayo Ads est en arrière-plan.';
			case 'push.onboarding_bullet_campaigns': return 'Campagnes, candidatures et budgets';
			case 'push.onboarding_bullet_messages': return 'Nouveaux messages dans le chat';
			case 'push.onboarding_bullet_system': return 'Factures, virements et alertes plateforme';
			case 'push.onboarding_enable': return 'Activer les notifications';
			case 'push.onboarding_later': return 'Pas maintenant';
			case 'push.onboarding_success': return 'Notifications activées';
			case 'push.onboarding_denied_hint': return 'Vous pourrez les activer plus tard dans les réglages du téléphone.';
			case 'push.onboarding_context_chat': return 'Vous venez de recevoir un message — activez les alertes pour ne plus manquer une réponse.';
			case 'push.onboarding_context_campaign': return 'Le statut d\'une campagne a changé — activez les notifications pour suivre candidatures et budgets.';
			case 'push.onboarding_context_invoice': return 'Une facture ou un virement vient d\'être mis à jour — soyez alerté dès que l\'argent bouge.';
			case 'creator.dashboard.title': return 'Studio Créateur';
			case 'creator.dashboard.subtitle': return 'Suivez vos statistiques, candidatures et gains en temps réel.';
			case 'creator.dashboard.coming_soon_title': return 'Votre tableau de bord créateur';
			case 'creator.dashboard.coming_soon_subtitle': return 'Statistiques, analyses et candidatures actives s’afficheront ici. Mises à jour en temps réel déjà branchées — pas besoin de rafraîchir.';
			case 'creator.wallet.coming_soon_title': return 'Vos gains';
			case 'creator.wallet.coming_soon_subtitle': return 'Solde disponible, virements en attente et historique Stripe s’afficheront ici.';
			case 'creator.wallet.connect_stripe_title': return 'Connecter Stripe';
			case 'creator.wallet.connect_stripe_subtitle': return 'Associez votre compte bancaire via Stripe pour activer les retraits. Vos données financières ne sont jamais stockées.';
			case 'creator.wallet.withdraw_title': return 'Demander un retrait';
			case 'creator.wallet.withdraw_subtitle': return 'Retirez votre solde disponible vers votre compte Stripe connecté.';
			case 'creator.wallet.available_balance': return 'Disponible';
			case 'creator.wallet.pending_balance': return 'En attente';
			case 'creator.wallet.total_earned': return 'Total gagné';
			case 'creator.wallet.load_error': return 'Impossible de charger votre portefeuille';
			case 'creator.wallet.withdraw_button': return 'Retirer';
			case 'creator.wallet.withdraw_sheet_title': return 'Demander un retrait';
			case 'creator.wallet.withdraw_sheet_subtitle': return 'Solde disponible : {available}. Les fonds seront envoyés vers votre compte Stripe.';
			case 'creator.wallet.withdraw_amount_label': return 'Montant (USD)';
			case 'creator.wallet.withdraw_sheet_body': return 'Entrez le montant que vous souhaitez retirer. Les fonds seront envoyés sur votre compte bancaire connecté.';
			case 'creator.wallet.withdraw_quick_amounts': return 'Montants rapides';
			case 'creator.wallet.withdraw_gross_amount': return 'Montant brut';
			case 'creator.wallet.withdraw_platform_fee': return 'Frais de plateforme ({percent}%)';
			case 'creator.wallet.withdraw_tax_vat': return 'TVA ({percent}%)';
			case 'creator.wallet.withdraw_net_received': return 'Net reçu';
			case 'creator.wallet.withdraw_submit': return 'Confirmer le retrait';
			case 'creator.wallet.withdraw_submitting': return 'Traitement…';
			case 'creator.wallet.withdraw_max': return 'Max';
			case 'creator.wallet.withdraw_preset_all': return 'Tout';
			case 'creator.wallet.withdraw_success': return 'Demande de retrait envoyée.';
			case 'creator.wallet.withdraw_secure_footer': return 'Paiement sécurisé — traité par Stripe. Vos coordonnées bancaires ne nous sont jamais transmises.';
			case 'creator.wallet.withdraw_error_invalid': return 'Saisissez un montant valide.';
			case 'creator.wallet.withdraw_error_min': return 'Retrait minimum : {min}.';
			case 'creator.wallet.withdraw_error_insufficient': return 'Solde disponible insuffisant.';
			case 'creator.wallet.withdraw_reason_business_info': return 'Finalisez vos informations commerciales avant de connecter un compte de paiement.';
			case 'creator.wallet.withdraw_reason_stripe': return 'Connectez Stripe pour activer les retraits.';
			case 'creator.wallet.withdraw_reason_stripe_incomplete': return 'Terminez l’onboarding Stripe pour activer les retraits.';
			case 'creator.wallet.withdraw_reason_payouts_disabled': return 'Votre compte Stripe n’est pas encore validé pour les paiements.';
			case 'creator.wallet.withdraw_reason_below_min': return 'Retrait minimum : {min}.';
			case 'creator.wallet.cancel_action': return 'Annuler la demande';
			case 'creator.wallet.cancel_in_progress': return 'Annulation…';
			case 'creator.wallet.cancel_dialog_title': return 'Annuler ce retrait ?';
			case 'creator.wallet.cancel_dialog_message': return 'Le retrait en attente sera annulé et les fonds reversés à votre solde disponible.';
			case 'creator.wallet.cancel_dialog_yes': return 'Annuler le retrait';
			case 'creator.wallet.cancel_dialog_no': return 'Conserver';
			case 'creator.wallet.cancel_success': return 'Retrait annulé, les fonds ont été restaurés.';
			case 'creator.wallet.stripe_connected': return 'Connecté';
			case 'creator.wallet.stripe_onboarding_required_pill': return 'Action requise';
			case 'creator.wallet.stripe_connect_action': return 'Connecter Stripe';
			case 'creator.wallet.stripe_complete_action': return 'Terminer l’onboarding';
			case 'creator.wallet.stripe_open_dashboard': return 'Ouvrir le tableau Stripe';
			case 'creator.wallet.stripe_error': return 'Un souci est survenu avec Stripe. Veuillez réessayer.';
			case 'creator.wallet.stripe_edit_business_action': return 'Corriger mes infos';
			case 'creator.wallet.stripe_card_title_disconnected': return 'Connecter Stripe';
			case 'creator.wallet.stripe_card_subtitle_disconnected': return 'Associez votre compte bancaire via Stripe pour recevoir vos paiements.';
			case 'creator.wallet.stripe_card_title_incomplete': return 'Terminez votre onboarding';
			case 'creator.wallet.stripe_card_subtitle_incomplete': return 'Stripe a encore besoin de quelques infos avant d’activer les paiements.';
			case 'creator.wallet.stripe_card_title_connected': return 'Stripe est connecté';
			case 'creator.wallet.stripe_card_subtitle_connected': return 'Votre compte Stripe Express est actif. Les paiements arrivent sur votre banque.';
			case 'creator.wallet.history_title': return 'Historique des retraits';
			case 'creator.wallet.history_empty': return 'Aucun retrait pour le moment — l’historique s’affichera ici.';
			case 'creator.wallet.history_load_error': return 'Impossible de charger l’historique des retraits.';
			case 'creator.wallet.history_status_pending': return 'En attente';
			case 'creator.wallet.history_status_processing': return 'En cours';
			case 'creator.wallet.history_status_succeeded': return 'Payé';
			case 'creator.wallet.history_status_failed': return 'Échec';
			case 'creator.wallet.history_status_cancelled': return 'Annulé';
			case 'creator.wallet.conditions_title': return 'Conditions de retrait';
			case 'creator.wallet.conditions_subtitle': return 'À savoir avant de demander un paiement.';
			case 'creator.wallet.conditions_min_label': return 'Retrait minimum';
			case 'creator.wallet.conditions_fee_label': return 'Frais';
			case 'creator.wallet.conditions_fee_value': return ({required Object percent}) => '${percent} (hors TVA)';
			case 'creator.wallet.conditions_processing_label': return 'Délai de traitement';
			case 'creator.wallet.conditions_processing_value': return '2 à 5 jours ouvrés';
			case 'creator.campaigns.browse_title': return 'Explorer les campagnes';
			case 'creator.campaigns.browse_subtitle': return 'Trouvez des campagnes adaptées à votre audience et postulez en un tap.';
			case 'creator.campaigns.browse_search_placeholder': return 'Rechercher par nom, type ou marque';
			case 'creator.campaigns.browse_empty_search_title': return 'Aucune campagne correspondante';
			case 'creator.campaigns.browse_empty_search_subtitle': return 'Essayez un autre mot-clé — nom, type (vidéo, shorts, lien) ou marque annonceur.';
			case 'creator.campaigns.applications_title': return 'Mes candidatures';
			case 'creator.campaigns.applications_subtitle': return 'Suivez le statut — approuvée, en attente, refusée — de chaque campagne.';
			case 'creator.campaigns.submit_title': return 'Soumettre un post';
			case 'creator.campaigns.submit_subtitle': return 'Une fois approuvé, partagez une URL vidéo publique pour que l\'annonceur la valide.';
			case 'creator.campaigns.details_title': return 'Détails de la campagne';
			case 'creator.campaigns.application_title': return 'Ma candidature';
			case 'creator.campaigns.load_error': return 'Impossible de charger les campagnes.';
			case 'creator.campaigns.empty_title': return 'Aucune campagne active';
			case 'creator.campaigns.empty_subtitle': return 'Les nouvelles campagnes apparaîtront ici dès qu\'un annonceur les lancera.';
			case 'creator.campaigns.pagination_previous': return 'Précédent';
			case 'creator.campaigns.pagination_next': return 'Suivant';
			case 'creator.campaigns.pagination_page': return ({required Object current, required Object total}) => 'Page ${current} / ${total}';
			case 'creator.campaigns.description_title': return 'Brief';
			case 'creator.campaigns.requirements_title': return 'Exigences';
			case 'creator.campaigns.assets_title': return 'Assets de la marque';
			case 'creator.campaigns.assets_subtitle': return 'Téléchargez le brief, les logos et les rushs.';
			case 'creator.campaigns.type_link': return 'Lien';
			case 'creator.campaigns.type_video': return 'Vidéo';
			case 'creator.campaigns.type_shorts': return 'Shorts';
			case 'creator.campaigns.reward_cpm_label': return 'CPM';
			case 'creator.campaigns.reward_cpc_label': return 'Rémunération par clic';
			case 'creator.campaigns.reward_per_view_label': return 'Rémunération par vue';
			case 'creator.campaigns.reward_per_view': return ({required Object amount}) => '${amount} / vue';
			case 'creator.campaigns.reward_per_click': return ({required Object amount}) => '${amount} / clic';
			case 'creator.campaigns.budget_remaining_label': return 'Budget restant';
			case 'creator.campaigns.requirement_platform': return ({required Object platform}) => 'Publiez uniquement sur ${platform}';
			case 'creator.campaigns.requirement_min_duration': return ({required Object minutes}) => 'Durée minimale : ${minutes} min';
			case 'creator.campaigns.requirement_shorts_max': return ({required Object seconds}) => 'Shorts jusqu\'à ${seconds} s';
			case 'creator.campaigns.requirement_vertical': return 'Format vertical (9:16) requis';
			case 'creator.campaigns.requirement_none': return 'Aucune exigence particulière.';
			case 'creator.campaigns.apply_cta': return 'Postuler à cette campagne';
			case 'creator.campaigns.apply_title': return 'Postuler';
			case 'creator.campaigns.apply_message_label': return 'Pitch (facultatif)';
			case 'creator.campaigns.apply_message_hint': return 'Expliquez pourquoi vous êtes le bon profil…';
			case 'creator.campaigns.apply_submit': return 'Envoyer la candidature';
			case 'creator.campaigns.apply_in_progress': return 'Envoi…';
			case 'creator.campaigns.apply_error': return 'Impossible d\'envoyer votre candidature. Réessayez.';
			case 'creator.campaigns.apply_success': return 'Candidature envoyée — vous serez notifié dès la décision.';
			case 'creator.campaigns.apply_pending_title': return 'Candidature en revue';
			case 'creator.campaigns.apply_pending_subtitle': return 'Nous vous préviendrons dès que l\'annonceur aura répondu.';
			case 'creator.campaigns.open_application_cta': return 'Ouvrir ma candidature';
			case 'creator.campaigns.chat_with_advertiser': return 'Discuter avec l\'annonceur';
			case 'creator.campaigns.status_banner_approved_title': return 'Vous êtes approuvé !';
			case 'creator.campaigns.status_banner_approved_subtitle': return 'Vous pouvez soumettre votre vidéo et chatter avec l\'annonceur.';
			case 'creator.campaigns.status_banner_pending_title': return 'En attente de l\'annonceur';
			case 'creator.campaigns.status_banner_pending_subtitle': return 'Votre pitch est en revue — vous recevrez une notification ici.';
			case 'creator.campaigns.status_banner_rejected_title': return 'Non retenu cette fois';
			case 'creator.campaigns.status_banner_rejected_subtitle': return 'Gardez un œil sur l\'onglet Campagnes — de nouveaux briefs arrivent chaque semaine.';
			case 'creator.campaigns.my_submissions_title': return 'Mes soumissions';
			case 'creator.campaigns.my_submissions_empty_approved': return 'Aucune vidéo soumise. Envoyez-en une pour commencer à gagner.';
			case 'creator.campaigns.my_submissions_empty_pending': return 'Les soumissions se débloquent une fois votre candidature approuvée.';
			case 'creator.campaigns.submit_cta': return 'Soumettre un post';
			case 'creator.campaigns.submit_platform_label': return 'Plateforme';
			case 'creator.campaigns.submit_url_label': return 'URL publique de la vidéo';
			case 'creator.campaigns.submit_url_hint': return 'https://youtube.com/watch?v=…';
			case 'creator.campaigns.submit_url_required': return 'Collez l\'URL de la vidéo.';
			case 'creator.campaigns.submit_url_invalid': return 'Saisissez une URL publique valide.';
			case 'creator.campaigns.submit_url_youtube_only': return 'Seules les URLs YouTube sont supportées pour l\'instant.';
			case 'creator.campaigns.submit_in_progress': return 'Envoi…';
			case 'creator.campaigns.submit_footer': return 'Votre vidéo doit rester publique pendant la campagne pour valider les vues.';
			case 'creator.campaigns.submit_error': return 'Impossible d\'envoyer votre vidéo. Réessayez.';
			case 'creator.campaigns.submit_success': return 'Vidéo envoyée — l\'annonceur la validera sous peu.';
			case 'creator.campaigns.submit_blocked_limit': return 'Vous avez déjà soumis pour cette campagne. Attendez la revue.';
			case 'creator.campaigns.submission_status_pending': return 'En revue';
			case 'creator.campaigns.submission_status_approved': return 'Approuvé';
			case 'creator.campaigns.submission_status_rejected': return 'Refusé';
			case 'creator.campaigns.submission_status_flagged': return 'Signalé';
			case 'creator.campaigns.submission_views': return ({required Object views}) => '${views} vues validées';
			case 'creator.stats.earnings_title': return 'Gains totaux';
			case 'creator.stats.pending': return 'En attente';
			case 'creator.stats.validated_views': return 'Vues validées';
			case 'creator.stats.validation_rate': return 'Taux de validation';
			case 'creator.stats.approved_campaigns': return 'Campagnes approuvées';
			case 'creator.applications.section_title': return 'Candidatures actives';
			case 'creator.applications.empty_title': return 'Aucune candidature';
			case 'creator.applications.empty_subtitle': return 'Parcourez l’onglet Campagnes et postulez à celles qui correspondent à votre audience.';
			case 'creator.applications.load_error': return 'Impossible de charger vos candidatures';
			case 'creator.applications.status_pending': return 'En attente';
			case 'creator.applications.status_approved': return 'Approuvée';
			case 'creator.applications.status_rejected': return 'Refusée';
			case 'creator.applications.status_withdrawn': return 'Retirée';
			case 'creator.applications.status_unknown': return '—';
			case 'creator.business.cta_title': return 'Finalisez vos informations commerciales';
			case 'creator.business.cta_subtitle': return 'Obligatoire avant de connecter votre compte bancaire — pour router correctement vos paiements.';
			case 'creator.business.cta_required_pill': return 'REQUIS';
			case 'creator.business.cta_button': return 'Finalize your Business Information';
			case 'creator.business.dialog_title': return 'Informations commerciales';
			case 'creator.business.dialog_subtitle': return 'Quelques infos légales pour que Stripe puisse ouvrir votre compte et traiter les paiements.';
			case 'creator.business.section_type': return 'Type d\'entreprise';
			case 'creator.business.section_company': return 'Société';
			case 'creator.business.section_address': return 'Adresse';
			case 'creator.business.section_stripe': return 'Pays et devise de paiement';
			case 'creator.business.type_personal_title': return 'Particulier / Personne privée';
			case 'creator.business.type_personal_subtitle': return 'Je reçois les paiements en tant que particulier.';
			case 'creator.business.type_company_title': return 'Société enregistrée';
			case 'creator.business.type_company_subtitle': return 'J’opère sous une entité juridique enregistrée.';
			case 'creator.business.company_name': return 'Nom de la société';
			case 'creator.business.vat_number': return 'Numéro de TVA';
			case 'creator.business.address_line1': return 'Adresse ligne 1';
			case 'creator.business.address_line2': return 'Adresse ligne 2 (optionnel)';
			case 'creator.business.city': return 'Ville';
			case 'creator.business.postal_code': return 'Code postal';
			case 'creator.business.state_region': return 'Région (optionnel)';
			case 'creator.business.country': return 'Pays';
			case 'creator.business.currency': return 'Devise de paiement';
			case 'creator.business.error_required': return 'Champ requis';
			case 'creator.business.save_and_continue': return 'Enregistrer et continuer';
			case 'creator.business.submitting': return 'Enregistrement…';
			case 'creator.business.footer_info': return 'Ces informations sont transmises à Stripe pour activer votre compte de paiement. Vos coordonnées bancaires ne nous sont jamais transmises.';
			case 'creator.business.save_error': return 'Impossible d’enregistrer vos infos. Veuillez réessayer.';
			case 'advertiser_wallet.hero_title': return 'Votre solde';
			case 'advertiser_wallet.hero_subtitle': return 'Ajoutez des fonds pour lancer des campagnes. Paiements sécurisés via Stripe. Apple Pay (iOS) et Google Pay (Android) sont proposés lorsqu’ils sont disponibles.';
			case 'advertiser_wallet.available': return 'Disponible';
			case 'advertiser_wallet.pending': return 'En attente';
			case 'advertiser_wallet.add_funds': return 'Ajouter des fonds';
			case 'advertiser_wallet.amount_label': return 'Montant';
			case 'advertiser_wallet.quick_50': return '50 €';
			case 'advertiser_wallet.quick_100': return '100 €';
			case 'advertiser_wallet.quick_250': return '250 €';
			case 'advertiser_wallet.min_deposit': return 'Dépôt minimum : 50,00 dans la devise affichée.';
			case 'advertiser_wallet.test_pay': return 'Simuler le paiement (dev)';
			case 'advertiser_wallet.test_hint': return 'Mode test : pas de vraie carte. Crédit portefeuille de dev pour QA.';
			case 'advertiser_wallet.pay_secure': return 'Carte, Apple Pay ou Google Pay';
			case 'advertiser_wallet.pay_with_card': return 'Payer par carte';
			case 'advertiser_wallet.pay_with_apple': return 'Payer avec Apple Pay';
			case 'advertiser_wallet.pay_with_google': return 'Payer avec Google Pay';
			case 'advertiser_wallet.or': return 'ou';
			case 'advertiser_wallet.stripe_unavailable': return 'Rechargement indisponible : le paiement n’est pas configuré côté serveur.';
			case 'advertiser_wallet.tx_title': return 'Activité récente';
			case 'advertiser_wallet.tx_empty': return 'Aucune transaction';
			case 'advertiser_wallet.tx_deposit': return 'Dépôt';
			case 'advertiser_wallet.tx_withdrawal': return 'Retrait';
			case 'advertiser_wallet.tx_other': return 'Opération';
			case 'advertiser_wallet.success': return 'Solde mis à jour';
			case 'advertiser_wallet.failed': return 'Impossible d’ajouter des fonds. Réessayez.';
			case 'advertiser_wallet.in_progress': return 'Traitement…';
			case 'advertiser_wallet.tx_page': return ({required Object current, required Object total}) => 'Page ${current} sur ${total}';
			case 'advertiser_wallet.tx_prev': return 'Précédent';
			case 'advertiser_wallet.tx_next': return 'Suivant';
			case 'advertiser_wallet.business_profile_gate_title': return 'Informations d’entreprise requises';
			case 'advertiser_wallet.business_profile_gate_body': return 'Renseignez des coordonnées de facturation valides avant d’ajouter des fonds — conformité et facturation Wayo Ads.';
			case 'advertiser_wallet.business_profile_gate_secure': return 'Connexion chiffrée — contrôle côté serveur avant tout paiement.';
			case 'advertiser_wallet.business_profile_gate_cta': return 'Renseigner mon activité';
			case 'advertiser_wallet.business_profile_error': return 'Impossible de charger le profil entreprise.';
			case 'advertiser_wallet.pay_locked_until_business': return 'Le paiement sera disponible une fois le profil complété.';
			case 'advertiser_wallet.payment_title': return 'Paiement';
			case 'advertiser_wallet.payment_total': return 'TOTAL';
			case 'advertiser_wallet.payment_deposit_amount': return 'Montant du dépôt';
			case 'advertiser_wallet.payment_bank_fee': return 'Frais de transaction bancaire (3.69%)';
			case 'chat.inbox_title': return 'Messages';
			case 'chat.inbox_subtitle': return 'Conversations sécurisées pour vos campagnes';
			case 'chat.conversation_unknown': return 'Conversation';
			case 'chat.thread_fallback_title': return 'Chat';
			case 'chat.composer_hint': return 'Écrire un message…';
			case 'chat.typing': return 'En train d’écrire…';
			case 'chat.error_load_threads': return 'Impossible de charger vos conversations. Réessayez.';
			case 'chat.error_phone': return 'Le partage de numéros de téléphone dans le chat n’est pas autorisé.';
			case 'chat.spam_cooldown_title': return 'Vous envoyez trop de messages';
			case 'chat.spam_cooldown_body': return ({required Object seconds}) => 'Patientez ${seconds} s avant d’envoyer à nouveau.';
			case 'chat.spam_cooldown_seconds': return ({required Object seconds}) => '${seconds} s';
			case 'chat.empty_threads_title': return 'Aucune conversation';
			case 'chat.empty_threads_hint': return 'Quand quelqu’un vous écrit au sujet d’une campagne, ce sera ici.';
			case 'chat.online': return 'En ligne';
			case 'chat.offline': return 'Hors ligne';
			case 'chat.typing_status': return 'En train d’écrire…';
			case 'chat.attachment': return 'Pièce jointe';
			case 'chat.attachment_image': return 'Photo';
			case 'chat.attachment_pdf': return 'PDF';
			case 'chat.open_file': return 'Ouvrir';
			case 'chat.pick_attachment': return 'Image ou PDF';
			case 'chat.upload_failed': return 'Envoi du fichier impossible. Réessayez.';
			case 'chat.file_too_large': return 'Fichier trop volumineux (max 10 Mo pour les images, 50 Mo pour le PDF).';
			case 'chat.search_users_hint': return 'Rechercher une personne par nom…';
			case 'chat.search_users_no_results': return 'Aucun utilisateur ne correspond.';
			case 'chat.search_users_min_hint': return 'Saisissez au moins 2 caractères pour lancer la recherche.';
			case 'chat.search_prior_chats_hint': return 'Rechercher parmi les personnes avec qui vous avez échangé…';
			case 'chat.search_prior_chats_no_results': return 'Personne ne correspond dans vos conversations.';
			case 'chat.search_prior_chats_min_hint': return 'Saisissez au moins 2 caractères.';
			case 'chat.conversation_open_failed': return 'Impossible d’ouvrir cette conversation. Réessayez.';
			case 'chat.file_picker_restart_hint': return 'Les pièces jointes nécessitent un redémarrage complet de l’app après une mise à jour. Arrêtez l’app puis relancez-la (évitez le hot restart).';
			case 'chat.attachment_type_not_allowed': return 'Seules les images (JPG, PNG, GIF, WebP, BMP) ou les PDF sont autorisées.';
			case 'chat.inbox_swipe_soon': return 'Épingler et archiver depuis la liste arrivent bientôt.';
			case 'chat.date_today': return 'Aujourd\'hui';
			case 'chat.date_yesterday': return 'Hier';
			case 'chat.bubble_reply': return 'Répondre';
			case 'chat.reply_composer_title': return 'Répondre';
			case 'chat.reply_composer_you': return 'Vous';
			case 'chat.composer_reply_hint': return 'Écrivez une réponse…';
			case 'chat.bubble_copy': return 'Copier';
			case 'chat.bubble_react': return 'Réagir';
			case 'chat.bubble_delete': return 'Supprimer';
			case 'chat.bubble_update': return 'Modifier';
			case 'chat.bubble_delete_unavailable': return 'La suppression des messages depuis l\'app n\'est pas encore disponible.';
			case 'chat.bubble_copied': return 'Copié dans le presse-papiers';
			case 'chat.bubble_forward': return 'Transférer';
			case 'chat.share_media_tooltip': return 'Partager';
			case 'chat.share_failed': return 'Impossible de partager ce fichier. Réessayez.';
			case 'chat.forward_sheet_title': return 'Envoyer vers…';
			case 'chat.forward_no_other_chats': return 'Ouvrez ou créez une autre conversation d’abord.';
			case 'chat.forward_sending': return 'Transfert…';
			case 'chat.forward_ok': return 'Message transféré.';
			case 'chat.forward_failed': return 'Échec du transfert.';
			case 'chat.forward_view': return 'Ouvrir';
			case 'chat.edited': return 'modifié';
			case 'chat.seen': return 'Vu';
			case 'chat.delivered': return 'Livré';
			case 'chat.edit_mode_title': return 'Modification du message';
			case 'chat.edit_mode_cancel': return 'Annuler';
			case 'chat.edit_mode_hint': return 'Modifier votre message…';
			case 'chat.edit_failed': return 'Impossible de modifier ce message. Réessayez.';
			case 'chat.edit_not_allowed': return 'Seuls vos messages texte peuvent être modifiés.';
			case 'chat.delete_failed': return 'Impossible de supprimer ce message. Réessayez.';
			case 'chat.delete_not_allowed': return 'Vous ne pouvez supprimer que vos propres messages.';
			case 'chat.delete_confirm_title': return 'Supprimer ce message ?';
			case 'chat.delete_confirm_text': return 'Cette action est irréversible.';
			case 'chat.delete_confirm_cta': return 'Supprimer';
			case 'chat.delete_confirm_cancel': return 'Annuler';
			case 'chat.scroll_to_latest': return 'Récent';
			case 'chat.loading_older_messages': return 'Chargement des messages plus anciens…';
			case 'chat.load_older_failed': return 'Impossible de charger les messages plus anciens.';
			case 'chat.image_download_tooltip': return 'Télécharger la photo';
			case 'chat.image_close_tooltip': return 'Fermer';
			case 'chat.image_saved_to_gallery': return 'Photo enregistrée dans la galerie.';
			case 'chat.image_download_failed': return 'Impossible de télécharger cette photo.';
			case 'chat.image_permission_denied': return 'Accès aux photos refusé. Activez-la dans les réglages.';
			case 'chat.image_saved_downloads_browser': return 'Photo téléchargée — vérifiez votre dossier Téléchargements.';
			case 'common.language': return 'Langue';
			case 'common.theme': return 'Thème';
			case 'common.light': return 'Clair';
			case 'common.dark': return 'Sombre';
			case 'common.system': return 'Système';
			case 'errors.rate_limited': return 'Trop de tentatives. Réessayez dans quelques minutes.';
			case 'errors.invalid_credentials': return 'Identifiants incorrects.';
			case 'errors.network': return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
			case 'errors.server_generic': return 'Une erreur s\'est produite. Réessayez.';
			case 'errors.empty_response': return 'Réponse vide du serveur.';
			case 'errors.login_failed': return 'Échec de la connexion.';
			case 'errors.unknown': return 'Une erreur inattendue s\'est produite.';
			case 'errors.session_invalid': return 'Votre session a expiré. Veuillez vous reconnecter.';
			case 'errors.email_not_found': return 'Aucun compte pour cet email.';
			case 'privacy_policy.title': return 'Politique de confidentialité';
			case 'privacy_policy.last_updated': return 'Dernière mise à jour : 7 octobre 2025';
			case 'privacy_policy.intro_title': return '1. Introduction';
			case 'privacy_policy.intro_body': return 'Chez Wayo Ads, nous nous engageons à collecter et à utiliser vos données de manière responsable, conformément aux lois applicables en matière de protection des données, notamment la loi marocaine n° 09-08 et, le cas échéant, le RGPD (UE 2016/679). En utilisant notre plateforme, vous acceptez la collecte, le traitement et l’utilisation de vos données tel que décrit dans la présente politique de confidentialité.';
			case 'privacy_policy.data_title': return '2. Données que nous collectons';
			case 'privacy_policy.data_body': return 'Nous ne collectons que les données nécessaires, conformément à la loi 09-08 et, le cas échéant, au RGPD.\n\nPour les annonceurs\n• Identification et contact : raison sociale, adresse e-mail, numéro de téléphone.\n• Profil : logo d’entreprise (si fourni), description de l’entreprise.\n• Campagnes : contenu des campagnes, budgets, critères de ciblage, données analytiques.\n\nPour les créateurs\n• Identification et contact : nom, adresse e-mail, numéro de téléphone.\n• Profil : photo de profil (si fournie), biographie, domaines d’expertise, liens vers les réseaux sociaux.\n• Contenu : vidéos, publications et supports que vous téléversez.\n• Données d’usage : interactions avec la plateforme, statistiques d’engagement, données de rémunération.\n\nInformations techniques (tous les utilisateurs)\n• Données techniques : adresse IP, type et version du navigateur, type d’appareil, système d’exploitation, identifiants de session, horodatages, pages visitées, clics, référents.\n• Cookies et technologies similaires : voir la section 8 (Cookies).\n\nDonnées de paiement\n• Transactions : montants, devise, date, moyen de paiement, adresse de facturation.\n• Important : les données de carte bancaire sont traitées exclusivement par notre prestataire de paiement (Stripe). Wayo Ads ne stocke pas les informations de carte bancaire.';
			case 'privacy_policy.purpose_title': return '3. Finalités du traitement';
			case 'privacy_policy.purpose_body': return 'Nous utilisons vos données pour : fournir, maintenir et améliorer nos services ; personnaliser l’expérience et recommander du contenu pertinent ; gérer la relation contractuelle (comptes, facturation, support) ; communiquer des informations relatives au service (mises à jour, changements, alertes) ; assurer la sécurité et l’intégrité de la plateforme (détection d’abus et de fraude) ; et réaliser des analyses d’usage avec des données agrégées ou anonymisées lorsque cela est possible.';
			case 'privacy_policy.legal_bases_title': return '4. Bases juridiques du traitement';
			case 'privacy_policy.legal_bases_body': return 'Selon les cas, nous nous appuyons sur : votre consentement (par exemple, cookies non essentiels, newsletters) ; l’exécution d’un contrat ou de mesures précontractuelles (par exemple, inscription, facturation) ; le respect d’une obligation légale (par exemple, conservation des factures) ; et notre intérêt légitime (par exemple, sécurité, amélioration du service).';
			case 'privacy_policy.sharing_title': return '5. Partage de vos informations';
			case 'privacy_policy.sharing_body': return 'Wayo Ads ne vend pas vos données personnelles. Un partage limité peut avoir lieu avec : des prestataires essentiels (processeurs de paiement, hébergeurs, outils d’e-mailing, analytique) ; et pour des motifs légaux si la loi l’exige ou en réponse à une demande légitime d’une autorité compétente.';
			case 'privacy_policy.security_title': return '6. Sécurité des données';
			case 'privacy_policy.security_body': return 'Nous mettons en œuvre notamment : le chiffrement TLS/HTTPS pour les données en transit ; des contrôles d’accès selon le principe du besoin d’en connaître ; des sauvegardes régulières et des procédures de restauration ; des mises à jour de sécurité et des audits périodiques ; ainsi que la journalisation et la détection d’activités anormales.';
			case 'privacy_policy.content_title': return '7. Responsabilités des utilisateurs et protection du contenu';
			case 'privacy_policy.content_body': return 'Vous devez respecter les droits de propriété intellectuelle des créateurs et de Wayo Ads. Ne copiez, ne partagez, ne redistribuez et ne revendez pas de contenu sans autorisation. Toute violation peut entraîner la suspension du compte et, le cas échéant, des poursuites.';
			case 'privacy_policy.cookies_title': return '8. Cookies et technologies de suivi';
			case 'privacy_policy.cookies_body': return 'Nous utilisons : des cookies essentiels (fonctionnement du site, sécurité, session) ; et des cookies analytiques (par exemple, Google Analytics) pour la mesure d’audience. Les cookies non essentiels ne sont déposés qu’avec votre consentement via une bannière cookies lors de votre première visite.';
			case 'privacy_policy.retention_title': return '9. Conservation des données';
			case 'privacy_policy.retention_body': return 'Nous conservons vos données uniquement le temps nécessaire aux finalités décrites dans la présente politique. Les données de compte sont conservées pendant la durée de vie du compte, augmentée de toute période légale de conservation. Les données de transaction sont conservées conformément aux obligations comptables et fiscales.';
			case 'privacy_policy.children_title': return '10. Vie privée des enfants';
			case 'privacy_policy.children_body': return 'Nos services ne s’adressent pas aux mineurs de moins de 18 ans. Nous ne collectons pas sciemment d’informations personnelles auprès d’enfants. Si nous apprenons que des données ont été collectées auprès d’un enfant sans le consentement parental, nous prendrons des mesures pour les supprimer.';
			case 'privacy_policy.changes_title': return '11. Modifications de la présente politique';
			case 'privacy_policy.changes_body': return 'Nous pouvons mettre à jour cette politique de confidentialité occasionnellement. Nous vous informerons des changements importants en publiant la nouvelle politique sur cette page et en mettant à jour la date de « Dernière mise à jour ».';
			case 'privacy_policy.contact_title': return '12. Coordonnées';
			case 'privacy_policy.contact_body': return 'Responsable du traitement : Wayo, Dubaï, Émirats arabes unis.\nE-mail : info@wayo.cloud\nAdresse : R320 Umm Hurair 2, Dubaï, Émirats arabes unis.';
			case 'app_settings.title': return 'Préférences';
			case 'app_settings.subtitle': return 'Apparence et langue';
			case 'app_settings.section_appearance': return 'Apparence';
			case 'app_settings.section_language': return 'Langue';
			case 'app_settings.theme_light': return 'Clair';
			case 'app_settings.theme_dark': return 'Sombre';
			case 'app_settings.theme_system': return 'Système';
			case 'app_settings.theme_hint': return 'Choisissez l’apparence de Wayo Ads. Système suit le réglage du téléphone.';
			case 'app_settings.language_hint': return 'Langue de l’interface. Dates et formats suivent la locale.';
			case 'app_settings.design_variant': return 'Style du panneau';
			case 'app_settings.design_glass': return 'Verre doux';
			case 'app_settings.design_corporate': return 'Corporate';
			case 'app_settings.close': return 'Fermer';
			case 'app_settings.open_semantics': return 'Ouvrir préférences et langue';
			case 'app_settings.close_semantics': return 'Fermer les préférences';
			case 'app_settings.profile_fallback': return 'Compte';
			case 'app_settings.selected': return 'Sélectionné';
			case 'app_settings.lang_en': return 'English';
			case 'app_settings.lang_fr': return 'Français';
			case 'app_settings.lang_ar': return 'العربية';
			case 'app_settings.section_notifications': return 'Notifications';
			case 'app_settings.notifications_toggle': return 'Notifications push';
			case 'app_settings.notifications_hint': return 'Alertes campagnes, chat, factures et paiements. Autorisation requise dans les réglages du téléphone.';
			case 'app_settings.notifications_status_enabled': return 'Activées — vous recevrez les alertes sur cet appareil';
			case 'app_settings.notifications_status_disabled': return 'Désactivées dans l’application';
			case 'app_settings.notifications_status_permission_denied': return 'Autorisez les notifications dans les réglages du téléphone';
			case 'app_settings.notifications_open_settings': return 'Ouvrir les réglages';
			case 'app_settings.notifications_enable_error': return 'Impossible d’activer les notifications. Vérifiez les réglages système.';
			case 'app_settings.notifications_update_error': return 'Impossible de mettre à jour les notifications. Réessayez.';
			case 'app_settings.section_account': return 'Compte';
			case 'app_settings.delete_account_entry': return 'Supprimer le compte';
			case 'app_settings.delete_account_entry_sub': return 'Délai de 30 jours — suppression dans l’app';
			case 'app_settings.section_about': return 'À propos';
			case 'app_settings.rate_app': return 'Noter Wayo Ads';
			case 'app_settings.rate_app_sub': return 'Ouvre l’App Store ou Google Play';
			case 'account_deletion.nav_title': return 'Suppression de compte';
			case 'account_deletion.title': return 'Supprimer mon compte Wayo Ads';
			case 'account_deletion.danger_zone_chip': return 'Zone de danger';
			case 'account_deletion.danger_zone_intro': return 'Supprime définitivement votre compte et toutes les données associées. À l’issue de la période de grâce, cette action ne pourra pas être annulée.';
			case 'account_deletion.danger_what_title': return 'Ce qui sera supprimé :';
			case 'account_deletion.danger_item_profile': return 'Votre profil et vos informations personnelles';
			case 'account_deletion.danger_item_campaigns': return 'Toutes vos campagnes et leurs données de performance';
			case 'account_deletion.danger_item_business': return 'Votre profil entreprise et les informations de marque';
			case 'account_deletion.danger_item_wallet': return 'Votre portefeuille annonceur et l’historique des transactions';
			case 'account_deletion.danger_item_notifications': return 'Vos notifications et préférences e-mail';
			case 'account_deletion.danger_item_access': return 'Votre accès à Wayo Ads (vous ne pourrez plus vous connecter ici)';
			case 'account_deletion.danger_wayo_note': return 'Seules les données Wayo Ads sont concernées. Votre compte Wayo (utilisé pour vous connecter) reste actif pour les autres services Wayo.';
			case 'account_deletion.subtitle_warning': return 'Important : au bout de 30 jours, vos données Wayo Ads seront supprimées définitivement. Vous pouvez annuler à tout moment avant cette date.';
			case 'account_deletion.bullet_loss': return 'Campagnes, candidatures et données de profil côté application seront supprimées après le délai.';
			case 'account_deletion.bullet_wallet': return 'Solde portefeuille, factures et historique des transactions liés à ce compte seront supprimés.';
			case 'account_deletion.bullet_cancel': return 'Annulation gratuite pendant 30 jours à compter de la demande.';
			case 'account_deletion.bullet_recreate': return 'Votre Wayo ID (connexion) n’est pas supprimé par cette étape — vous pourrez vous reconnecter avec un nouveau profil applicatif.';
			case 'account_deletion.role_advertiser': return 'Annonceur : les campagnes actives s’arrêtent lorsque les données sont purgées.';
			case 'account_deletion.role_creator': return 'Créateur : candidatures, chaînes et gains dans l’app seront supprimés.';
			case 'account_deletion.continue_cta': return 'Continuer';
			case 'account_deletion.back': return 'Retour';
			case 'account_deletion.more_info_title': return 'Avant de continuer';
			case 'account_deletion.more_info_body': return 'E-mails : confirmation immédiate, puis un rappel environ 3 jours avant la suppression.\nSupport : contactez-nous pour exporter des données ou clôturer des campagnes.';
			case 'account_deletion.step_auth_title': return 'Confirmer votre identité';
			case 'account_deletion.status_active': return 'Aucune suppression en cours pour ce compte.';
			case 'account_deletion.status_pending': return ({required Object date}) => 'Suppression déjà planifiée. Date finale : ${date}';
			case 'account_deletion.password_label': return 'Mot de passe';
			case 'account_deletion.password_hint': return 'Au moins 8 caractères';
			case 'account_deletion.forgot_password': return 'Mot de passe oublié ?';
			case 'account_deletion.oauth_note': return 'Si vous utilisez uniquement Google ou Apple, définissez d’abord un mot de passe (Mot de passe oublié).';
			case 'account_deletion.oauth_deletion_intro': return 'Vous vous connectez avec Google ou Apple. Après « Continuer », confirmez à l’étape suivante — aucun mot de passe requis.';
			case 'account_deletion.oauth_deletion_step_hint': return 'Votre identité a été vérifiée à la connexion Google ou Apple. Touchez le bouton ci-dessous pour afficher la feuille de confirmation finale.';
			case 'account_deletion.legal_recap': return ({required Object date}) => 'Vous lancez une période de grâce de 30 jours avant suppression définitive. Vous pouvez annuler jusqu’au ${date}.';
			case 'account_deletion.next_review': return 'Vérifier et confirmer';
			case 'account_deletion.dialog_title': return 'Confirmer ?';
			case 'account_deletion.dialog_body': return 'Vos données Wayo Ads seront planifiées pour suppression. Suppression définitive le :';
			case 'account_deletion.dialog_cancel_hint': return 'Vous pouvez annuler à tout moment dans les paramètres jusqu’à cette date.';
			case 'account_deletion.timeline_request': return 'Demande';
			case 'account_deletion.timeline_reminder': return 'Rappel e-mail';
			case 'account_deletion.timeline_purge': return 'Suppression';
			case 'account_deletion.dialog_confirm': return 'Oui, planifier la suppression';
			case 'account_deletion.dialog_dismiss': return 'Garder mon compte';
			case 'account_deletion.success_title': return 'Suppression planifiée';
			case 'account_deletion.success_intro': return 'Que se passe-t-il maintenant ?';
			case 'account_deletion.success_use_until': return 'Vous pouvez continuer à utiliser Wayo Ads jusqu’à la date limite.';
			case 'account_deletion.success_reminder': return 'Nous vous enverrons un rappel quelques jours avant la suppression.';
			case 'account_deletion.success_cancel_anytime': return 'Annulez à tout moment depuis cet écran ou les paramètres.';
			case 'account_deletion.days_left': return ({required Object n}) => 'Jours restants : ${n}';
			case 'account_deletion.purge_date': return ({required Object date}) => 'Suppression définitive : ${date}';
			case 'account_deletion.reminder_approx': return ({required Object date}) => 'Rappel vers le : ${date}';
			case 'account_deletion.cancel_request': return 'Annuler la suppression';
			case 'account_deletion.go_home': return 'Retour à l’accueil';
			case 'account_deletion.toast_cancelled': return 'Suppression annulée. Votre compte est rétabli.';
			case 'account_deletion.error_load': return 'Impossible de charger le statut du compte.';
			case 'account_deletion.error_load_unauthorized': return 'Impossible de vérifier votre session Wayo Ads. Déconnectez-vous, reconnectez-vous, puis réessayez.';
			case 'account_deletion.error_load_network': return 'Vérifiez votre connexion et l’accessibilité de Wayo Ads, puis réessayez.';
			case 'account_deletion.error_delete': return 'Une erreur s’est produite. Réessayez.';
			case 'account_deletion.error_password': return 'Mot de passe incorrect. Réessayez ou réinitialisez votre mot de passe.';
			case 'account_deletion.banner_line': return ({required Object date, required Object n}) => 'Votre compte sera supprimé le ${date} (${n} jours restants).';
			case 'account_deletion.banner_cancel_dialog_title': return 'Annuler la suppression planifiée ?';
			case 'account_deletion.banner_cancel_dialog_body': return 'Votre profil Wayo Ads restera actif.';
			case 'account_deletion.banner_cancel_dialog_confirm': return 'Garder mon compte';
			case 'account_deletion.pending_danger_card_body': return ({required Object date}) => 'Votre compte est programmé pour une suppression définitive le ${date}. Vous pouvez annuler cette demande à tout moment avant cette date.';
			case 'account_deletion.pending_scheduled_status': return 'Suppression du compte planifiée';
			case 'account_deletion.pending_days_remaining_one': return 'Il reste 1 jour';
			case 'account_deletion.pending_days_remaining_plural': return ({required Object n}) => 'Il reste ${n} jours';
			case 'onboarding.role_gate_title': return 'Choisissez votre profil';
			case 'onboarding.role_gate_subtitle': return 'Même étape que sur le site Wayo Ads avant d’utiliser l’app.';
			case 'onboarding.role_creator_cta': return 'Créateur';
			case 'onboarding.role_creator_desc': return 'Parcourez les campagnes, postulez et collaborez avec les marques.';
			case 'onboarding.role_advertiser_cta': return 'Annonceur';
			case 'onboarding.role_advertiser_desc': return 'Lancez des campagnes et pilotez les créateurs depuis votre tableau de bord.';
			case 'onboarding.email_code_title': return 'Vérifiez votre email';
			case 'onboarding.email_code_subtitle': return ({required Object email}) => 'Saisissez le code à 6 chiffres envoyé à ${email}.';
			case 'onboarding.skip': return 'Passer';
			case 'onboarding.next': return 'Suivant';
			case 'onboarding.done': return 'Compris';
			case 'onboarding.advertiser.dashboard_title': return 'Votre tableau de bord';
			case 'onboarding.advertiser.dashboard_subtitle': return 'Suivez votre solde, vos campagnes actives et vos notifications — tout se met à jour en temps réel.';
			case 'onboarding.advertiser.campaigns_title': return 'Campagnes';
			case 'onboarding.advertiser.campaigns_subtitle': return 'Créez de nouvelles campagnes, examinez les candidatures et suivez les performances au même endroit.';
			case 'onboarding.advertiser.wallet_title': return 'Portefeuille';
			case 'onboarding.advertiser.wallet_subtitle': return 'Rechargez votre budget et suivez vos dépenses — sécurisé par Stripe.';
			case 'onboarding.advertiser.invoices_title': return 'Factures';
			case 'onboarding.advertiser.invoices_subtitle': return 'Téléchargez vos PDF signés : dépôts, facturation des campagnes et virements — tout au même endroit.';
			case 'onboarding.advertiser.chat_title': return 'Chat';
			case 'onboarding.advertiser.chat_subtitle': return 'Discutez avec vos créateurs une fois la campagne validée. Vos conversations restent synchronisées.';
			case 'onboarding.creator.dashboard_title': return 'Dashboard créateur';
			case 'onboarding.creator.dashboard_subtitle': return 'Vos KPIs, candidatures actives et revenus se rafraîchissent automatiquement — sans geste de votre part.';
			case 'onboarding.creator.campaigns_title': return 'Parcourir & postuler';
			case 'onboarding.creator.campaigns_subtitle': return 'Découvrez les campagnes éligibles, postulez en un clic et suivez l\'état de vos candidatures en direct.';
			case 'onboarding.creator.wallet_title': return 'Revenus & retraits';
			case 'onboarding.creator.wallet_subtitle': return 'Consultez votre solde, demandez un retrait via Stripe Connect et retrouvez vos paiements.';
			case 'onboarding.creator.invoices_title': return 'Relevés de paiement';
			case 'onboarding.creator.invoices_subtitle': return 'Filtrez revenus et virements, téléchargez des PDF signés ou un ZIP — tout se met à jour automatiquement.';
			case 'onboarding.creator.chat_title': return 'Discuter avec l\'annonceur';
			case 'onboarding.creator.chat_subtitle': return 'Dès l\'approbation, le chat s\'ouvre pour vous aligner avec l\'annonceur sur la livraison.';
			default: return null;
		}
	}
}

