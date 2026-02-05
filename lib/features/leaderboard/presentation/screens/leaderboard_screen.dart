import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? _currentUserId;
  LeaderboardEntry? _currentUserData;
  List<LeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  // Fungsi untuk parsing data dengan aman
  int _safeParseToInt(dynamic value) {
    if (value == null) return 0;
    
    if (value is num) {
      return value.toInt();
    }
    
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    
    try {
      final strValue = value.toString();
      return int.tryParse(strValue) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String _getLevel(int totalSKKM) {
    if (totalSKKM >= 100) return 'Master';
    if (totalSKKM >= 50) return 'Advanced';
    if (totalSKKM >= 20) return 'Intermediate';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('totalSKKM', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorScreen('Gagal memuat leaderboard');
            }

            if (!snapshot.hasData) {
              return _buildLoadingScreen();
            }

            final docs = snapshot.data!.docs;

            // Proses data leaderboard
            _leaderboard = docs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;

              final int totalSKKM = _safeParseToInt(data['totalSKKM']);
              final int completedEvents = _safeParseToInt(data['completedEvents']);
              final int registeredEvents = _safeParseToInt(data['registeredEvents']);

              return LeaderboardEntry(
                userId: doc.id,
                rank: index + 1,
                userName: data['name']?.toString() ?? 'User',
                faculty: data['fakultas']?.toString() ?? 
                         data['departemen']?.toString() ?? 
                         'Fakultas',
                totalSKKM: totalSKKM,
                completedEvents: completedEvents,
                registeredEvents: registeredEvents,
              );
            }).toList();

            // Cari data user saat ini
            if (_currentUserId != null) {
              final currentUserIndex = _leaderboard.indexWhere(
                (entry) => entry.userId == _currentUserId
              );
              
              if (currentUserIndex != -1) {
                _currentUserData = _leaderboard[currentUserIndex];
              }
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Current User Stats
                  if (_currentUserData != null) _buildCurrentUserStats(_currentUserData!),
                  
                  // Stats Grid
                  _buildStatsGrid(_currentUserData),
                  
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                  ),
                  
                  // Top Mahasiswa Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Top Mahasiswa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            'Total: ${_leaderboard.length} mahasiswa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Leaderboard List
                  _buildLeaderboardList(),
                  
                  const SizedBox(height: 80), // Space untuk bottom navigation
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            'Leaderboard SKKM',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue.shade700),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserStats(LeaderboardEntry userData) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Peringkat Anda',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${userData.rank}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level: ${_getLevel(userData.totalSKKM)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Text(
                      '${userData.totalSKKM} poin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                '${userData.completedEvents} event selesai',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(LeaderboardEntry? userData) {
    final stats = [
      {
        'title': 'Daftar',
        'value': userData?.registeredEvents.toString() ?? '0',
        'icon': Icons.list_alt,
        'color': Colors.blue,
      },
      {
        'title': 'Selesai',
        'value': userData?.completedEvents.toString() ?? '0',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'title': 'SKKM',
        'value': userData?.totalSKKM.toString() ?? '0',
        'icon': Icons.star,
        'color': Colors.orange,
      },
      {
        'title': 'Peringkat',
        'value': userData != null ? '#${userData.rank}' : '#0',
        'icon': Icons.leaderboard,
        'color': Colors.purple,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stat['color'] as Color? ?? Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stat['icon'] as IconData? ?? Icons.info,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String? ?? '0',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardList() {
    // Ambil 4 teratas untuk ditampilkan
    final topUsers = _leaderboard.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: topUsers.map((user) => _buildTopUserCard(user)).toList(),
      ),
    );
  }

  Widget _buildTopUserCard(LeaderboardEntry user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: _getRankGradient(user.rank),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#${user.rank}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          user.userName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          user.faculty,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${user.totalSKKM} SKKM',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${user.completedEvents} event',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFC400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFFA0A0A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFB87333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat leaderboard...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final int rank;
  final String userName;
  final String faculty;
  final int totalSKKM;
  final int completedEvents;
  final int registeredEvents;

  LeaderboardEntry({
    required this.userId,
    required this.rank,
    required this.userName,
    required this.faculty,
    required this.totalSKKM,
    required this.completedEvents,
    required this.registeredEvents,
  });
}