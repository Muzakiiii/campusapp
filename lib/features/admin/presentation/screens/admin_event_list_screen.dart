import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/app/routes.dart';
import 'package:campusapp/features/admin/data/repositories/admin_event_repository.dart';
import 'package:campusapp/features/admin/presentation/widgets/event_list_tile_admin.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/admin/presentation/screens/admin_edit_event_screen.dart';

class AdminEventListScreen extends StatefulWidget {
  const AdminEventListScreen({super.key});

  @override
  State<AdminEventListScreen> createState() =>
      _AdminEventListScreenState();
}

class _AdminEventListScreenState extends State<AdminEventListScreen> {
  final AdminEventRepository _eventRepository =
      AdminEventRepository();
  final TextEditingController _searchController =
      TextEditingController();

  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =======================
  // LOAD EVENTS
  // =======================
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final events = await _eventRepository.getAllEvents();
      setState(() {
        _events = events;
        _filteredEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal memuat data event');
    }
  }

  // =======================
  // SEARCH
  // =======================
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEvents = _events;
      } else {
        _filteredEvents = _events.where((event) {
          return event.judul.toLowerCase().contains(query) ||
              event.kategori.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // =======================
  // DELETE
  // =======================
  void _showDeleteConfirmation(int index) {
    final event = _filteredEvents[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event'),
        content: Text(
          'Apakah Anda yakin ingin menghapus event "${event.judul}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event.id, index);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(String eventId, int index) async {
    try {
      await _eventRepository.deleteEvent(eventId);

      setState(() {
        _events.removeWhere((e) => e.id == eventId);
        _filteredEvents.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      _showError('Gagal menghapus event');
    }
  }

  // =======================
  // NAVIGATION
  // =======================
  void _navigateToCreateEvent() {
    Navigator.pushNamed(context, Routes.adminCreateEvent)
        .then((_) => _loadEvents());
  }

  void _navigateToEditEvent(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditEventScreen(eventId: eventId),
      ),
    ).then((_) => _loadEvents());
  }

  // =======================
  // DETAIL
  // =======================
  void _viewEventDetails(int index) {
    final event = _filteredEvents[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.judul),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.deskripsi),
              const SizedBox(height: 16),
              _buildDetailRow('Kategori', event.kategori),
              _buildDetailRow(
                'Tanggal',
                '${event.tanggal.day}/${event.tanggal.month}/${event.tanggal.year} • ${event.jamMulai}',
              ),
              _buildDetailRow('Lokasi', event.lokasi),
              _buildDetailRow(
                'Peserta',
                '${event.jumlahPendaftar} orang',
              ),
              _buildDetailRow(
                'Harga Online',
                event.hargaOnline == 0
                    ? 'Gratis'
                    : 'Rp ${event.hargaOnline.toStringAsFixed(0)}',
              ),
              _buildDetailRow('SKKM', '${event.skkm} poin'),
              _buildDetailRow('Kuota', '${event.kuota} orang'),
              _buildDetailRow('Status', event.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Event')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari event...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Event: ${_filteredEvents.length}',
                ),
                CustomButton(
                  onPressed: _navigateToCreateEvent,
                  text: 'Event Baru',
                  height: 36,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: _filteredEvents.isEmpty
                        ? const Center(child: Text('Belum ada event'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];

                              return InkWell(
                                onTap: () => _viewEventDetails(index),
                                child: EventListTileAdmin(
                                  event: event,
                                  onEdit: () =>
                                      _navigateToEditEvent(event.id),
                                  onDelete: () =>
                                      _showDeleteConfirmation(index),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
