// lib/features/events/data/repositories/payment_repository.dart
import 'dart:async';
import 'package:campusapp/features/events/domain/models/payment_model.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:flutter/material.dart';

class PaymentRepository {
  final List<Payment> _payments = [];
  final List<PaymentMethodDetail> _paymentMethods = [];

  PaymentRepository() {
    _initializePaymentMethods();
  }

  void _initializePaymentMethods() {
    _paymentMethods.addAll([
      PaymentMethodDetail(
        method: PaymentMethod.transferBank,
        name: 'Transfer Bank',
        description: 'Transfer ke rekening bank kami',
        icon: Icons.account_balance,
        banks: [
          Bank(name: 'BCA', number: '1234567890', holder: 'CAMPUS APP'),
          Bank(name: 'Mandiri', number: '0987654321', holder: 'CAMPUS APP'),
          Bank(name: 'BRI', number: '1122334455', holder: 'CAMPUS APP'),
          Bank(name: 'BNI', number: '5544332211', holder: 'CAMPUS APP'),
        ],
        color: Colors.blue,
      ),
      PaymentMethodDetail(
        method: PaymentMethod.eWallet,
        name: 'E-Wallet',
        description: 'Bayar via e-wallet populer',
        icon: Icons.wallet,
        wallets: [
          EWallet(name: 'OVO', number: '081234567890'),
          EWallet(name: 'GoPay', number: '081234567891'),
          EWallet(name: 'DANA', number: '081234567892'),
          EWallet(name: 'LinkAja', number: '081234567893'),
        ],
        color: Colors.green,
      ),
      PaymentMethodDetail(
        method: PaymentMethod.qris,
        name: 'QRIS',
        description: 'Scan QR Code untuk pembayaran',
        icon: Icons.qr_code,
        qrisCode: '00020101021126690014COM.GO-JEK.WWW011893600914...',
        color: Colors.purple,
      ),
      PaymentMethodDetail(
        method: PaymentMethod.virtualAccount,
        name: 'Virtual Account',
        description: 'Bayar via Virtual Account',
        icon: Icons.credit_card,
        banks: [
          Bank(name: 'BCA VA', number: '888801234567890', holder: 'CAMPUS APP VA'),
          Bank(name: 'Mandiri VA', number: '888809876543210', holder: 'CAMPUS APP VA'),
        ],
        color: Colors.orange,
      ),
      PaymentMethodDetail(
        method: PaymentMethod.creditCard,
        name: 'Kartu Kredit',
        description: 'Bayar dengan kartu kredit Visa/Mastercard',
        icon: Icons.credit_score,
        color: Colors.red,
      ),
    ]);
  }

  // ==============================
  // BUAT PEMBAYARAN BARU (FIX)
  // ==============================
  Payment createPayment({
    required EventModel event,
    required String userId,
    required PaymentMethod method,
  }) {
    final paymentId = DateTime.now().millisecondsSinceEpoch.toString();

    const double adminFee = 2000;
    final double eventPrice = event.onlinePrice > 0
        ? event.onlinePrice.toDouble()
        : event.offlinePrice.toDouble();
    final double totalAmount = eventPrice + adminFee;

    final payment = Payment(
      id: paymentId,
      eventId: event.id,
      userId: userId,
      eventTitle: event.judul, // FIX: judul
      amount: totalAmount,
      method: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      paymentCode: _generatePaymentCode(),
      virtualAccountNumber: method == PaymentMethod.virtualAccount
          ? '8888${paymentId.substring(paymentId.length - 10)}'
          : null,
    );

    _payments.add(payment);
    return payment;
  }

  String _generatePaymentCode() {
    return 'PAY${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  // ==============================
  // UPLOAD BUKTI PEMBAYARAN
  // ==============================
  Future<Payment> uploadPaymentProof({
    required String paymentId,
    required String imageUrl,
    String? note,
  }) async {
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      final updatedPayment = _payments[index].copyWith(
        paymentProofUrl: imageUrl,
        status: PaymentStatus.paid,
        paidAt: DateTime.now(),
        note: note,
      );

      _payments[index] = updatedPayment;
      await Future.delayed(const Duration(seconds: 2));
      return updatedPayment;
    }
    throw Exception('Payment not found');
  }

  Payment? getPayment(String paymentId) {
    try {
      return _payments.firstWhere((p) => p.id == paymentId);
    } catch (e) {
      return null;
    }
  }

  List<Payment> getUserPayments(String userId) {
    return _payments.where((p) => p.userId == userId).toList();
  }

  List<PaymentMethodDetail> getPaymentMethods() {
    return _paymentMethods;
  }

  PaymentMethodDetail? getPaymentMethodDetail(PaymentMethod method) {
    try {
      return _paymentMethods.firstWhere((pm) => pm.method == method);
    } catch (e) {
      return null;
    }
  }

  // ==============================
  // VERIFIKASI PEMBAYARAN (ADMIN)
  // ==============================
  Future<Payment> verifyPayment(
    String paymentId, {
    bool isVerified = true,
  }) async {
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      final updatedPayment = _payments[index].copyWith(
        status: isVerified
            ? PaymentStatus.verified
            : PaymentStatus.rejected,
        verifiedAt: DateTime.now(),
      );

      _payments[index] = updatedPayment;
      await Future.delayed(const Duration(seconds: 1));
      return updatedPayment;
    }
    throw Exception('Payment not found');
  }
}
