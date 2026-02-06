import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    final greeting = _getGreeting();
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHeader(context, greeting, currentUser),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot>(
          stream: currentUser != null
              ? _firestore.collection('users').doc(currentUser.uid).snapshots()
              : null,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            String userName = 'User';
            if (userSnapshot.hasData &&
                userSnapshot.data != null &&
                userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              if (userData != null && userData.containsKey('name')) {
                userName = userData['name'] ?? 'User';
              }
            }

            return StreamBuilder<List<EventModel>>(
              stream: _eventRepository.getAllEventsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEvents = snapshot.data ?? [];
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
                      _buildGreetingSection(greeting, userName),
                      const SizedBox(height: 25),
                      _buildRecommendedEventsSection(isSmallScreen, allEvents),
                      const SizedBox(height: 25),
                      _buildUpcomingEventsSection(isSmallScreen, upcomingEvents),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecommendedEventsSection(
    bool isSmallScreen,
    List<EventModel> allEvents,
  ) {
    final recommendedEvents =
        _showAllEvents ? allEvents : allEvents.take(4).toList();

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
        const SizedBox(height: 12),
        SizedBox(
          height: 280, // DIPERBESAR LAGI dari 260 ke 280
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedEvents.length,
            itemBuilder: (context, index) {
              final event = recommendedEvents[index];
              return Container(
                width: 180,
                margin: EdgeInsets.only(
                  right: index < recommendedEvents.length - 1 ? 12 : 0,
                ),
                child: _buildEventCard(event),
              );
            },
          ),
        ),
      ],
    );
  }

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
        const SizedBox(height: 12),
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

  Widget _buildEventCard(EventModel event) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bagian gambar dengan fixed height
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 140, // DIPERBESAR dari 130 ke 140
                width: double.infinity,
                color: event.categoryColor.withOpacity(0.8),
                child: Stack(
                  children: [
                    if (event.posterUrl.isNotEmpty)
                      Image.network(
                        event.posterUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultEventIcon(event);
                        },
                      )
                    else
                      _buildDefaultEventIcon(event),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            event.isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () async {
                            await _eventRepository.toggleBookmark(
                              event.id,
                              event.isBookmarked,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bagian konten - DIKURANGI KONTENNYA
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Judul saja, tanpa batasan maxLines yang ketat
                  Text(
                    event.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.2, // DIKECILKAN dari 1.3
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Hanya Kategori dan Lokasi
                  Row(
                    children: [
                      // Kategori
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.kategori,
                          style: TextStyle(
                            fontSize: 10, // DIKECILKAN
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Status Harga
                      Text(
                        event.isGratis ? 'Gratis' : 'Berbayar',
                        style: TextStyle(
                          fontSize: 10, // DIKECILKAN
                          color: event.isGratis ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Lokasi saja
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
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
                  
                  // HAPUS WAKTU untuk menghemat ruang
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEventIcon(EventModel event) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: event.categoryColor.withOpacity(0.8),
      child: Center(
        child: Icon(
          event.categoryIcon,
          size: 40,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildUpcomingTile(EventModel event) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            Text(
              event.judul,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Info dasar: Tanggal & Lokasi saja
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.lokasi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            
            // Kategori dan Status - dalam satu baris
            const SizedBox(height: 12),
            Row(
              children: [
                // Kategori
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.kategori,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Status Harga
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: event.isGratis 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.isGratis ? 'Gratis' : 'Berbayar',
                    style: TextStyle(
                      fontSize: 12,
                      color: event.isGratis ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            // Button Daftar
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToEventRegistration(context, event);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Daftar Sekarang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEventRegistration(
    BuildContext context,
    EventModel event,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventRegistrationScreen(
          event: event,
          userId: _auth.currentUser?.uid ?? 'GUEST',
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

  PreferredSizeWidget _buildHeader(
      BuildContext context, String greeting, User? currentUser) {
    return AppBar(
      title: StreamBuilder<DocumentSnapshot>(
        stream: currentUser != null
            ? _firestore.collection('users').doc(currentUser.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          String userName = 'User';

          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData != null && userData.containsKey('name')) {
              userName = userData['name'] ?? 'User';
            }
          }

          return Text('$greeting, $userName');
        },
      ),
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
            if (currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    userId: currentUser.uid,
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildGreetingSection(String greeting, String userName) {
    return Text(
      '$greeting, $userName',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }
}