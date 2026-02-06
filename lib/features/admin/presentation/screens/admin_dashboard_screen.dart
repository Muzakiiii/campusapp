import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/app/routes.dart';
import 'package:campusapp/features/admin/data/repositories/admin_event_repository.dart';
import 'package:campusapp/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:campusapp/features/admin/presentation/widgets/stats_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminEventRepository _eventRepository = AdminEventRepository();
  final AdminPaymentRepository _paymentRepository = AdminPaymentRepository();

  Map<String, dynamic> _stats = {
    'totalEvents': 0,
    'activeEvents': 0,
    'pendingPayments': 0,
    'verifiedPayments': 0,
    'totalParticipants': 0,
    'totalRevenue': 0.0,
    'paymentStats': {
      'totalPayments': 0,
      'rejectedCount': 0,
    }
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final eventStats = await _eventRepository.getDashboardStats();
      final paymentStats = await _paymentRepository.getPaymentStatistics();

      setState(() {
        _stats = {
          'totalEvents': eventStats.totalEvents,
          'activeEvents': eventStats.activeEvents,
          'pendingPayments': eventStats.pendingPayments,
          'verifiedPayments': eventStats.verifiedPayments,
          'totalParticipants': eventStats.totalParticipants,
          'totalRevenue': eventStats.totalRevenue,
          'paymentStats': paymentStats,
        };
        _isLoading = false;
      });
    } catch (e) {
      _isLoading = false;
      _showError('Gagal memuat data dashboard');
      setState(() {});
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _navigateToEventList() {
    Navigator.pushNamed(context, Routes.adminEventList);
  }

  void _navigateToCreateEvent() {
    Navigator.pushNamed(context, Routes.adminCreateEvent);
  }

  void _navigateToPaymentVerification() {
    Navigator.pushNamed(context, Routes.adminPaymentVerification);
  }

  // Fungsi untuk menampilkan konfirmasi logout
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun admin?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _logout(); // Panggil fungsi logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, Routes.gate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            onPressed: _showLogoutConfirmation, // Panggil fungsi konfirmasi
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildEventStats(),
                    const SizedBox(height: 24),
                    _buildPaymentStats(),
                    const SizedBox(height: 24),
                    _buildManageEvents(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ================= WIDGET SECTIONS =================

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.admin_panel_settings,
              size: 32,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang, Admin!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola event dan verifikasi pembayaran dengan mudah',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _navigateToCreateEvent,
                text: 'Buat Event Baru',
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                onPressed: _navigateToPaymentVerification,
                text: 'Verifikasi Pembayaran',
                backgroundColor: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Event',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            StatsCard(
              title: 'Total Event',
              value: '${_stats['totalEvents']}',
              icon: Icons.event,
              color: AppColors.primary,
            ),
            StatsCard(
              title: 'Event Aktif',
              value: '${_stats['activeEvents']}',
              icon: Icons.event_available,
              color: AppColors.success,
              subtitle: 'Aktif',
            ),
            StatsCard(
              title: 'Total Peserta',
              value: '${_stats['totalParticipants']}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            StatsCard(
              title: 'Total Pendapatan',
              value: 'Rp ${(_stats['totalRevenue'] as num).toInt()}',
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            StatsCard(
              title: 'Menunggu Verifikasi',
              value: '${_stats['pendingPayments']}',
              icon: Icons.pending_actions,
              color: AppColors.warning,
            ),
            StatsCard(
              title: 'Terverifikasi',
              value: '${_stats['verifiedPayments']}',
              icon: Icons.verified,
              color: AppColors.success,
            ),
            StatsCard(
              title: 'Total Transaksi',
              value:
                  '${_stats['paymentStats']['totalPayments']}',
              icon: Icons.payments,
              color: Colors.purple,
            ),
            StatsCard(
              title: 'Ditolak',
              value:
                  '${_stats['paymentStats']['rejectedCount']}',
              icon: Icons.block,
              color: AppColors.error,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManageEvents() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kelola Event',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lihat dan edit semua event yang telah dibuat',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: _navigateToEventList,
            text: 'Lihat Semua Event',
            width: double.infinity,
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}