import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/events/data/repositories/event_repository.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Past, 2: Saved
  final EventRepository _eventRepository = EventRepository();

  List<EventModel> _upcomingEvents = [];
  List<EventModel> _pastEvents = [];
  List<EventModel> _savedEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // =============================
  // LOAD EVENTS FROM FIRESTORE
  // =============================
  Future<void> _loadEvents() async {
    try {
      // Ambil SEMUA event (sekali fetch manual)
      final snapshot = await _eventRepository
          .getAllEventsStream()
          .first;

      final savedSnapshot = await _eventRepository
          .getBookmarkedEventsStream()
          .first;

      final now = DateTime.now();

      setState(() {
        _upcomingEvents =
            snapshot.where((e) => e.tanggal.isAfter(now)).toList();

        _pastEvents =
            snapshot.where((e) => e.tanggal.isBefore(now)).toList();

        _savedEvents = savedSnapshot;

        _upcomingEvents
            .sort((a, b) => a.tanggal.compareTo(b.tanggal));
        _pastEvents
            .sort((a, b) => b.tanggal.compareTo(a.tanggal));
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
  }

  void _refreshEvents() {
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final List<EventModel> currentEvents = _selectedTab == 0
        ? _upcomingEvents
        : _selectedTab == 1
            ? _pastEvents
            : _savedEvents;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabItem('Upcoming', 0),
                _buildTabItem('Past', 1),
                _buildTabItem('Saved', 2),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${_upcomingEvents.length + _pastEvents.length + _savedEvents.length}',
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Upcoming',
                    '${_upcomingEvents.length}',
                    Icons.upcoming,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Saved',
                    '${_savedEvents.length}',
                    Icons.bookmark,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: currentEvents.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async => _refreshEvents(),
                      child: ListView.builder(
                        itemCount: currentEvents.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(currentEvents[index]);
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // =============================
  // EVENT CARD (SESUAI MODEL KAMU)
  // =============================
  Widget _buildEventCard(EventModel event) {
    final isSavedTab = _selectedTab == 2;
    final eventStatus = _getEventStatus(event);

    final hargaText = event.isGratis
        ? 'Gratis'
        : 'Rp ${event.hargaOnline.toInt()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + Participants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(eventStatus),
                  _buildParticipantsChip(event.jumlahPendaftar),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.judul,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSavedTab)
                    IconButton(
                      icon: const Icon(Icons.bookmark,
                          color: AppColors.primary),
                      onPressed: () => _removeFromSaved(event),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Category + Date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.kategori,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: event.categoryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    event.dateText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  _buildDetailItem(
                      Icons.access_time,
                      '${event.jamMulai} - ${event.jamSelesai}'),
                  const SizedBox(width: 16),
                  _buildDetailItem(Icons.location_on, event.lokasi),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildPriceChip(hargaText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================
  // STATUS LOGIC (REAL)
  // =============================
  EventStatusType _getEventStatus(EventModel event) {
    final now = DateTime.now();
    if (event.tanggal.isAfter(now)) {
      return EventStatusType.registered;
    } else {
      return EventStatusType.completed;
    }
  }

  Widget _buildStatusChip(EventStatusType status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildParticipantsChip(int participants) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            '$participants',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        price,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _selectedTab == 0
            ? 'No Upcoming Events'
            : _selectedTab == 1
                ? 'No Past Events'
                : 'No Saved Events',
      ),
    );
  }

  Color _getStatusColor(EventStatusType status) {
    switch (status) {
      case EventStatusType.registered:
        return Colors.green;
      case EventStatusType.completed:
        return Colors.blue;
      case EventStatusType.saved:
        return Colors.purple;
    }
  }

  String _getStatusText(EventStatusType status) {
    switch (status) {
      case EventStatusType.registered:
        return 'Registered';
      case EventStatusType.completed:
        return 'Completed';
      case EventStatusType.saved:
        return 'Saved';
    }
  }

  // =============================
  // ACTIONS
  // =============================
  void _showEventDetails(EventModel event) {
    // TODO: Navigate to detail
  }

  Future<void> _removeFromSaved(EventModel event) async {
    await _eventRepository.toggleBookmark(
      event.id,
      event.isBookmarked,
    );
    _loadEvents();
  }
}

// =============================
// ENUM
// =============================
enum EventStatusType { registered, completed, saved }
