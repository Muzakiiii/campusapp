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
              .where('role', isEqualTo: 'mahasiswa') // Hanya ambil mahasiswa
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

              // Parsing data sesuai struktur Firestore Anda
              final int totalSKKM = _safeParseToInt(data['totalSKKM']);
              final int completedEvents = _safeParseToInt(data['completedEvents']);
              final int registeredEvents = _safeParseToInt(data['registeredEvents']);
              final String name = data['name']?.toString() ?? 'Mahasiswa';
              final String fakultas = data['fakultas']?.toString() ?? '-';
              final String departemen = data['departemen']?.toString() ?? '-';
              final String nim = data['nim']?.toString() ?? '-';
              final int angkatan = _safeParseToInt(data['angkatan']);

              return LeaderboardEntry(
                userId: doc.id,
                rank: index + 1,
                userName: name,
                faculty: fakultas,
                departemen: departemen,
                nim: nim,
                angkatan: angkatan,
                totalSKKM: totalSKKM,
                completedEvents: completedEvents,
                registeredEvents: registeredEvents,
                email: data['email']?.toString() ?? '',
              );
            }).toList();

            // Cari data user saat ini berdasarkan email
            final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
            if (currentUserEmail != null && currentUserEmail.isNotEmpty) {
              final currentUserIndex = _leaderboard.indexWhere(
                (entry) => entry.email == currentUserEmail
              );
              
              if (currentUserIndex != -1) {
                _currentUserData = _leaderboard[currentUserIndex];
              }
            }

            // Jika tidak ditemukan berdasarkan email, cari berdasarkan userId
            if (_currentUserId != null && _currentUserData == null) {
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
                  
                  // Leaderboard List - tampilkan semua atau maksimal 10
                  _buildLeaderboardList(),
                  
                  const SizedBox(height: 20),
                  
                  // Tampilkan peringkat user jika tidak masuk top list
                  if (_currentUserData != null && _currentUserData!.rank > 4)
                    _buildCurrentUserRankCard(),
                  
                  const SizedBox(height: 80),
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
            onPressed: () {
              setState(() {});
            },
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
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
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
          const SizedBox(height: 12),
          
          // Badge Peringkat
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: _getRankGradient(userData.rank),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getRankColor(userData.rank).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#${userData.rank}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nama dan Info
          Text(
            userData.userName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                userData.faculty,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.confirmation_number, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'NIM: ${userData.nim}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getLevelColor(userData.totalSKKM),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Level: ${_getLevel(userData.totalSKKM)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistik Ringkas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat(
                icon: Icons.star,
                value: '${userData.totalSKKM}',
                label: 'SKKM',
                color: Colors.orange,
              ),
              _buildMiniStat(
                icon: Icons.event_available,
                value: '${userData.completedEvents}',
                label: 'Selesai',
                color: Colors.green,
              ),
              _buildMiniStat(
                icon: Icons.event,
                value: '${userData.registeredEvents}',
                label: 'Daftar',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
                    color: (stat['color'] as Color?)?.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: stat['color'] as Color? ?? Colors.blue,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    stat['icon'] as IconData? ?? Icons.info,
                    color: stat['color'] as Color? ?? Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String? ?? '0',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color? ?? Colors.black,
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
    // Ambil maksimal 4 teratas untuk ditampilkan di bagian Top Mahasiswa
    final topUsers = _leaderboard.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: topUsers.map((user) => _buildTopUserCard(user)).toList(),
      ),
    );
  }

  Widget _buildCurrentUserRankCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${_currentUserData!.rank}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUserData!.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _currentUserData!.faculty,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_currentUserData!.totalSKKM} SKKM',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                '${_currentUserData!.completedEvents} event',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: _getRankGradient(user.rank),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#${user.rank}',
              style: const TextStyle(
                fontSize: 16,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.faculty,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (user.nim.isNotEmpty && user.nim != '-')
              Text(
                'NIM: ${user.nim}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
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
              '${user.completedEvents} event selesai',
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.blue;
    }
  }

  Color _getLevelColor(int totalSKKM) {
    if (totalSKKM >= 100) return const Color(0xFF9C27B0); // Purple for Master
    if (totalSKKM >= 50) return const Color(0xFF2196F3); // Blue for Advanced
    if (totalSKKM >= 20) return const Color(0xFF4CAF50); // Green for Intermediate
    return const Color(0xFFFF9800); // Orange for Beginner
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
  final String departemen;
  final String nim;
  final int angkatan;
  final int totalSKKM;
  final int completedEvents;
  final int registeredEvents;
  final String email;

  LeaderboardEntry({
    required this.userId,
    required this.rank,
    required this.userName,
    required this.faculty,
    required this.departemen,
    required this.nim,
    required this.angkatan,
    required this.totalSKKM,
    required this.completedEvents,
    required this.registeredEvents,
    required this.email,
  });
}