import 'package:flutter/foundation.dart';

enum AnnouncementType {
  info,
  warning,
  success,
  urgent;

  static AnnouncementType fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'INFO':
        return AnnouncementType.info;
      case 'WARNING':
        return AnnouncementType.warning;
      case 'SUCCESS':
        return AnnouncementType.success;
      case 'URGENT':
        return AnnouncementType.urgent;
      default:
        return AnnouncementType.info;
    }
  }

  String get apiValue => name.toUpperCase();
}

enum AnnouncementAudience {
  all,
  creator,
  advertiser;

  static AnnouncementAudience fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'ALL':
        return AnnouncementAudience.all;
      case 'CREATOR':
        return AnnouncementAudience.creator;
      case 'ADVERTISER':
        return AnnouncementAudience.advertiser;
      default:
        return AnnouncementAudience.all;
    }
  }

  String get apiValue => name.toUpperCase();

  String get displayName {
    switch (this) {
      case AnnouncementAudience.all:
        return 'All Users';
      case AnnouncementAudience.creator:
        return 'Creators';
      case AnnouncementAudience.advertiser:
        return 'Advertisers';
    }
  }
}

@immutable
class Announcement {
  const Announcement({
    required this.id,
    required this.message,
    required this.type,
    required this.targetAudience,
    required this.active,
    required this.order,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String message;
  final AnnouncementType type;
  final AnnouncementAudience targetAudience;
  final bool active;
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: AnnouncementType.fromString(json['type']?.toString()),
      targetAudience: AnnouncementAudience.fromString(
        json['targetAudience']?.toString(),
      ),
      active: json['active'] == true,
      order: _parseInt(json['order']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? _parseDateTime(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'message': message,
      'type': type.apiValue,
      'targetAudience': targetAudience.apiValue,
      'active': active,
      'order': order,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'message': message,
      'type': type.apiValue,
      'targetAudience': targetAudience.apiValue,
      'active': active,
      'order': order,
    };
  }

  Announcement copyWith({
    String? id,
    String? message,
    AnnouncementType? type,
    AnnouncementAudience? targetAudience,
    bool? active,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      targetAudience: targetAudience ?? this.targetAudience,
      active: active ?? this.active,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _parseInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static DateTime _parseDateTime(Object? v) {
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
