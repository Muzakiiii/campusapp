import 'package:flutter/material.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/shared/widgets/custom_button.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';
import 'package:campusapp/features/admin/data/repositories/admin_payment_repository.dart';
import 'package:campusapp/features/admin/presentation/widgets/payment_verification_tile.dart';

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
    });

    try {
      final payments = await _paymentRepository.getAllPayments();
      setState(() {
        _payments = payments;
        _filteredPayments = payments
            .where((payment) => payment.status == _selectedFilter)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Gagal memuat data pembayaran');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Payment> filtered = _payments.where((payment) {
      return payment.status == _selectedFilter;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        return payment.eventTitle.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            payment.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            payment.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredPayments = filtered;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Pembayaran'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('ID Pembayaran', payment.id),
              _buildDetailItem('Event', payment.eventTitle),
              _buildDetailItem('User ID', payment.userId),
              _buildDetailItem('Jumlah', 'Rp ${payment.amount.toInt()}'),
              _buildDetailItem('Metode', payment.methodName),
              _buildDetailItem('Status', payment.statusText),
              _buildDetailItem(
                'Tanggal Transaksi',
                '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year} ${payment.createdAt.hour}:${payment.createdAt.minute}',
              ),
              if (payment.paidAt != null)
                _buildDetailItem(
                  'Tanggal Bayar',
                  '${payment.paidAt!.day}/${payment.paidAt!.month}/${payment.paidAt!.year}',
                ),
              if (payment.verifiedAt != null)
                _buildDetailItem(
                  'Tanggal Verifikasi',
                  '${payment.verifiedAt!.day}/${payment.verifiedAt!.month}/${payment.verifiedAt!.year}',
                ),
              if (payment.note != null && payment.note!.isNotEmpty)
                _buildDetailItem('Catatan', payment.note!),
              if (payment.paymentProofUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Bukti Pembayaran:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        // TODO: Show image in full screen
                        _showImagePreview(payment.paymentProofUrl!);
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
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

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Container(
              height: 300,
              width: 300,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.image, size: 64, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'URL: $imageUrl',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _verifyPayment(Payment payment) async {
    final reason = await _showReasonDialog(
      'Verifikasi Pembayaran',
      'Apakah Anda yakin ingin memverifikasi pembayaran ini?',
      'Tambahkan catatan (opsional):',
    );

    if (reason != null) {
      try {
        await _paymentRepository.verifyPayment(payment.id, note: reason);
        _showSuccess('Pembayaran berhasil diverifikasi');
        _loadPayments(); // Refresh list
      } catch (e) {
        _showError('Gagal memverifikasi pembayaran');
      }
    }
  }

  Future<void> _rejectPayment(Payment payment) async {
    final reason = await _showReasonDialog(
      'Tolak Pembayaran',
      'Apakah Anda yakin ingin menolak pembayaran ini?',
      'Alasan penolakan (wajib):',
      isRequired: true,
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _paymentRepository.rejectPayment(payment.id, reason: reason);
        _showSuccess('Pembayaran berhasil ditolak');
        _loadPayments(); // Refresh list
      } catch (e) {
        _showError('Gagal menolak pembayaran');
      }
    } else if (reason != null && reason.isEmpty) {
      _showError('Harap masukkan alasan penolakan');
    }
  }

  Future<String?> _showReasonDialog(
    String title,
    String message,
    String hint, {
    bool isRequired = false,
  }) async {
    final TextEditingController reasonController = TextEditingController();

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
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '*Wajib diisi',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
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
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(PaymentStatus status, String label) {
    final isSelected = _selectedFilter == status;
    Color getStatusColor(PaymentStatus status) {
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

    final statusColor = getStatusColor(status);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = status;
            _applyFilters();
          });
        }
      },
      label: Text(label),
      backgroundColor: Colors.white,
      selectedColor: statusColor.withOpacity(0.2),
      checkmarkColor: statusColor,
      labelStyle: TextStyle(
        color: isSelected ? statusColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? statusColor : Colors.grey[300]!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pembayaran'),
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pembayaran...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Status Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              ],
            ),
          ),

          // Payment Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${_filteredPayments.length} pembayaran',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                CustomButton(
                  onPressed: _loadPayments,
                  text: 'Refresh',
                  backgroundColor: AppColors.primary,
                  height: 36,
                ),
              ],
            ),
          ),

          // Payment List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    child: _filteredPayments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedFilter == PaymentStatus.pending
                                      ? Icons.payments
                                      : _selectedFilter ==
                                            PaymentStatus.verified
                                      ? Icons.verified
                                      : Icons.block,
                                  size: 64,
                                  color: AppColors.textSecondary.withOpacity(
                                    0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilter == PaymentStatus.pending
                                      ? 'Tidak ada pembayaran yang menunggu verifikasi'
                                      : _selectedFilter ==
                                            PaymentStatus.verified
                                      ? 'Tidak ada pembayaran terverifikasi'
                                      : 'Tidak ada data pembayaran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                    child: const Text('Reset pencarian'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredPayments.length,
                            itemBuilder: (context, index) {
                              final payment = _filteredPayments[index];
                              return PaymentVerificationTile(
                                payment: payment,
                                onVerify: () => _verifyPayment(payment),
                                onReject: () => _rejectPayment(payment),
                                onViewDetails: () =>
                                    _showPaymentDetails(payment),
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
