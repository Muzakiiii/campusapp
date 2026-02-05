// lib/features/events/presentation/screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:campusapp/core/themes/app_theme.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';
import 'package:campusapp/features/events/data/repositories/payment_repository.dart';

class PaymentScreen extends StatefulWidget {
  final EventModel event;
  final String userId;

  const PaymentScreen({
    super.key,
    required this.event,
    required this.userId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final ImagePicker _imagePicker = ImagePicker();

  PaymentMethod? _selectedMethod;
  Payment? _createdPayment;
  File? _paymentProofImage;
  late TextEditingController _noteController;
  bool _isUploading = false;
  bool _showProofUpload = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _createPayment();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ======================
  // FORMAT RUPIAH
  // ======================
  String _formatRupiah(num value) {
    return 'Rp ${value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  void _createPayment() {
    _createdPayment = _paymentRepository.createPayment(
      event: widget.event,
      userId: widget.userId,
      method: PaymentMethod.transferBank,
    );
    _selectedMethod = PaymentMethod.transferBank;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Event'),
      ),
      body: _createdPayment == null ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Menyiapkan pembayaran...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final payment = _createdPayment!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(payment),
          const SizedBox(height: 30),
          _buildPaymentMethods(),
          const SizedBox(height: 20),
          if (_selectedMethod != null && !_showProofUpload)
            _buildPaymentDetails(),
          if (_showProofUpload) _buildPaymentProofUpload(),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ======================
  // ORDER SUMMARY (FIXED)
  // ======================
  Widget _buildOrderSummary(Payment payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.event.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.event.categoryIcon,
                  color: widget.event.categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.judul, // ✅ FIX
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.dateText} • ${widget.event.jamMulai}', // ✅ FIX
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),

          _buildPriceDetail(
            'Biaya Event',
            _formatRupiah(widget.event.hargaOnline), // ✅ FIX
          ),
          _buildPriceDetail('Biaya Admin', _formatRupiah(2000)),

          Divider(color: Colors.grey.shade300),

          _buildPriceDetail(
            'Total Pembayaran',
            _formatRupiah(payment.amount),
            isTotal: true,
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: payment.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: payment.statusColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: payment.statusColor),
                const SizedBox(width: 8),
                Text(
                  payment.statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: payment.statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetail(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w700,
              color: isTotal ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ======================
  // PAYMENT METHODS
  // ======================
  Widget _buildPaymentMethods() {
    final methods = _paymentRepository.getPaymentMethods();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...methods.map(_buildPaymentMethodCard).toList(),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodDetail method) {
    final isSelected = _selectedMethod == method.method;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(method.icon, color: AppColors.primary),
        title: Text(method.name),
        subtitle: Text(method.description),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.circle_outlined),
        onTap: () {
          setState(() {
            _selectedMethod = method.method;
            _showProofUpload = false;
            _createdPayment =
                _createdPayment!.copyWith(method: method.method);
          });
        },
      ),
    );
  }

  // ======================
  // PAYMENT DETAILS
  // ======================
  Widget _buildPaymentDetails() {
    final detail =
        _paymentRepository.getPaymentMethodDetail(_selectedMethod!);

    if (detail == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        if (detail.banks != null)
          ...detail.banks!.map(
            (bank) => ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(bank.name),
              subtitle: Text('${bank.number} a.n ${bank.holder}'),
            ),
          ),

        if (detail.wallets != null)
          ...detail.wallets!.map(
            (wallet) => ListTile(
              leading: const Icon(Icons.wallet),
              title: Text(wallet.name),
              subtitle: Text(wallet.number),
            ),
          ),

        if (detail.qrisCode != null)
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('QRIS'),
            subtitle: Text(detail.qrisCode!),
          ),
      ],
    );
  }

  // ======================
  // UPLOAD BUKTI
  // ======================
  Widget _buildPaymentProofUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Bukti Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        if (_paymentProofImage != null)
          Image.file(_paymentProofImage!, height: 200),

        const SizedBox(height: 12),

        TextField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
        ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: const Text('Pilih Gambar'),
        ),
      ],
    );
  }

  // ======================
  // ACTION BUTTONS
  // ======================
  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_showProofUpload)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showProofUpload = true;
                });
              },
              child: const Text('Upload Bukti Pembayaran'),
            ),
          ),

        if (_showProofUpload)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadPaymentProof,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Kirim Bukti'),
            ),
          ),
      ],
    );
  }

  // ======================
  // IMAGE PICKER
  // ======================
  Future<void> _pickImage() async {
    final picked =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _paymentProofImage = File(picked.path);
      });
    }
  }

  // ======================
  // UPLOAD (SIMULASI)
  // ======================
  Future<void> _uploadPaymentProof() async {
    if (_paymentProofImage == null) return;

    setState(() => _isUploading = true);

    try {
      final updated = await _paymentRepository.uploadPaymentProof(
        paymentId: _createdPayment!.id,
        imageUrl: _paymentProofImage!.path,
        note: _noteController.text,
      );

      setState(() {
        _createdPayment = updated;
        _isUploading = false;
        _showProofUpload = false;
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload: $e')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Berhasil'),
        content: const Text('Bukti pembayaran berhasil dikirim.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
