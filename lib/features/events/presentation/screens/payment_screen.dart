// lib/features/events/presentation/screens/payment_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  Uint8List? _paymentProofImageBytes;
  String? _paymentProofFileName;
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

  Future<void> _createPayment() async {
    _createdPayment = await _paymentRepository.createPayment(
      event: widget.event,
      userId: widget.userId,
      method: PaymentMethod.transferBank,
    );
    _selectedMethod = PaymentMethod.transferBank;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Event'),
      ),
      body: _createdPayment == null ? _buildLoading() : _buildContent(theme),
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

  Widget _buildContent(ThemeData theme) {
    final payment = _createdPayment!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(payment),
          const SizedBox(height: 30),
          _buildPaymentMethods(theme),
          const SizedBox(height: 20),
          if (_selectedMethod != null && !_showProofUpload)
            _buildPaymentDetails(),
          if (_showProofUpload) _buildPaymentProofUpload(theme),
          const SizedBox(height: 30),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  // ======================
  // ORDER SUMMARY
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
                      widget.event.judul,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.dateText} • ${widget.event.jamMulai}',
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
            _formatRupiah(widget.event.hargaOnline),
          ),
          _buildPriceDetail('Biaya Admin', _formatRupiah(2000)),

          Divider(color: Colors.grey.shade300),

          _buildPriceDetail(
            'Total Pembayaran',
            _formatRupiah(payment.amount),
            isTotal: true,
            themeColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildPriceDetail(String label, String value, {
    bool isTotal = false,
    Color? themeColor,
  }) {
    final primaryColor = themeColor ?? Theme.of(context).colorScheme.primary;
    
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
              color: isTotal ? primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ======================
  // PAYMENT METHODS
  // ======================
  Widget _buildPaymentMethods(ThemeData theme) {
    final methods = _paymentRepository.getPaymentMethods();
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...methods.map((method) => _buildPaymentMethodCard(method, primaryColor)).toList(),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodDetail method, Color primaryColor) {
    final isSelected = _selectedMethod == method.method;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(method.icon, color: primaryColor),
        title: Text(method.name),
        subtitle: Text(method.description),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: primaryColor)
            : const Icon(Icons.circle_outlined),
        onTap: () {
          setState(() {
            _selectedMethod = method.method;
            _showProofUpload = false;
            _createdPayment = _createdPayment!.copyWith(method: method.method);
          });
        },
      ),
    );
  }

  // ======================
  // PAYMENT DETAILS
  // ======================
  Widget _buildPaymentDetails() {
    final detail = _paymentRepository.getPaymentMethodDetail(_selectedMethod!);

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
  // UPLOAD BUKTI (FIXED FOR WEB)
  // ======================
  Widget _buildPaymentProofUpload(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Bukti Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        if (_paymentProofImageBytes != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.memory(
              _paymentProofImageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

        if (_paymentProofFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'File: $_paymentProofFileName',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),

        const SizedBox(height: 16),

        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Catatan (opsional)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 3,
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_paymentProofImageBytes != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _paymentProofImageBytes = null;
                      _paymentProofFileName = null;
                    });
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ======================
  // ACTION BUTTONS
  // ======================
  Widget _buildActionButtons(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;

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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload Bukti Pembayaran'),
            ),
          ),

        if (_showProofUpload)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading || _paymentProofImageBytes == null 
                  ? null 
                  : _uploadPaymentProof,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Kirim Bukti Pembayaran'),
            ),
          ),
      ],
    );
  }

  // ======================
  // IMAGE PICKER (FIXED FOR WEB)
  // ======================
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _paymentProofImageBytes = bytes;
          _paymentProofFileName = pickedFile.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ======================
  // UPLOAD BUKTI
  // ======================
  Future<void> _uploadPaymentProof() async {
    if (_paymentProofImageBytes == null) return;

    setState(() => _isUploading = true);

    try {
      final updated = await _paymentRepository.uploadPaymentProof(
        paymentId: _createdPayment!.id,
        imageBytes: _paymentProofImageBytes!,
        note: _noteController.text,
      );

      setState(() {
        _createdPayment = updated;
        _isUploading = false;
        _showProofUpload = false;
        _paymentProofImageBytes = null;
        _paymentProofFileName = null;
        _noteController.clear();
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload bukti: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Berhasil'),
        content: const Text('Bukti pembayaran berhasil dikirim. Tunggu verifikasi dari admin.'),
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