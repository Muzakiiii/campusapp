import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/events/data/repositories/event_repository.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/notifications/presentation/screens/notification_screen.dart';
import 'package:campusapp/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:campusapp/features/events/presentation/screens/event_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? userType;

  const HomeScreen({super.key, this.userId, this.userType});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllEvents = false;
  final ScrollController _scrollController = ScrollController();
  final EventRepository _eventRepository = EventRepository();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // =========================
  // MAIN BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    final greeting = _getGreeting();
    final displayUserId = widget.userId ?? 'GUEST';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHeader(context, displayUserId, greeting),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<EventModel>>(
          stream: _eventRepository.getAllEventsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allEvents = snapshot.data ?? [];

            // 🔥 UPCOMING pakai event.tanggal
            final upcomingEvents = allEvents
                .where((e) => e.tanggal.isAfter(DateTime.now()))
                .toList();

            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: isSmallScreen ? 10 : 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingSection(greeting, displayUserId),
                  const SizedBox(height: 25),

                  _buildRecommendedEventsSection(
                    isSmallScreen,
                    allEvents,
                  ),

                  const SizedBox(height: 25),

                  _buildUpcomingEventsSection(
                    isSmallScreen,
                    upcomingEvents,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // RECOMMENDED
  // =========================
  Widget _buildRecommendedEventsSection(
    bool isSmallScreen,
    List<EventModel> allEvents,
  ) {
    final recommendedEvents = _showAllEvents
        ? allEvents
        : allEvents.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rekomendasi untuk Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            InkWell(
              onTap: () {
                setState(() => _showAllEvents = !_showAllEvents);
              },
              child: Text(
                _showAllEvents ? 'Sembunyikan' : 'Lihat Semua',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: isSmallScreen ? 210 : 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedEvents.length,
            itemBuilder: (context, index) {
              final event = recommendedEvents[index];

              return Container(
                width: isSmallScreen ? 180 : 200,
                margin: EdgeInsets.only(
                  right: index < recommendedEvents.length - 1 ? 15 : 0,
                ),
                child: _buildEventCard(event),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================
  // UPCOMING
  // =========================
  Widget _buildUpcomingEventsSection(
    bool isSmallScreen,
    List<EventModel> upcomingEvents,
  ) {
    final visibleEvents =
        _showAllEvents ? upcomingEvents : upcomingEvents.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Acara Mendatang',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '${visibleEvents.length} acara',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: visibleEvents.length,
          itemBuilder: (context, index) {
            final event = visibleEvents[index];
            return _buildUpcomingTile(event);
          },
        ),
      ],
    );
  }

  // =========================
  // EVENT CARD
  // =========================
  Widget _buildEventCard(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: event.categoryColor.withOpacity(0.8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    event.categoryIcon,
                    size: 50,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      event.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      await _eventRepository.toggleBookmark(
                        event.id,
                        event.isBookmarked,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          event.judul, // ✅ FIX
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          event.lokasi, // ✅ FIX
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // =========================
  // UPCOMING TILE
  // =========================
  Widget _buildUpcomingTile(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.judul, // ✅ FIX
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('${event.dateText} • ${event.jamMulai}'), // ✅ FIX
          const SizedBox(height: 6),
          Text(event.lokasi), // ✅ FIX
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _navigateToEventRegistration(context, event);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Daftar Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // NAV + HELPERS
  // =========================
  void _navigateToEventRegistration(
    BuildContext context,
    EventModel event,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventRegistrationScreen(
          event: event,
          userId: widget.userId ?? 'GUEST',
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // =========================
  // HEADER
  // =========================
  PreferredSizeWidget _buildHeader(
    BuildContext context,
    String userId,
    String greeting,
  ) {
    return AppBar(
      title: Text('$greeting, $userId'),
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LeaderboardScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(
                 userId: FirebaseAuth.instance.currentUser!.uid,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGreetingSection(String greeting, String userId) {
    return Text(
      '$greeting, $userId',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}
