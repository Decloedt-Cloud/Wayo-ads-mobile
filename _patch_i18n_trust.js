const fs = require('fs');
const path = 'c:/Users/MaskiAymen/Desktop/Wayo/Wayo-ads-mobile/lib/i18n';
const fr = {
  trust: {
    title: 'Score de confiance',
    tier: 'Niveau $name',
    verified: 'Vérifié',
    delta_up: '+$value cette semaine',
    delta_down: '-$value cette semaine',
    cpm_hint: 'Hausse CPM potentielle : $value',
    breakdown_title: 'Détail du score',
    validation_points: 'Taux de validation',
    fraud_points: 'Score fraude',
    anomaly_points: 'Score anomalie',
    open_analytics: 'Voir les analytics',
  },
  analytics: {
    title: 'Analytics créateur',
    period_7d: '7j',
    period_30d: '30j',
    period_90d: '90j',
    load_error: 'Impossible de charger les analytics',
    empty: 'Pas encore de données pour cette période',
    earnings: 'Gains',
    pending: 'En attente',
    validated_views: 'Vues validées',
    validated_clicks: 'Clics validés',
    view_validation_rate: 'Validation vues',
    click_validation_rate: 'Validation clics',
    daily_title: 'Quotidien',
    by_campaign: 'Par campagne',
    server_authority_note:
      "Montants et taux viennent du serveur. L'app n'invente pas de règles financières.",
  },
};
const ar = {
  trust: {
    title: 'درجة الثقة',
    tier: 'المستوى $name',
    verified: 'موثّق',
    delta_up: '+$value هذا الأسبوع',
    delta_down: '-$value هذا الأسبوع',
    cpm_hint: 'ارتفاع CPM محتمل: $value',
    breakdown_title: 'تفصيل الدرجة',
    validation_points: 'معدل التحقق',
    fraud_points: 'درجة الاحتيال',
    anomaly_points: 'درجة الشذوذ',
    open_analytics: 'عرض التحليلات',
  },
  analytics: {
    title: 'تحليلات المنشئ',
    period_7d: '7ي',
    period_30d: '30ي',
    period_90d: '90ي',
    load_error: 'تعذّر تحميل التحليلات',
    empty: 'لا توجد بيانات لهذه الفترة بعد',
    earnings: 'الأرباح',
    pending: 'قيد الانتظار',
    validated_views: 'مشاهدات موثّقة',
    validated_clicks: 'نقرات موثّقة',
    view_validation_rate: 'تحقق المشاهدات',
    click_validation_rate: 'تحقق النقرات',
    daily_title: 'يومي',
    by_campaign: 'حسب الحملة',
    server_authority_note:
      'المبالغ والمعدلات من الخادم. التطبيق لا يخترع قواعد مالية.',
  },
};
function patch(file, block) {
  const j = JSON.parse(fs.readFileSync(file, 'utf8'));
  Object.assign(j.creator, block);
  fs.writeFileSync(file, JSON.stringify(j, null, 2) + '\n');
  console.log('ok', file);
}
patch(path + '/strings_fr.i18n.json', fr);
patch(path + '/strings_ar.i18n.json', ar);
