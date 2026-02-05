import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/notifications/data/repositories/notification_repository.dart';
import 'package:campusapp/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:campusapp/features/notifications/domain/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId; // WAJIB untuk Firestore

  const NotificationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  // =============================
  // TANDAI 1 NOTIFIKASI
  // =============================
  Future<void> _markAsRead(String id) async {
    await _notificationRepository.tandaiSudahDibaca(id);
  }

  // =============================
  // HAPUS NOTIFIKASI
  // =============================
  void _deleteNotification(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content:
            const Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await _notificationRepository.hapusNotifikasi(id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // TANDAI SEMUA
  // =============================
  Future<void> _markAllAsRead() async {
    await _notificationRepository
        .tandaiSemuaSudahDibaca(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          // Stream jumlah unread
          StreamBuilder<int>(
            stream: _notificationRepository
                .getJumlahBelumDibacaStream(widget.userId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              if (unreadCount == 0) return const SizedBox();

              return TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  'Tandai Semua',
                  style: TextStyle(color: AppColors.primary),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationRepository
            .getNotifikasiStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data ?? [];
          final unreadCount =
              notifications.where((n) => !n.isRead).length;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 60,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semua notifikasi akan muncul di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Stream otomatis update, tidak perlu reload manual
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Banner unread
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Anda memiliki $unreadCount notifikasi belum dibaca',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // List notifikasi
                ...notifications.map((notification) {
                  return NotificationTile(
                    notification: notification,
                    onTap: () => _markAsRead(notification.id),
                    onDelete: () =>
                        _deleteNotification(notification.id),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
