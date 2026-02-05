import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';

class EventListTileAdmin extends StatelessWidget {
  final EventModel event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool showActions;

  const EventListTileAdmin({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.showActions = true,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Teknologi':
        return Colors.blue;
      case 'Kesehatan':
        return Colors.green;
      case 'Kepemimpinan':
        return Colors.orange;
      case 'Seni & Budaya':
        return Colors.purple;
      case 'Olahraga':
        return Colors.red;
      case 'Bisnis':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Teknologi':
        return Icons.computer;
      case 'Kesehatan':
        return Icons.health_and_safety;
      case 'Kepemimpinan':
        return Icons.leaderboard;
      case 'Seni & Budaya':
        return Icons.palette;
      case 'Olahraga':
        return Icons.sports_soccer;
      case 'Bisnis':
        return Icons.business_center;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(event.kategori);
    final categoryIcon = _getCategoryIcon(event.kategori);

    final tanggalText =
        '${event.tanggal.day}/${event.tanggal.month}/${event.tanggal.year}';

    final isGratis = event.hargaOnline == 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.judul,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$tanggalText • ${event.jamMulai}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ================= FOOTER =================
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isGratis
                        ? 'Gratis'
                        : 'Rp ${event.hargaOnline.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isGratis ? Colors.blue : Colors.green,
                    ),
                  ),

                  if (showActions)
                    Row(
                      children: [
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                          color: AppColors.primary,
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete),
                          color: AppColors.error,
                          tooltip: 'Hapus',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
