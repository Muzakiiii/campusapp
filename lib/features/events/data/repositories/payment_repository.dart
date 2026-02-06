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
      print('🔄 Membuat pembayaran untuk event: ${event.judul}');
      print('👤 User ID: $userId');
      print('💰 Metode: ${method.toString()}');

      // Validasi input
      if (userId.isEmpty) {
        throw Exception('User ID tidak valid');
      }

      if (event.id.isEmpty) {
        throw Exception('Event ID tidak valid');
      }

      // Hitung total amount
      const double adminFee = 2000;
      final double eventPrice = event.hargaOnline > 0
          ? event.hargaOnline.toDouble()
          : event.hargaOffline.toDouble();
      final double totalAmount = eventPrice + adminFee;

      // Cek apakah user sudah memiliki pembayaran untuk event ini
      final existingPayment = await getPaymentByEventAndUser(event.id, userId);
      if (existingPayment != null) {
        print('⚠️ User sudah memiliki pembayaran untuk event ini');
        return existingPayment;
      }

      // Generate payment ID dan code
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final paymentCode = _generatePaymentCode();

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

      print('📝 Data pembayaran yang akan disimpan:');
      print('  ID: $paymentId');
      print('  Kode: $paymentCode');
      print('  Jumlah: $totalAmount');
      print('  Status: ${payment.status}');

      // Simpan ke Firestore dengan timeout
      await _executeWithTimeout(
        () async {
          await _firestore
              .collection('payments')
              .doc(paymentId)
              .set(payment.toFirestore());
        },
        timeout: Duration(seconds: 15),
        operationName: 'Menyimpan ke Firestore',
      );

      // Verifikasi data tersimpan
      final verifyDoc = await _firestore
          .collection('payments')
          .doc(paymentId)
          .get()
          .timeout(Duration(seconds: 10));

      if (!verifyDoc.exists) {
        throw Exception('Gagal memverifikasi penyimpanan data');
      }

      print('✅ Payment created successfully: $paymentId');
      return payment;
    } on TimeoutException catch (e) {
      print('⏰ Timeout creating payment: $e');
      throw Exception('Timeout: Gagal membuat pembayaran. Cek koneksi internet Anda.');
    } on FirebaseException catch (e) {
      print('🔥 Firebase error creating payment: ${e.code} - ${e.message}');
      
      String errorMessage = 'Gagal membuat pembayaran';
      switch (e.code) {
        case 'permission-denied':
          errorMessage = 'Akses ditolak. Pastikan Anda sudah login.';
          break;
        case 'unavailable':
          errorMessage = 'Firebase tidak tersedia. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          errorMessage = 'Gagal koneksi ke server. Cek koneksi internet.';
          break;
      }
      
      throw Exception('$errorMessage (${e.code})');
    } catch (e) {
      print('❌ Error creating payment: $e');
      
      // Format error message lebih user-friendly
      if (e.toString().contains('connection') || e.toString().contains('network')) {
        throw Exception('Gagal koneksi ke server. Periksa koneksi internet Anda dan coba lagi.');
      } else if (e.toString().contains('permission')) {
        throw Exception('Tidak memiliki izin untuk membuat pembayaran. Pastikan Anda sudah login.');
      } else {
        throw Exception('Gagal membuat pembayaran: ${e.toString().split(':').last.trim()}');
      }
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
  // HELPER: EXECUTE WITH TIMEOUT
  // ==============================
  Future<void> _executeWithTimeout(
    Future<void> Function() operation,
    {
      required Duration timeout,
      required String operationName,
    }
  ) async {
    try {
      await operation().timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('$operationName timeout setelah ${timeout.inSeconds} detik');
    }
  }

  // ==============================
  // UPLOAD BUKTI PEMBAYARAN KE FIREBASE STORAGE
  // ==============================
  Future<String> _uploadImageToStorage(
      Uint8List imageBytes, String paymentId) async {
    try {
      print('🔄 Mengupload gambar untuk payment: $paymentId');
      print('📁 Ukuran file: ${imageBytes.length} bytes');
      
      final fileName = 'payment_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('payment_proofs/$paymentId/$fileName');
      
      final uploadTask = storageRef.putData(
        imageBytes,
        firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Tambah timeout untuk upload
      final snapshot = await uploadTask
          .timeout(Duration(seconds: 30))
          .onError((error, stackTrace) {
            throw TimeoutException('Upload gambar timeout setelah 30 detik');
          });
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploaded successfully: ${downloadUrl.substring(0, 50)}...');
      return downloadUrl;
    } on firebase_storage.FirebaseException catch (e) {
      print('🔥 Storage error: ${e.code} - ${e.message}');
      
      String errorMessage = 'Gagal mengupload gambar';
      switch (e.code) {
        case 'unauthorized':
          errorMessage = 'Tidak memiliki izin untuk upload gambar';
          break;
        case 'bucket-not-found':
          errorMessage = 'Storage bucket tidak ditemukan';
          break;
        case 'object-not-found':
          errorMessage = 'File tidak ditemukan';
          break;
        case 'quota-exceeded':
          errorMessage = 'Quota storage telah terlampaui';
          break;
      }
      
      throw Exception('$errorMessage (${e.code})');
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Gagal mengupload gambar: ${e.toString().split(':').last.trim()}');
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
      print('🔄 Uploading payment proof for: $paymentId');
      
      // Validasi input
      if (imageBytes.isEmpty) {
        throw Exception('Gambar tidak valid');
      }
      
      if (imageBytes.length > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Ukuran gambar terlalu besar (maks 10MB)');
      }

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

      await _executeWithTimeout(
        () async {
          await _firestore
              .collection('payments')
              .doc(paymentId)
              .update(updatedData);
        },
        timeout: Duration(seconds: 15),
        operationName: 'Update payment status',
      );

      // 3. Ambil data terbaru dengan timeout
      final doc = await _firestore.collection('payments').doc(paymentId)
          .get()
          .timeout(Duration(seconds: 10));
          
      if (!doc.exists) {
        throw Exception('Payment tidak ditemukan setelah update');
      }

      final updatedPayment = Payment.fromFirestore(doc.data()!, doc.id);
      print('✅ Payment proof uploaded successfully');
      return updatedPayment;
    } on TimeoutException catch (e) {
      print('⏰ Timeout uploading payment proof: $e');
      throw Exception('Timeout: Gagal upload bukti pembayaran. Coba lagi.');
    } catch (e) {
      print('❌ Error uploading payment proof: $e');
      throw Exception('Gagal upload bukti pembayaran: ${e.toString().split(':').last.trim()}');
    }
  }

  // ==============================
  // GET PAYMENT BY ID
  // ==============================
  Future<Payment?> getPayment(String paymentId) async {
    try {
      print('🔄 Mengambil payment: $paymentId');
      
      final doc = await _firestore.collection('payments').doc(paymentId)
          .get()
          .timeout(Duration(seconds: 10));
          
      if (!doc.exists) {
        print('⚠️ Payment tidak ditemukan: $paymentId');
        return null;
      }
      
      print('✅ Payment ditemukan: $paymentId');
      return Payment.fromFirestore(doc.data()!, doc.id);
    } on TimeoutException {
      print('⏰ Timeout mengambil payment');
      return null;
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
      print('🔄 Mengambil payments user: $userId');
      
      final snap = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(Duration(seconds: 15));

      print('✅ Found ${snap.docs.length} payments for user: $userId');
      return snap.docs
          .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
          .toList();
    } on TimeoutException {
      print('⏰ Timeout mengambil user payments');
      return [];
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
      print('🔄 Mencari payment untuk event: $eventId, user: $userId');
      
      final snap = await _firestore
          .collection('payments')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get()
          .timeout(Duration(seconds: 10));

      if (snap.docs.isEmpty) {
        print('ℹ️ Tidak ada payment ditemukan untuk event dan user ini');
        return null;
      }

      print('✅ Payment ditemukan: ${snap.docs.first.id}');
      return Payment.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
    } on TimeoutException {
      print('⏰ Timeout mencari payment');
      return null;
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

      await _executeWithTimeout(
        () async {
          await _firestore
              .collection('payments')
              .doc(paymentId)
              .update(updatedData);
        },
        timeout: Duration(seconds: 15),
        operationName: 'Verifikasi payment',
      );

      // Ambil data terbaru
      final doc = await _firestore.collection('payments').doc(paymentId)
          .get()
          .timeout(Duration(seconds: 10));
          
      if (!doc.exists) {
        throw Exception('Payment tidak ditemukan setelah verifikasi');
      }

      final updatedPayment = Payment.fromFirestore(doc.data()!, doc.id);
      print('✅ Payment $status successfully: $paymentId');
      return updatedPayment;
    } on TimeoutException catch (e) {
      print('⏰ Timeout verifying payment: $e');
      throw Exception('Timeout: Gagal memverifikasi pembayaran');
    } catch (e) {
      print('❌ Error verifying payment: $e');
      throw Exception('Gagal memverifikasi pembayaran: ${e.toString().split(':').last.trim()}');
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

      await _executeWithTimeout(
        () async {
          await _firestore
              .collection('payments')
              .doc(paymentId)
              .update(updatedData);
        },
        timeout: Duration(seconds: 15),
        operationName: 'Cancel payment',
      );

      print('✅ Payment cancelled successfully: $paymentId');
    } on TimeoutException catch (e) {
      print('⏰ Timeout cancelling payment: $e');
      throw Exception('Timeout: Gagal membatalkan pembayaran');
    } catch (e) {
      print('❌ Error cancelling payment: $e');
      throw Exception('Gagal membatalkan pembayaran: ${e.toString().split(':').last.trim()}');
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
          .get()
          .timeout(Duration(seconds: 15));

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

      print('✅ Statistics: total=$totalPayments, pending=$pendingCount, verified=$verifiedCount, amount=$totalAmount');
      
      return {
        'totalPayments': totalPayments,
        'pendingCount': pendingCount,
        'verifiedCount': verifiedCount,
        'totalAmount': totalAmount,
      };
    } on TimeoutException {
      print('⏰ Timeout mengambil statistics');
      return {
        'totalPayments': 0,
        'pendingCount': 0,
        'verifiedCount': 0,
        'totalAmount': 0.0,
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
      await _executeWithTimeout(
        () async {
          await _firestore.collection('payments').doc(paymentId).delete();
        },
        timeout: Duration(seconds: 15),
        operationName: 'Delete payment',
      );
      
      print('✅ Payment deleted successfully: $paymentId');
    } catch (e) {
      print('❌ Error deleting payment: $e');
      throw Exception('Gagal menghapus pembayaran: ${e.toString().split(':').last.trim()}');
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
        .handleError((error) {
          print('❌ Stream error: $error');
          // Return empty list on error
          return Stream.value([]);
        })
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return Payment.fromFirestore(doc.data(), doc.id);
              } catch (e) {
                print('❌ Error parsing payment document ${doc.id}: $e');
                return null;
              }
            })
            .where((payment) => payment != null)
            .cast<Payment>()
            .toList());
  }

  // ==============================
  // CHECK IF USER HAS PAID FOR EVENT
  // ==============================
  Future<bool> hasUserPaidForEvent(String eventId, String userId) async {
    try {
      final payment = await getPaymentByEventAndUser(eventId, userId);
      if (payment == null) {
        return false;
      }
      
      final hasPaid = payment.status == PaymentStatus.verified || 
                     payment.status == PaymentStatus.paid;
      
      print('💰 Payment status check: event=$eventId, user=$userId, hasPaid=$hasPaid');
      return hasPaid;
    } catch (e) {
      print('❌ Error checking payment status: $e');
      return false;
    }
  }

  // ==============================
  // CHECK FIREBASE CONNECTION
  // ==============================
  Future<bool> checkConnection() async {
    try {
      // Coba akses Firestore dengan timeout singkat
      await _firestore.collection('payments').limit(1).get().timeout(Duration(seconds: 5));
      print('✅ Firebase connection OK');
      return true;
    } catch (e) {
      print('❌ Firebase connection error: $e');
      return false;
    }
  }
}