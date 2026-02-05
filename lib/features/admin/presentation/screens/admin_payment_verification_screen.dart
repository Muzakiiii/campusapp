// lib/features/admin/presentation/screens/admin_payment_verification_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';
import 'package:campusapp/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:campusapp/features/admin/presentation/widgets/payment_verification_tile.dart';
import 'package:intl/intl.dart';

class AdminPaymentVerificationScreen extends StatefulWidget {
  const AdminPaymentVerificationScreen({super.key});

  @override
  State<AdminPaymentVerificationScreen> createState() =>
      _AdminPaymentVerificationScreenState();
}

class _AdminPaymentVerificationScreenState
    extends State<AdminPaymentVerificationScreen> {
  final AdminPaymentRepository _paymentRepository = AdminPaymentRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  PaymentStatus _selectedFilter = PaymentStatus.pending;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _payments = [];
      _filteredPayments = [];
    });

    try {
      print('Loading payments from Firestore...');
      final payments = await _paymentRepository.getAllPayments();
      print('Successfully loaded ${payments.length} payments');
      
      if (payments.isNotEmpty) {
        print('=== PAYMENTS DATA SAMPLE ===');
        for (var i = 0; i < min(3, payments.length); i++) {
          final payment = payments[i];
          print('Payment ${i + 1}:');
          print('  ID: ${payment.id}');
          print('  Event: ${payment.eventTitle}');
          print('  Status: ${payment.status} (${payment.statusText})');
          print('  Method: ${payment.method} (${payment.methodName})');
          print('  Amount: Rp${payment.amount}');
          print('  User ID: ${payment.userId}');
          print('  Created: ${payment.createdAt}');
          print('  Note: ${payment.note ?? "null"}');
          print('---');
        }
      }
      
      setState(() {
        _payments = payments;
        _filteredPayments = payments
            .where((payment) => payment.status == _selectedFilter)
            .toList();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ ERROR loading payments: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      _showError('Gagal memuat data pembayaran. Periksa koneksi atau data format.');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Payment> filtered = _payments.where((payment) {
      return payment.status == _selectedFilter;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        final eventTitle = payment.eventTitle.toLowerCase();
        final userId = payment.userId.toLowerCase();
        final paymentId = payment.id.toLowerCase();
        final paymentCode = payment.paymentCode?.toLowerCase() ?? '';
        final methodName = payment.methodName.toLowerCase();
        final note = payment.note?.toLowerCase() ?? '';
        
        return eventTitle.contains(_searchQuery) ||
            userId.contains(_searchQuery) ||
            paymentId.contains(_searchQuery) ||
            paymentCode.contains(_searchQuery) ||
            methodName.contains(_searchQuery) ||
            note.contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _filteredPayments = filtered;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(payment.methodIcon, color: payment.statusColor),
            const SizedBox(width: 8),
            const Text('Detail Pembayaran'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Kode Pembayaran', payment.paymentCode ?? '-'),
              _buildDetailItem('ID', payment.id),
              const SizedBox(height: 8),
              _buildDetailItem('Event', payment.eventTitle),
              const SizedBox(height: 8),
              _buildDetailItem('User ID', payment.userId),
              const SizedBox(height: 8),
              _buildDetailItem('Jumlah', _formatRupiah(payment.amount)),
              const SizedBox(height: 8),
              _buildDetailItem('Metode', payment.methodName),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: payment.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: payment.statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  payment.statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: payment.statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailItem('Tanggal Transaksi', _formatDateTime(payment.createdAt)),
              
              if (payment.virtualAccountNumber != null && payment.virtualAccountNumber!.isNotEmpty)
                _buildDetailItem('Virtual Account', payment.virtualAccountNumber!),
              
              if (payment.paidAt != null)
                _buildDetailItem('Tanggal Bayar', _formatDateTime(payment.paidAt!)),
              
              if (payment.verifiedAt != null)
                _buildDetailItem('Tanggal Verifikasi', _formatDateTime(payment.verifiedAt!)),
              
              if (payment.note != null && payment.note!.isNotEmpty)
                _buildDetailItem('Catatan', payment.note!),
              
              if (payment.paymentProofUrl != null && payment.paymentProofUrl!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Bukti Pembayaran:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showImagePreview(payment.paymentProofUrl!),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                        ),
                        child: payment.paymentProofUrl!.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  payment.paymentProofUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder();
                                  },
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
                                ),
                              )
                            : _buildImagePlaceholder(),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'Lihat Bukti',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bukti Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            Container(
              height: 400,
              width: 400,
              color: Colors.grey[100],
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Gagal memuat gambar',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  imageUrl,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              imageUrl,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPayment(Payment payment) async {
    final reason = await _showReasonDialog(
      title: 'Verifikasi Pembayaran',
      message: 'Apakah Anda yakin ingin memverifikasi pembayaran ini?',
      hint: 'Tambahkan catatan (opsional):',
      isRequired: false,
    );

    if (reason != null) {
      try {
        await _paymentRepository.verifyPayment(payment.id, note: reason);
        _showSuccess('Pembayaran berhasil diverifikasi');
        await _loadPayments();
      } catch (e) {
        _showError('Gagal memverifikasi pembayaran: ${e.toString()}');
      }
    }
  }

  Future<void> _rejectPayment(Payment payment) async {
    final reason = await _showReasonDialog(
      title: 'Tolak Pembayaran',
      message: 'Apakah Anda yakin ingin menolak pembayaran ini?',
      hint: 'Alasan penolakan (wajib):',
      isRequired: true,
    );

    if (reason != null) {
      if (reason.isEmpty) {
        _showError('Harap masukkan alasan penolakan');
        return;
      }
      
      try {
        await _paymentRepository.rejectPayment(payment.id, reason: reason);
        _showSuccess('Pembayaran berhasil ditolak');
        await _loadPayments();
      } catch (e) {
        _showError('Gagal menolak pembayaran: ${e.toString()}');
      }
    }
  }

  Future<String?> _showReasonDialog({
    required String title,
    required String message,
    required String hint,
    bool isRequired = false,
  }) async {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
                validator: isRequired
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap isi alasan penolakan';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '*Wajib diisi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? true) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(PaymentStatus status, String label) {
    final isSelected = _selectedFilter == status;
    
    final statusColor = _getStatusColor(status);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = status;
          _applyFilters();
        });
      },
      label: Text(label),
      backgroundColor: Colors.white,
      selectedColor: statusColor.withOpacity(0.15),
      checkmarkColor: statusColor,
      labelStyle: TextStyle(
        color: isSelected ? statusColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? statusColor : Colors.grey[300]!,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.blue;
      case PaymentStatus.verified:
        return Colors.green;
      case PaymentStatus.rejected:
        return Colors.red;
      case PaymentStatus.expired:
        return Colors.grey;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'menunggu';
      case PaymentStatus.paid:
        return 'sudah bayar';
      case PaymentStatus.verified:
        return 'terverifikasi';
      case PaymentStatus.rejected:
        return 'ditolak';
      case PaymentStatus.expired:
        return 'kadaluarsa';
      case PaymentStatus.cancelled:
        return 'dibatalkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari pembayaran...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),

          // Status Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatusFilterChip(PaymentStatus.pending, 'Menunggu'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(PaymentStatus.paid, 'Sudah Bayar'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(PaymentStatus.verified, 'Terverifikasi'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(PaymentStatus.rejected, 'Ditolak'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(PaymentStatus.expired, 'Kadaluarsa'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(PaymentStatus.cancelled, 'Dibatalkan'),
                ],
              ),
            ),
          ),

          // Payment Count and Refresh
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${_payments.length} pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ditampilkan: ${_filteredPayments.length} ${_getStatusLabel(_selectedFilter)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                CustomButton(
                  onPressed: _loadPayments,
                  text: 'Refresh',
                  backgroundColor: primaryColor,
                  height: 36,
                  width: 100,
                ),
              ],
            ),
          ),

          // Payment List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Memuat data pembayaran...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    color: primaryColor,
                    displacement: 40,
                    child: _filteredPayments.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedFilter == PaymentStatus.pending
                                        ? Icons.payments_outlined
                                        : _selectedFilter == PaymentStatus.verified
                                            ? Icons.verified_outlined
                                            : Icons.block_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedFilter == PaymentStatus.pending
                                        ? 'Tidak ada pembayaran yang menunggu verifikasi'
                                        : _selectedFilter == PaymentStatus.verified
                                            ? 'Tidak ada pembayaran terverifikasi'
                                            : 'Tidak ada data pembayaran',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  if (_searchQuery.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: TextButton(
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                        child: const Text('Reset pencarian'),
                                      ),
                                    ),
                                  TextButton(
                                    onPressed: _loadPayments,
                                    child: const Text('Muat ulang data'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredPayments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final payment = _filteredPayments[index];
                              return PaymentVerificationTile(
                                payment: payment,
                                onVerify: () => _verifyPayment(payment),
                                onReject: () => _rejectPayment(payment),
                                onViewDetails: () => _showPaymentDetails(payment),
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