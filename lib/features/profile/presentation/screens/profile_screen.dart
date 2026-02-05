import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusapp/core/themes/app_theme.dart';

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

      // ================= USER PROFILE =================
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        name = data['name'] ?? '-';
        studentId = data['studentId'] ?? '-';
        faculty = data['faculty'] ?? '-';
        department = data['department'] ?? '-';
        batch = data['batch'] ?? '-';
      }

      // ================= EVENTS ATTENDED =================
      final regSnap = await _firestore
          .collection('registrations')
          .where('uid', isEqualTo: uid)
          .where('status', isEqualTo: 'verified')
          .get();

      eventsAttended = regSnap.docs.length;

      // ================= SKKM POINTS =================
      skkmPoints = regSnap.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['skkm'] ?? 0) as int),
      );

      // ================= RANK (SIMPLE GLOBAL) =================
      final allUsersSnap = await _firestore.collection('users').get();
      rank = allUsersSnap.docs.length; // placeholder rank sederhana

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Profile load error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primary,
          ],
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
          _buildInfoRow(
            icon: Icons.groups,
            label: 'Angkatan',
            value: batch,
          ),
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
      ),
      child: Column(
        children: [
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
        Text('$title • $suffix',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600)),
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/gate',
                (route) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
