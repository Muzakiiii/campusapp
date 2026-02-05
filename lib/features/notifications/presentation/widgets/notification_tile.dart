import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/notifications/domain/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container (berdasarkan tipe)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(notification.type),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      _getTypeIcon(notification.type),
                      color: _getTypeColor(notification.type),
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.judul,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: notification.isRead
                                    ? Colors.grey.shade800
                                    : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeAgo(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        notification.deskripsi,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification.type)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getTypeText(notification.type),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getTypeColor(notification.type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Spacer(),

                          if (onDelete != null)
                            GestureDetector(
                              onTap: onDelete,
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (!notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // HELPER: TIME AGO
  // =========================
  String _formatTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // =========================
  // TYPE UI HELPERS
  // =========================
  Color _getBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.event:
        return AppColors.primary.withOpacity(0.1);
      case NotificationType.system:
        return Colors.blue.withOpacity(0.1);
      case NotificationType.reminder:
        return Colors.orange.withOpacity(0.1);
      case NotificationType.announcement:
        return Colors.green.withOpacity(0.1);
      case NotificationType.warning:
        return Colors.red.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.event:
        return AppColors.primary;
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.announcement:
        return Colors.green;
      case NotificationType.warning:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.event:
        return Icons.event;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.warning:
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeText(NotificationType type) {
    switch (type) {
      case NotificationType.event:
        return 'EVENT';
      case NotificationType.system:
        return 'SISTEM';
      case NotificationType.reminder:
        return 'PENGINGAT';
      case NotificationType.announcement:
        return 'PENGUMUMAN';
      case NotificationType.warning:
        return 'PERINGATAN';
      default:
        return 'LAINNYA';
    }
  }
}
