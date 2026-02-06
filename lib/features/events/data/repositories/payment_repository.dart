// lib/features/events/data/repositories/payment_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// ==============================
// CLOUDINARY CONFIG
// ==============================
// Di bagian atas file payment_repository.dart
class CloudinaryConfig {
  // HANYA cloudName dan uploadPreset yang diperlukan
  static const String cloudName = 'dvf7f78gl';
  static const String uploadPreset = 'ml_default';
  static const String folder = 'campusapp/payment_proofs';
  
  // URL tanpa API key
  static String get uploadUrl => 
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}

// ==============================
// PAYMENT METHOD MODELS
// ==============================
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

// ==============================
// PAYMENT REPOSITORY (CLOUDINARY VERSION)
// ==============================
class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  // HELPER METHOD
  // ==============================
  Future<T> _executeWithTimeout<T>(
    Future<T> Function() operation, {
    required Duration timeout,
    required String operationName,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      print('⏰ Timeout during $operationName');
      throw TimeoutException('$operationName timeout');
    }
  }

  // ==============================
  // 1. BUAT PEMBAYARAN BARU
  // ==============================
  Future<Payment> createPayment({
    required EventModel event,
    required String userId,
    required PaymentMethod method,
  }) async {
    try {
      print('🔄 Membuat pembayaran untuk event: ${event.judul}');

      // Validasi input
      if (userId.isEmpty) throw Exception('User ID tidak valid');
      if (event.id.isEmpty) throw Exception('Event ID tidak valid');

      // Cek apakah user sudah memiliki pembayaran untuk event ini
      final existingPayment = await getPaymentByEventAndUser(event.id, userId);
      if (existingPayment != null) {
        print('⚠️ User sudah memiliki pembayaran untuk event ini');
        return existingPayment;
      }

      // Hitung total amount
      const double adminFee = 2000;
      final double eventPrice = event.hargaOnline > 0
          ? event.hargaOnline.toDouble()
          : event.hargaOffline.toDouble();
      final double totalAmount = eventPrice + adminFee;

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

      print('📝 Data pembayaran: $paymentId | Kode: $paymentCode | Jumlah: $totalAmount');

      // Simpan ke Firestore
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

      print('✅ Payment created successfully: $paymentId');
      return payment;
    } on TimeoutException catch (e) {
      print('⏰ Timeout creating payment: $e');
      throw Exception('Timeout: Gagal membuat pembayaran. Cek koneksi internet.');
    } on FirebaseException catch (e) {
      print('🔥 Firebase error: ${e.code} - ${e.message}');
      
      String errorMessage = 'Gagal membuat pembayaran';
      switch (e.code) {
        case 'permission-denied':
          errorMessage = 'Akses ditolak. Pastikan Anda sudah login.';
          break;
        case 'unavailable':
          errorMessage = 'Server tidak tersedia. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          errorMessage = 'Gagal koneksi ke server. Cek koneksi internet.';
          break;
      }
      throw Exception('$errorMessage (${e.code})');
    } catch (e) {
      print('❌ Error creating payment: $e');
      throw Exception('Gagal membuat pembayaran: ${e.toString().split(':').last.trim()}');
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
  // 2. UPLOAD GAMBAR KE CLOUDINARY
  // ==============================
  Future<String> _uploadImageToCloudinary(
    Uint8List imageBytes, 
    String paymentId,
    String userId,
  ) async {
    try {
      print('☁️ Mengupload gambar ke Cloudinary');
      print('📁 Payment ID: $paymentId | User ID: $userId');
      print('📦 Ukuran file: ${imageBytes.length} bytes');

      // Validasi ukuran file (maks 10MB)
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception('Ukuran gambar terlalu besar (maks 10MB)');
      }

      // Generate nama file yang unik
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'payment_${userId}_${paymentId}_$timestamp.jpg';

      // Buat multipart request ke Cloudinary
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.uploadUrl),
      );

      // Tambah fields yang diperlukan
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = CloudinaryConfig.folder;
      request.fields['public_id'] = fileName;

      // Tambah file image
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));

      print('🚀 Mengirim request ke Cloudinary...');

      // Kirim request dengan timeout lebih lama (60 detik)
      final response = await request.send().timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Upload gambar timeout setelah 60 detik');
        },
      );

      // Baca response
      final responseString = await response.stream.bytesToString();
      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseString);
        final imageUrl = responseData['secure_url'] ?? responseData['url'];
        
        if (imageUrl == null) {
          throw Exception('URL gambar tidak ditemukan dalam response Cloudinary');
        }

        print('✅ Upload berhasil: ${imageUrl.substring(0, 50)}...');
        return imageUrl.toString();
      } else {
        final errorData = jsonDecode(responseString);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('Cloudinary error: $errorMessage');
      }
    } on TimeoutException catch (e) {
      print('⏰ Timeout uploading to Cloudinary: $e');
      throw Exception('Upload gambar timeout. Pastikan koneksi internet stabil.');
    } on http.ClientException catch (e) {
      print('🌐 Network error: $e');
      throw Exception('Gagal terhubung ke server Cloudinary. Cek koneksi internet.');
    } catch (e) {
      print('❌ Error uploading to Cloudinary: $e');
      throw Exception('Gagal mengupload gambar: ${e.toString().split(':').last.trim()}');
    }
  }

  // ==============================
  // 3. UPLOAD BUKTI PEMBAYARAN (UTAMA)
  // ==============================
Future<Payment> uploadPaymentProof({
  required String paymentId,
  required String userId,
  required Uint8List imageBytes,
  String? note,
}) async {
  try {
    print('=== 🐛 DEBUGGING PERMISSION START ===');
    
    // 1. Cek auth state
    print('👤 User ID from parameter: $userId');
    
    // 2. Cek apakah payment document ada dan bisa dibaca
    print('🔍 Checking payment document: $paymentId');
    final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
    
    if (!paymentDoc.exists) {
      print('❌ Payment document tidak ditemukan!');
      throw Exception('Payment tidak ditemukan');
    }
    
    print('✅ Document ditemukan');
    print('📄 Document data: ${paymentDoc.data()}');
    
    // 3. Cek apakah user adalah pemilik
    final paymentUserId = paymentDoc.data()?['userId'];
    print('🔐 Payment user ID: $paymentUserId');
    print('🔐 Request user ID: $userId');
    
    if (paymentUserId != userId) {
      print('❌ PERMISSION DENIED: User bukan pemilik payment!');
      throw Exception('Anda tidak memiliki izin untuk mengupdate payment ini');
    }
    
    // 4. Cek status saat ini
    final currentStatus = paymentDoc.data()?['status'];
    print('📊 Current status: $currentStatus');
    
    if (currentStatus != 'pending') {
      print('❌ Status tidak valid untuk upload. Harus "pending", tapi sekarang "$currentStatus"');
      throw Exception('Payment sudah tidak dalam status pending');
    }
    
    print('=== ✅ SEMUA CHECK PASSED ===');
    
    // Lanjutkan dengan upload Cloudinary...
    print('☁️ Mulai upload ke Cloudinary...');
    final imageUrl = await _uploadImageToCloudinary(imageBytes, paymentId, userId);
    
    print('✅ Cloudinary upload berhasil: $imageUrl');
    
    // 5. Data yang akan diupdate
    final updatedData = {
      'paymentProofUrl': imageUrl,
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    
    print('📝 Data update yang akan dikirim:');
    updatedData.forEach((key, value) {
      print('   $key: $value');
    });
    
    // 6. Coba update dengan timeout
    print('🔄 Mengupdate Firestore...');
    try {
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updatedData);
      print('✅ Firestore update berhasil!');
    } on FirebaseException catch (e) {
      print('❌ FirebaseException: ${e.code} - ${e.message}');
      print('❌ Full error: $e');
      rethrow;
    }
    
    // 7. Verifikasi update
    final updatedDoc = await _firestore.collection('payments').doc(paymentId).get();
    print('✅ Verifikasi berhasil. Status baru: ${updatedDoc.data()?['status']}');
    
    return Payment.fromFirestore(updatedDoc.data()!, updatedDoc.id);
    
  } catch (e) {
    print('❌ ERROR DETAIL: $e');
    print('❌ Stack trace: ${e.toString()}');
    rethrow;
  }
}

  // ==============================
  // 4. GET PAYMENT BY ID
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
  // 5. GET USER PAYMENTS
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
  // 6. GET PAYMENT BY EVENT AND USER
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
  // 7. GET PAYMENT METHODS (UI)
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
  // 8. VERIFIKASI PEMBAYARAN (ADMIN)
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
  // 9. CANCEL PAYMENT
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
  // 10. PAYMENT STATISTICS
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
  // 11. DELETE PAYMENT
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
  // 12. STREAM PAYMENTS FOR REAL-TIME UPDATES
  // ==============================
  Stream<List<Payment>> streamUserPayments(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          print('❌ Stream error: $error');
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
  // 13. CHECK IF USER HAS PAID FOR EVENT
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
  // 14. CHECK FIREBASE CONNECTION
  // ==============================
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('payments').limit(1).get().timeout(Duration(seconds: 5));
      print('✅ Firebase connection OK');
      return true;
    } catch (e) {
      print('❌ Firebase connection error: $e');
      return false;
    }
  }
  
  // ==============================
  // 15. CHECK CLOUDINARY CONNECTION
  // ==============================
  Future<bool> checkCloudinaryConnection() async {
    try {
      // Coba ping Cloudinary API
      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/ping')
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Cloudinary connection error: $e');
      return false;
    }
  }
}