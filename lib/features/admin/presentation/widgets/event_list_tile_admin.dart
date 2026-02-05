import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final isGratis = event.isGratis;
    final kuotaText = '${event.kuota} peserta';
    final skkmText = '${event.skkm} SKKM';
    
    // Format waktu sesuai dengan AdminEditEventScreen
    final jamMulai = event.jamMulai;
    final jamSelesai = event.jamSelesai;
    final formattedTime = jamMulai.isNotEmpty && jamSelesai.isNotEmpty 
        ? '$jamMulai - $jamSelesai' 
        : 'Waktu belum ditentukan';
    
    // Format tanggal
    final dateFormat = event.tanggal != null 
        ? _formatDate(event.tanggal!) 
        : 'Tanggal belum ditentukan';
    
    // Format batas daftar
    final batasDaftarText = event.batasDaftar != null 
        ? 'Batas: ${_formatDate(event.batasDaftar!)}' 
        : 'Batas daftar: -';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
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
                  // Category Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.kategori).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getCategoryColor(event.kategori).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getCategoryIcon(event.kategori),
                      color: _getCategoryColor(event.kategori),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Event Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul dan Status Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                event.judul,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge kecil
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(event.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getStatusColor(event.status),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _capitalizeFirst(event.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(event.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Kategori tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(event.kategori).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.kategori,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(event.kategori),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Deskripsi singkat
                        Text(
                          event.deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Info tanggal dan batas daftar
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateFormat,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              batasDaftarText,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Jam dan Lokasi Row
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.lokasi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Link Online jika ada
                        if (event.linkOnline.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Online: ${event.linkOnline}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),

            // ================= FOOTER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Info kuota, SKKM, dan harga
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Badge Kuota
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            kuotaText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        
                        // Badge SKKM
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.orange.shade100,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            skkmText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                        
                        // Badge Harga Online
                        if (event.hargaOnline > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.purple.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.computer,
                                  size: 10,
                                  color: Colors.purple.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Rp ${event.hargaOnline}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Badge Harga Offline
                        if (event.hargaOffline > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.teal.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 10,
                                  color: Colors.teal.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Rp ${event.hargaOffline}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Badge Gratis
                        if (isGratis)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.celebration,
                                  size: 10,
                                  color: Colors.green.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Gratis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  if (showActions)
                    Row(
                      children: [
                        // Edit Button
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Edit Event',
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Delete Button
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.shade100,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Hapus Event',
                          ),
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

  // Helper untuk format tanggal
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper untuk kapitalisasi status
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Helper untuk warna kategori sesuai AdminEditEventScreen
  Color _getCategoryColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'seminar':
        return Colors.blue;
      case 'workshop':
        return Colors.orange;
      case 'pelatihan':
        return Colors.green;
      case 'lomba':
        return Colors.purple;
      case 'webinar':
        return Colors.teal;
      case 'lainnya':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Helper untuk ikon kategori
  IconData _getCategoryIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'seminar':
        return Icons.school;
      case 'workshop':
        return Icons.build;
      case 'pelatihan':
        return Icons.train;
      case 'lomba':
        return Icons.emoji_events;
      case 'webinar':
        return Icons.videocam;
      case 'lainnya':
        return Icons.event;
      default:
        return Icons.event;
    }
  }

  // Helper untuk warna status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}