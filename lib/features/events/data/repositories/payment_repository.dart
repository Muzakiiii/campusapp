// lib/features/events/data/repositories/payment_repository.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';

class Bank {
  final String name;
  final String number;
  final String holder;

  Bank({
    required this.name,
    required this.number,
    required this.holder,
  });
}

class EWallet {
  final String name;
  final String number;

  EWallet({
    required this.name,
    required this.number,
  });
}

class PaymentMethodDetail {
  final PaymentMethod method;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<Bank>? banks;
  final List<EWallet>? wallets;
  final String? qrisCode;

  PaymentMethodDetail({
    required this.method,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.banks,
    this.wallets,
    this.qrisCode,
  });
}

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;
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
  // BUAT PEMBAYARAN BARU DAN SIMPAN KE FIRESTORE
  // ==============================
  Future<Payment> createPayment({
    required EventModel event,
    required String userId,
    required PaymentMethod method,
  }) async {
    try {
      // Generate payment ID dan code
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final paymentCode = _generatePaymentCode();

      // Hitung total amount
      const double adminFee = 2000;
      final double eventPrice = event.hargaOnline > 0
          ? event.hargaOnline.toDouble()
          : event.hargaOffline.toDouble();
      final double totalAmount = eventPrice + adminFee;

      // Buat payment object
      final payment = Payment(
        id: paymentId,
        eventId: event.id,
        userId: userId,
        eventTitle: event.judul,
        amount: totalAmount,
        method: method,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        paymentCode: paymentCode,
        virtualAccountNumber: method == PaymentMethod.virtualAccount
            ? '8888${paymentId.substring(paymentId.length - 10)}'
            : null,
      );

      // Simpan ke Firestore
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .set(payment.toFirestore());

      print('✅ Payment created successfully: $paymentId');
      return payment;
    } catch (e) {
      print('❌ Error creating payment: $e');
      throw Exception('Gagal membuat pembayaran: $e');
    }
  }

  String _generatePaymentCode() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = now.millisecondsSinceEpoch.toString().substring(9);
    return 'PAY$month$day$random';
  }

  // ==============================
  // UPLOAD BUKTI PEMBAYARAN KE FIREBASE STORAGE
  // ==============================
  Future<String> _uploadImageToStorage(
      Uint8List imageBytes, String paymentId) async {
    try {
      final fileName = 'payment_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('payment_proofs/$paymentId/$fileName');
      
      final uploadTask = storageRef.putData(
        imageBytes,
        firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Gagal mengupload gambar: $e');
    }
  }

  // ==============================
  // UPLOAD BUKTI PEMBAYARAN
  // ==============================
  Future<Payment> uploadPaymentProof({
    required String paymentId,
    required Uint8List imageBytes,
    String? note,
  }) async {
    try {
      // 1. Upload image ke Firebase Storage
      final imageUrl = await _uploadImageToStorage(imageBytes, paymentId);

      // 2. Update payment di Firestore
      final updatedData = {
        'paymentProofUrl': imageUrl,
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (note != null && note.isNotEmpty) 'note': note,
      };

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updatedData);

      // 3. Ambil data terbaru
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (!doc.exists) {
        throw Exception('Payment tidak ditemukan');
      }

      final updatedPayment = Payment.fromFirestore(doc.data()!, doc.id);
      print('✅ Payment proof uploaded successfully');
      return updatedPayment;
    } catch (e) {
      print('❌ Error uploading payment proof: $e');
      throw Exception('Gagal upload bukti pembayaran: $e');
    }
  }

  // ==============================
  // GET PAYMENT BY ID
  // ==============================
  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (!doc.exists) return null;
      
      return Payment.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error getting payment: $e');
      return null;
    }
  }

  // ==============================
  // GET USER PAYMENTS
  // ==============================
  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      final snap = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs
          .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting user payments: $e');
      return [];
    }
  }

  // ==============================
  // GET PAYMENT BY EVENT AND USER
  // ==============================
  Future<Payment?> getPaymentByEventAndUser(
      String eventId, String userId) async {
    try {
      final snap = await _firestore
          .collection('payments')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      return Payment.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
    } catch (e) {
      print('❌ Error getting payment by event and user: $e');
      return null;
    }
  }

  // ==============================
  // GET PAYMENT METHODS (UI)
  // ==============================
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
    String? note,
  }) async {
    try {
      final status = isVerified ? 'verified' : 'rejected';
      final adminNote = note != null && note.isNotEmpty ? note : null;
      
      final updatedData = {
        'status': status,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (adminNote != null) 'adminNote': adminNote,
      };

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updatedData);

      // Ambil data terbaru
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (!doc.exists) {
        throw Exception('Payment tidak ditemukan');
      }

      final updatedPayment = Payment.fromFirestore(doc.data()!, doc.id);
      print('✅ Payment $status successfully: $paymentId');
      return updatedPayment;
    } catch (e) {
      print('❌ Error verifying payment: $e');
      throw Exception('Gagal memverifikasi pembayaran: $e');
    }
  }

  // ==============================
  // CANCEL PAYMENT
  // ==============================
  Future<void> cancelPayment(String paymentId, {String? reason}) async {
    try {
      final updatedData = {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        if (reason != null && reason.isNotEmpty) 'cancelReason': reason,
      };

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updatedData);

      print('✅ Payment cancelled successfully: $paymentId');
    } catch (e) {
      print('❌ Error cancelling payment: $e');
      throw Exception('Gagal membatalkan pembayaran: $e');
    }
  }

  // ==============================
  // PAYMENT STATISTICS
  // ==============================
  Future<Map<String, dynamic>> getPaymentStatistics(String userId) async {
    try {
      final snap = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();

      final totalPayments = snap.docs.length;
      
      final pendingCount = snap.docs
          .where((d) => Payment.fromFirestore(d.data(), d.id).status == PaymentStatus.pending)
          .length;
      
      final verifiedCount = snap.docs
          .where((d) => Payment.fromFirestore(d.data(), d.id).status == PaymentStatus.verified)
          .length;
      
      final totalAmount = snap.docs
          .where((d) => Payment.fromFirestore(d.data(), d.id).status == PaymentStatus.verified)
          .fold<double>(0.0, (sum, d) => sum + (d.data()['amount'] ?? 0));

      return {
        'totalPayments': totalPayments,
        'pendingCount': pendingCount,
        'verifiedCount': verifiedCount,
        'totalAmount': totalAmount,
      };
    } catch (e) {
      print('❌ Error getting payment statistics: $e');
      return {
        'totalPayments': 0,
        'pendingCount': 0,
        'verifiedCount': 0,
        'totalAmount': 0.0,
      };
    }
  }

  // ==============================
  // DELETE PAYMENT (Hanya untuk development/testing)
  // ==============================
  Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();
      print('✅ Payment deleted successfully: $paymentId');
    } catch (e) {
      print('❌ Error deleting payment: $e');
      throw Exception('Gagal menghapus pembayaran: $e');
    }
  }

  // ==============================
  // STREAM PAYMENTS FOR REAL-TIME UPDATES
  // ==============================
  Stream<List<Payment>> streamUserPayments(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ==============================
  // CHECK IF USER HAS PAID FOR EVENT
  // ==============================
  Future<bool> hasUserPaidForEvent(String eventId, String userId) async {
    try {
      final payment = await getPaymentByEventAndUser(eventId, userId);
      if (payment == null) return false;
      
      return payment.status == PaymentStatus.verified || 
             payment.status == PaymentStatus.paid;
    } catch (e) {
      print('❌ Error checking payment status: $e');
      return false;
    }
  }
}