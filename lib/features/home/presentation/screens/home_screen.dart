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
  String _selectedCategory = 'Semua'; // Default filter
  final ScrollController _scrollController = ScrollController();
  final EventRepository _eventRepository = EventRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // 1. UPDATE DAFTAR KATEGORI
  // ==========================================
  final List<Map<String, dynamic>> _categories = [
    {'label': 'Semua', 'icon': Icons.grid_view},
    {'label': 'Seminar', 'icon': Icons.co_present},     // Ikon Presentasi
    {'label': 'Workshop', 'icon': Icons.build},         // Ikon Tools/Praktek
    {'label': 'Webinar', 'icon': Icons.laptop_mac},     // Ikon Laptop/Online
    {'label': 'Pelatihan', 'icon': Icons.model_training}, // Ikon Training
    {'label': 'Lomba', 'icon': Icons.emoji_events},     // Ikon Piala
    {'label': 'Lainnya', 'icon': Icons.more_horiz},     // Ikon Lainnya
  ];

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
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;
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

                final allEventsRaw = snapshot.data ?? [];

                // Filter Logic
                final filteredEvents = _selectedCategory == 'Semua'
                    ? allEventsRaw
                    : allEventsRaw
                        .where((e) => e.kategori == _selectedCategory)
                        .toList();

                final upcomingEvents = filteredEvents
                    .where((e) => e.tanggal.isAfter(DateTime.now()))
                    .toList();

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: isSmallScreen ? 10 : 20,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildGreetingSection(greeting, userName),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildCategoryFilter(),
                      
                      const SizedBox(height: 20),

                      if (filteredEvents.isEmpty)
                        Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, 
                                  size: 50, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              Text(
                                "Tidak ada acara di kategori $_selectedCategory",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildRecommendedEventsSection(
                              isSmallScreen, filteredEvents),
                        ),
                        
                        const SizedBox(height: 25),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildUpcomingEventsSection(
                              isSmallScreen, upcomingEvents),
                        ),
                      ],
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

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['label'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category['label'];
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      category['icon'],
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedEventsSection(
    bool isSmallScreen,
    List<EventModel> events,
  ) {
    final recommendedEvents = (_selectedCategory != 'Semua' || _showAllEvents) 
        ? events 
        : events.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory == 'Semua' 
                  ? 'Rekomendasi untuk Anda' 
                  : 'Kategori: $_selectedCategory',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (_selectedCategory == 'Semua')
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
          height: 280,
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
    final visibleEvents = (_selectedCategory != 'Semua' || _showAllEvents) 
        ? upcomingEvents 
        : upcomingEvents.take(3).toList();

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
        // Tambahkan clipBehavior agar efek riak air (ripple) tidak keluar dari radius card
        clipBehavior: Clip.antiAlias, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
        // Bungkus Column dengan InkWell untuk mendeteksi klik pada seluruh kartu
        child: InkWell(
          onTap: () {
            // Aksi navigasi ke halaman pendaftaran saat kartu diklik
            _navigateToEventRegistration(context, event);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                // Hapus top radius di sini karena clipBehavior card sudah menangani semuanya,
                // tapi dibiarkan juga tidak masalah.
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: _getCategoryColor(event.kategori).withOpacity(0.8),
                  child: Stack(
                    children: [
                      if (event.posterUrl.isNotEmpty)
                        Image.network(
                          event.posterUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultEventIcon(event),
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
                              // Tombol bookmark tetap berfungsi terpisah
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(event.kategori)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.kategori,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getCategoryColor(event.kategori),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.isGratis ? 'Gratis' : 'Berbayar',
                          style: TextStyle(
                            fontSize: 10,
                            color: event.isGratis ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12, color: Colors.grey.shade600),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEventIcon(EventModel event) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _getCategoryColor(event.kategori).withOpacity(0.8),
      child: Center(
        child: Icon(
          _getCategoryIcon(event.kategori),
          size: 40,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildUpcomingTile(EventModel event) {
    Color categoryColor = _getCategoryColor(event.kategori);
    IconData categoryIcon = _getCategoryIcon(event.kategori);

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
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.lokasi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(categoryIcon, size: 12, color: categoryColor),
                      const SizedBox(width: 4),
                      Text(
                        event.kategori,
                        style: TextStyle(
                          fontSize: 12,
                          color: categoryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToEventRegistration(context, event);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  foregroundColor: Colors.white,
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

  void _navigateToEventRegistration(BuildContext context, EventModel event) {
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
      // ==========================================
      // MODIFIKASI: MENGHILANGKAN SAPAAN DI APPBAR
      // ==========================================
      // Kita mengganti StreamBuilder yang memuat sapaan dengan Text statis.
      // Sapaan personal (Good morning, User) tetap ada di bagian body.
      title: const Text(
        'CampusGo', // Ganti dengan nama aplikasimu atau 'Beranda'
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      // ==========================================
      
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
  
  // ==========================================
  // 2. UPDATE HELPER WARNA
  // ==========================================
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Seminar': return Colors.blue;
      case 'Workshop': return Colors.orange;
      case 'Webinar': return Colors.teal;
      case 'Pelatihan': return Colors.green;
      case 'Lomba': return Colors.amber;
      case 'Lainnya': return Colors.purple;
      default: return AppColors.primary;
    }
  }

  // ==========================================
  // 3. UPDATE HELPER ICON
  // ==========================================
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Seminar': return Icons.co_present;
      case 'Workshop': return Icons.build;
      case 'Webinar': return Icons.laptop_mac;
      case 'Pelatihan': return Icons.model_training;
      case 'Lomba': return Icons.emoji_events;
      case 'Lainnya': return Icons.more_horiz;
      default: return Icons.event;
    }
  }
}