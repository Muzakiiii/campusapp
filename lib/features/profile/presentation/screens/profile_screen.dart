import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;

  // USER DATA
  String name = '-';
  String studentId = '-';
  String faculty = '-';
  String department = '-';
  String batch = '-';

  // STATS
  int skkmPoints = 0;
  int eventsAttended = 0;
  int rank = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // 1. AMBIL DATA USER
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        // Parsing data sementara ke variabel lokal
        String tempName = data['name']?.toString() ?? '-';
        String tempNim = data['nim']?.toString() ?? '-';
        String tempFaculty = data['fakultas']?.toString() ?? '-';
        String tempDept = data['departemen']?.toString() ?? '-';
        String tempBatch = data['angkatan']?.toString() ?? '-';

        // Parsing SKKM (Pastikan jadi Integer untuk perhitungan Rank)
        int tempSkkm = 0;
        var skkmRaw = data['totalSKKM'];
        if (skkmRaw is int) {
          tempSkkm = skkmRaw;
        } else if (skkmRaw is String) {
          tempSkkm = int.tryParse(skkmRaw) ?? 0;
        }

        // Parsing Events
        int tempEvents = 0;
        var eventsRaw = data['completedEvents'];
        if (eventsRaw is int) {
          tempEvents = eventsRaw;
        } else if (eventsRaw is String) {
          tempEvents = int.tryParse(eventsRaw) ?? 0;
        }

        // 2. HITUNG RANKING SEBENARNYA (Sesuai Leaderboard)
        // Logika: Hitung jumlah user yang punya totalSKKM > skkm saya.
        // Jika ada 3 orang yang poinnya lebih tinggi, berarti saya ranking 4.

        final rankQuery = await _firestore
            .collection('users')
            .where('totalSKKM', isGreaterThan: tempSkkm)
            .count()
            .get();

        // Jika count null, anggap 0 lalu tambah 1
        int realRank = (rankQuery.count ?? 0) + 1;

        // 3. UPDATE UI SEKALIGUS
        if (mounted) {
          setState(() {
            name = tempName;
            studentId = tempNim;
            faculty = tempFaculty;
            department = tempDept;
            batch = tempBatch;

            skkmPoints = tempSkkm;
            eventsAttended = tempEvents;
            rank = realRank; // Rank yang sudah sinkron

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // LAYOUT TIDAK DIUBAH SAMA SEKALI
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStatsCard(),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAcademicInfo(),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSettingsMenu(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.9), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProfileAvatar(),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              studentId,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _buildRankBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person,
            size: 50,
            color: AppColors.primary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Peringkat #$rank',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ================= STATS =================

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            title: 'SKKM',
            value: skkmPoints.toString(),
            icon: Icons.workspace_premium,
            color: Colors.amber.shade700,
            suffix: 'Poin',
          ),
          _buildStatCard(
            title: 'Acara',
            value: eventsAttended.toString(),
            icon: Icons.event_available,
            color: Colors.green,
            suffix: 'Event',
          ),
          _buildStatCard(
            title: 'Peringkat',
            value: '#$rank',
            icon: Icons.leaderboard,
            color: Colors.purple,
            suffix: 'Global',
          ),
        ],
      ),
    );
  }

  // ================= ACADEMIC =================

  Widget _buildAcademicInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.apartment,
            label: 'Fakultas',
            value: faculty,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.book,
            label: 'Program Studi',
            value: department,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(icon: Icons.groups, label: 'Angkatan', value: batch),
        ],
      ),
    );
  }

  // ================= SETTINGS =================

  Widget _buildSettingsMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.edit,
            title: 'Edit Profil',
            color: AppColors.primary, // Atau Colors.blue
            onTap: () async {
              // Navigasi ke halaman Edit dan tunggu hasilnya
              // Pastikan kamu sudah import 'edit_profile_screen.dart'
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentName: name,
                    currentPhone:
                        '0812...', // Sebaiknya ambil dari variable state jika sudah di-load
                    currentFaculty: faculty,
                    currentDepartment: department,
                    currentBatch: batch,
                    nim:
                        studentId, // NIM biasanya tidak boleh diedit (read-only)
                  ),
                ),
              );

              // Jika result == true (berhasil simpan), refresh data di halaman ini
              if (result == true) {
                _loadProfileData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui!')),
                );
              }
            },
          ),
          const Divider(height: 1), // Garis pemisah
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // ================= REUSABLE =================

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String suffix,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          '$title • $suffix',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }

  // ================= LOGOUT =================

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _auth.signOut();
              // Pastikan route '/gate' atau route login kamu sesuai
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/gate',
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
