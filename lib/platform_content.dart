import 'package:cloud_firestore/cloud_firestore.dart';

class PublicSiteContent {
  final String heroTitle;
  final String heroSubtitle;
  final String aboutTitle;
  final String aboutBody;
  final String infoTitle;
  final String infoBody;
  final String supportEmail;
  final String primaryCtaLabel;

  const PublicSiteContent({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.aboutTitle,
    required this.aboutBody,
    required this.infoTitle,
    required this.infoBody,
    required this.supportEmail,
    required this.primaryCtaLabel,
  });

  factory PublicSiteContent.fromMap(Map<String, dynamic>? data) {
    return PublicSiteContent(
      heroTitle: _readString(
        data?['heroTitle'],
        fallback: 'Kelola toko, laporan, dan insight AI dalam satu ekosistem.',
      ),
      heroSubtitle: _readString(
        data?['heroSubtitle'],
        fallback:
            'SmartLaba menghadirkan dashboard operasional, manajemen kasir, analisis laba, dan website bisnis yang sinkron dengan aplikasi mobile.',
      ),
      aboutTitle: _readString(
        data?['aboutTitle'],
        fallback: 'Tentang SmartLaba',
      ),
      aboutBody: _readString(
        data?['aboutBody'],
        fallback:
            'SmartLaba dibuat untuk owner toko yang butuh operasional rapi, data realtime, dan keputusan bisnis yang lebih cepat lewat satu database Firebase yang sama.',
      ),
      infoTitle: _readString(data?['infoTitle'], fallback: 'Info & Dukungan'),
      infoBody: _readString(
        data?['infoBody'],
        fallback:
            'Butuh onboarding owner, akses panel developer, atau pengaturan website? Hubungi tim SmartLaba untuk setup bisnis Anda.',
      ),
      supportEmail: _readString(
        data?['supportEmail'],
        fallback: 'support@smartlaba.id',
      ),
      primaryCtaLabel: _readString(data?['primaryCtaLabel'], fallback: 'Masuk'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heroTitle': heroTitle,
      'heroSubtitle': heroSubtitle,
      'aboutTitle': aboutTitle,
      'aboutBody': aboutBody,
      'infoTitle': infoTitle,
      'infoBody': infoBody,
      'supportEmail': supportEmail,
      'primaryCtaLabel': primaryCtaLabel,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class PlatformSettings {
  final String appNotice;
  final String latestVersion;
  final String minimumSupportedVersion;
  final String updateMessage;
  final bool maintenanceMode;
  final bool forceUpdate;
  final bool webEnabled;
  final String apkDownloadUrl;
  final String supportEmail;

  const PlatformSettings({
    required this.appNotice,
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.updateMessage,
    required this.maintenanceMode,
    required this.forceUpdate,
    required this.webEnabled,
    required this.apkDownloadUrl,
    required this.supportEmail,
  });

  factory PlatformSettings.fromMap(Map<String, dynamic>? data) {
    return PlatformSettings(
      appNotice: _readString(data?['appNotice']),
      latestVersion: _readString(data?['latestVersion'], fallback: '1.0.0'),
      minimumSupportedVersion: _readString(
        data?['minimumSupportedVersion'],
        fallback: '1.0.0',
      ),
      updateMessage: _readString(
        data?['updateMessage'],
        fallback:
            'Versi aplikasi Anda sudah terlalu lama. Silakan perbarui ke versi terbaru untuk melanjutkan.',
      ),
      maintenanceMode: data?['maintenanceMode'] == true,
      forceUpdate: data?['forceUpdate'] == true,
      webEnabled: data?['webEnabled'] != false,
      apkDownloadUrl: _readString(data?['apkDownloadUrl']),
      supportEmail: _readString(
        data?['supportEmail'],
        fallback: 'support@smartlaba.id',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appNotice': appNotice,
      'latestVersion': latestVersion,
      'minimumSupportedVersion': minimumSupportedVersion,
      'updateMessage': updateMessage,
      'maintenanceMode': maintenanceMode,
      'forceUpdate': forceUpdate,
      'webEnabled': webEnabled,
      'apkDownloadUrl': apkDownloadUrl,
      'supportEmail': supportEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class AppBroadcastMessage {
  final bool isActive;
  final String title;
  final String body;
  final String targetRole;
  final String ctaLabel;
  final String ctaUrl;
  final int updatedAtMillis;

  const AppBroadcastMessage({
    required this.isActive,
    required this.title,
    required this.body,
    required this.targetRole,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.updatedAtMillis,
  });

  factory AppBroadcastMessage.fromMap(Map<String, dynamic>? data) {
    return AppBroadcastMessage(
      isActive: data?['isActive'] == true,
      title: _readString(data?['title'], fallback: 'Pembaruan SmartLaba'),
      body: _readString(
        data?['body'],
        fallback:
            'Ada informasi terbaru dari developer panel. Cek pengumuman ini untuk update operasional aplikasi.',
      ),
      targetRole: _readString(data?['targetRole'], fallback: 'All'),
      ctaLabel: _readString(data?['ctaLabel'], fallback: 'Lihat Detail'),
      ctaUrl: _readString(data?['ctaUrl']),
      updatedAtMillis: _readTimestampMillis(data?['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'title': title,
      'body': body,
      'targetRole': targetRole,
      'ctaLabel': ctaLabel,
      'ctaUrl': ctaUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get signature =>
      '$updatedAtMillis|$title|$body|$targetRole|$ctaLabel|$ctaUrl|$isActive';

  bool matchesRole(String role) {
    final normalizedTarget = targetRole.trim().toLowerCase();
    final normalizedRole = role.trim().toLowerCase();
    return normalizedTarget.isEmpty ||
        normalizedTarget == 'all' ||
        normalizedTarget == normalizedRole;
  }
}

DocumentReference<Map<String, dynamic>> publicSiteContentRef(
  FirebaseFirestore firestore,
) {
  return firestore.collection('system_settings').doc('public_site');
}

DocumentReference<Map<String, dynamic>> platformSettingsRef(
  FirebaseFirestore firestore,
) {
  return firestore.collection('system_settings').doc('platform');
}

DocumentReference<Map<String, dynamic>> appBroadcastRef(
  FirebaseFirestore firestore,
) {
  return firestore.collection('system_settings').doc('app_broadcast');
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
  if (value is num) {
    return value.toString();
  }
  return fallback;
}

int _readTimestampMillis(dynamic value) {
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }
  if (value is DateTime) {
    return value.millisecondsSinceEpoch;
  }
  if (value is int) {
    return value;
  }
  return 0;
}
