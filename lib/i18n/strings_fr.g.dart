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
	@override late final _TranslationsCreatorFr creator = _TranslationsCreatorFr._(_root);
	@override late final _TranslationsAdvertiserWalletFr advertiser_wallet = _TranslationsAdvertiserWalletFr._(_root);
	@override late final _TranslationsChatFr chat = _TranslationsChatFr._(_root);
	@override late final _TranslationsCommonFr common = _TranslationsCommonFr._(_root);
	@override late final _TranslationsErrorsFr errors = _TranslationsErrorsFr._(_root);
	@override late final _TranslationsPrivacyPolicyFr privacy_policy = _TranslationsPrivacyPolicyFr._(_root);
	@override late final _TranslationsAppSettingsFr app_settings = _TranslationsAppSettingsFr._(_root);
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
	@override String get cta => 'Se connecter avec Wayo';
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
	@override String get google_not_configured => 'Connexion Google non configurée. Ajoutez AUTH_GOOGLE_SERVER_CLIENT_ID dans dart_defines.json (ID client Web Google se terminant par .apps.googleusercontent.com), puis redémarrez complètement l’app.';
	@override String get google_wrong_client_id => 'AUTH_GOOGLE_SERVER_CLIENT_ID doit être l’ID client Web Google Cloud (…apps.googleusercontent.com), pas l’UUID du client OAuth Passport.';
	@override String get google_failed => 'Échec de la connexion Google. Réessayez.';
	@override String get google_channel_restart => 'Connexion Google interrompue avec Android (souvent après un hot restart). Arrêtez complètement l’app puis Relancer — évitez le hot restart.';
	@override String get google_android_oauth_misconfigured => 'Google n’a pas pu vérifier l’app (code 10). Dans Google Cloud Console, même projet que l’ID client Web : ajoutez un client OAuth de type Android avec le package ma.wayo.wayoadsgo et l’empreinte SHA-1 du keystore (debug ou release), attendez quelques minutes puis réessayez.';
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
	@override String get notifications_view_all => 'Voir toutes les notifications';
	@override String get notifications_important => 'Important';
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
	@override String get subtitle => 'Suivez les performances de vos campagnes — consultation uniquement.';
	@override late final _TranslationsAdvertiserCampaignsTabsFr tabs = _TranslationsAdvertiserCampaignsTabsFr._(_root);
	@override String get search_placeholder => 'Rechercher une campagne';
	@override late final _TranslationsAdvertiserCampaignsEmptyFr empty = _TranslationsAdvertiserCampaignsEmptyFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsCardFr card = _TranslationsAdvertiserCampaignsCardFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsStatusFr status = _TranslationsAdvertiserCampaignsStatusFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsPlatformFr platform = _TranslationsAdvertiserCampaignsPlatformFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsDetailFr detail = _TranslationsAdvertiserCampaignsDetailFr._(_root);
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
	@override String get withdraw_amount_label => 'Montant';
	@override String get withdraw_submit => 'Confirmer le retrait';
	@override String get withdraw_submitting => 'Traitement…';
	@override String get withdraw_max => 'Max';
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
	@override String get section_type => 'Type de compte';
	@override String get section_company => 'Société';
	@override String get section_address => 'Adresse';
	@override String get section_stripe => 'Pays et devise de paiement';
	@override String get type_personal_title => 'Particulier';
	@override String get type_personal_subtitle => 'Je reçois les paiements en tant que particulier.';
	@override String get type_sole_title => 'Auto-entrepreneur';
	@override String get type_sole_subtitle => 'J’exerce en freelance sous mon nom.';
	@override String get type_company_title => 'Société immatriculée';
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
	@override String get wallet_subtitle => 'Rechargez votre budget, consultez vos factures et votre historique — sécurisé par Stripe.';
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
			case 'login.brand': return 'Wayo Ads';
			case 'login.headline_line1': return 'Bienvenue';
			case 'login.headline_line2_prefix': return 'sur ';
			case 'login.headline_brand': return 'Wayo Ads';
			case 'login.subtitle': return 'Connectez-vous avec votre compte Wayo ID pour gérer vos campagnes et vos collaborations.';
			case 'login.cta': return 'Se connecter avec Wayo';
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
			case 'login.google_not_configured': return 'Connexion Google non configurée. Ajoutez AUTH_GOOGLE_SERVER_CLIENT_ID dans dart_defines.json (ID client Web Google se terminant par .apps.googleusercontent.com), puis redémarrez complètement l’app.';
			case 'login.google_wrong_client_id': return 'AUTH_GOOGLE_SERVER_CLIENT_ID doit être l’ID client Web Google Cloud (…apps.googleusercontent.com), pas l’UUID du client OAuth Passport.';
			case 'login.google_failed': return 'Échec de la connexion Google. Réessayez.';
			case 'login.google_channel_restart': return 'Connexion Google interrompue avec Android (souvent après un hot restart). Arrêtez complètement l’app puis Relancer — évitez le hot restart.';
			case 'login.google_android_oauth_misconfigured': return 'Google n’a pas pu vérifier l’app (code 10). Dans Google Cloud Console, même projet que l’ID client Web : ajoutez un client OAuth de type Android avec le package ma.wayo.wayoadsgo et l’empreinte SHA-1 du keystore (debug ou release), attendez quelques minutes puis réessayez.';
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
			case 'dashboard.notifications_view_all': return 'Voir toutes les notifications';
			case 'dashboard.notifications_important': return 'Important';
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
			case 'advertiser_campaigns.subtitle': return 'Suivez les performances de vos campagnes — consultation uniquement.';
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
			case 'creator.wallet.withdraw_amount_label': return 'Montant';
			case 'creator.wallet.withdraw_submit': return 'Confirmer le retrait';
			case 'creator.wallet.withdraw_submitting': return 'Traitement…';
			case 'creator.wallet.withdraw_max': return 'Max';
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
			case 'creator.business.section_type': return 'Type de compte';
			case 'creator.business.section_company': return 'Société';
			case 'creator.business.section_address': return 'Adresse';
			case 'creator.business.section_stripe': return 'Pays et devise de paiement';
			case 'creator.business.type_personal_title': return 'Particulier';
			case 'creator.business.type_personal_subtitle': return 'Je reçois les paiements en tant que particulier.';
			case 'creator.business.type_sole_title': return 'Auto-entrepreneur';
			case 'creator.business.type_sole_subtitle': return 'J’exerce en freelance sous mon nom.';
			case 'creator.business.type_company_title': return 'Société immatriculée';
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
			case 'chat.inbox_title': return 'Messages';
			case 'chat.inbox_subtitle': return 'Conversations sécurisées pour vos campagnes';
			case 'chat.conversation_unknown': return 'Conversation';
			case 'chat.thread_fallback_title': return 'Chat';
			case 'chat.composer_hint': return 'Écrire un message…';
			case 'chat.typing': return 'En train d’écrire…';
			case 'chat.error_load_threads': return 'Impossible de charger vos conversations. Réessayez.';
			case 'chat.error_phone': return 'Le partage de numéros de téléphone dans le chat n’est pas autorisé.';
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
			case 'onboarding.advertiser.wallet_subtitle': return 'Rechargez votre budget, consultez vos factures et votre historique — sécurisé par Stripe.';
			case 'onboarding.advertiser.chat_title': return 'Chat';
			case 'onboarding.advertiser.chat_subtitle': return 'Discutez avec vos créateurs une fois la campagne validée. Vos conversations restent synchronisées.';
			case 'onboarding.creator.dashboard_title': return 'Dashboard créateur';
			case 'onboarding.creator.dashboard_subtitle': return 'Vos KPIs, candidatures actives et revenus se rafraîchissent automatiquement — sans geste de votre part.';
			case 'onboarding.creator.campaigns_title': return 'Parcourir & postuler';
			case 'onboarding.creator.campaigns_subtitle': return 'Découvrez les campagnes éligibles, postulez en un clic et suivez l\'état de vos candidatures en direct.';
			case 'onboarding.creator.wallet_title': return 'Revenus & retraits';
			case 'onboarding.creator.wallet_subtitle': return 'Consultez votre solde, demandez un retrait via Stripe Connect et retrouvez vos paiements.';
			case 'onboarding.creator.chat_title': return 'Discuter avec l\'annonceur';
			case 'onboarding.creator.chat_subtitle': return 'Dès l\'approbation, le chat s\'ouvre pour vous aligner avec l\'annonceur sur la livraison.';
			default: return null;
		}
	}
}

