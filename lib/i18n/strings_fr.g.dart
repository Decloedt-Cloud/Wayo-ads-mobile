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
	@override late final _TranslationsLoginFr login = _TranslationsLoginFr._(_root);
	@override late final _TranslationsForgotPasswordFr forgot_password = _TranslationsForgotPasswordFr._(_root);
	@override late final _TranslationsOtpFr otp = _TranslationsOtpFr._(_root);
	@override late final _TranslationsResetPasswordFr reset_password = _TranslationsResetPasswordFr._(_root);
	@override late final _TranslationsValidationFr validation = _TranslationsValidationFr._(_root);
	@override late final _TranslationsHomeFr home = _TranslationsHomeFr._(_root);
	@override late final _TranslationsDashboardFr dashboard = _TranslationsDashboardFr._(_root);
	@override late final _TranslationsAdvertiserCampaignsFr advertiser_campaigns = _TranslationsAdvertiserCampaignsFr._(_root);
	@override late final _TranslationsNavFr nav = _TranslationsNavFr._(_root);
	@override late final _TranslationsChatFr chat = _TranslationsChatFr._(_root);
	@override late final _TranslationsCommonFr common = _TranslationsCommonFr._(_root);
	@override late final _TranslationsErrorsFr errors = _TranslationsErrorsFr._(_root);
	@override late final _TranslationsPrivacyPolicyFr privacy_policy = _TranslationsPrivacyPolicyFr._(_root);
	@override late final _TranslationsAppSettingsFr app_settings = _TranslationsAppSettingsFr._(_root);
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
	@override String get theme_toggle_tooltip => 'Basculer entre thème clair et sombre';
	@override String get refresh => 'Actualiser le tableau de bord';
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
	@override String get approved_creators => 'Créateurs approuvés';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		switch (path) {
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
			case 'dashboard.theme_toggle_tooltip': return 'Basculer entre thème clair et sombre';
			case 'dashboard.refresh': return 'Actualiser le tableau de bord';
			case 'advertiser_campaigns.title': return 'Campagnes';
			case 'advertiser_campaigns.subtitle': return 'Suivez les performances de vos campagnes — consultation uniquement.';
			case 'advertiser_campaigns.tabs.active': return 'Actives';
			case 'advertiser_campaigns.tabs.paused': return 'En pause';
			case 'advertiser_campaigns.tabs.completed': return 'Terminées';
			case 'advertiser_campaigns.search_placeholder': return 'Rechercher une campagne';
			case 'advertiser_campaigns.empty.none': return 'Aucune campagne';
			case 'advertiser_campaigns.empty.hint': return 'Vous n\'avez pas encore de campagne pour ce statut.';
			case 'advertiser_campaigns.empty.search': return 'Aucun résultat pour cette recherche';
			case 'advertiser_campaigns.empty.search_hint': return 'Essayez un autre nom ou effacez la recherche.';
			case 'advertiser_campaigns.card.budget_total': return 'Budget';
			case 'advertiser_campaigns.card.remaining': return 'Restant';
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
			case 'advertiser_campaigns.detail.approved_creators': return 'Créateurs approuvés';
			case 'nav.dashboard': return 'Tableau de bord';
			case 'nav.campaigns': return 'Campagnes';
			case 'nav.analytics': return 'Analytique';
			case 'nav.wallet': return 'Portefeuille';
			case 'nav.chat': return 'Messages';
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
			default: return null;
		}
	}
}

