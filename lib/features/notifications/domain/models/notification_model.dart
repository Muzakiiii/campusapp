import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  event,
  announcement,
  reminder,
  system,
  warning,
}

class NotificationModel {
  final String id;
  final String userId;
  final String judul;
  final String deskripsi;
  final bool isRead;
  final DateTime createdAt;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.judul,
    required this.deskripsi,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.system,
  });

  // =========================
  // FROM FIRESTORE
  // =========================
  factory NotificationModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    final Timestamp? ts = map['createdAt'];

    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? '',
      judul: map['judul'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: ts != null ? ts.toDate() : DateTime.now(),
      type: _parseType(map['type']),
    );
  }

  // =========================
  // TO FIRESTORE
  // =========================
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'judul': judul,
      'deskripsi': deskripsi,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': _typeToString(type),
    };
  }

  // =========================
  // PARSE TYPE
  // =========================
  static NotificationType _parseType(String? value) {
    switch (value) {
      case 'event':
        return NotificationType.event;
      case 'announcement':
        return NotificationType.announcement;
      case 'reminder':
        return NotificationType.reminder;
      case 'warning':
        return NotificationType.warning;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.event:
        return 'event';
      case NotificationType.announcement:
        return 'announcement';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.system:
      default:
        return 'system';
    }
  }

  // =========================
  // COPY WITH
  // =========================
  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      judul: judul,
      deskripsi: deskripsi,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }

  // =========================
  // UI HELPER
  // =========================
  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
