import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusapp/features/events/domain/models/payment_model.dart';

class AdminPaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =============================
  // GET ALL PAYMENTS
  // =============================
  Future<List<Payment>> getAllPayments() async {
    final snap = await _firestore
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((doc) {
      return Payment.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // =============================
  // GET BY STATUS
  // =============================
  Future<List<Payment>> getPaymentsByStatus(PaymentStatus status) async {
    final snap = await _firestore
        .collection('payments')
        .where('status', isEqualTo: status.name)
        .get();

    return snap.docs.map((doc) {
      return Payment.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // =============================
  // GET PAYMENT BY ID
  // =============================
  Future<Payment?> getPaymentById(String paymentId) async {
    final doc =
        await _firestore.collection('payments').doc(paymentId).get();

    if (!doc.exists) return null;

    return Payment.fromFirestore(doc.data()!, doc.id);
  }

  // =============================
  // VERIFY PAYMENT (ADMIN)
  // =============================
  Future<void> verifyPayment(String paymentId, {String? note}) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
      if (note != null) 'note': note,
    });
  }

  // =============================
  // REJECT PAYMENT (ADMIN)
  // =============================
  Future<void> rejectPayment(
    String paymentId, {
    required String reason,
  }) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': 'rejected',
      'note': 'Ditolak: $reason',
    });
  }

  // =============================
  // PAYMENT STATISTICS (REAL)
  // =============================
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    final snap = await _firestore.collection('payments').get();

    final totalPayments = snap.docs.length;

    final pendingCount = snap.docs
        .where((d) => d.data()['status'] == 'pending')
        .length;

    final verifiedCount = snap.docs
        .where((d) => d.data()['status'] == 'verified')
        .length;

    final rejectedCount = snap.docs
        .where((d) => d.data()['status'] == 'rejected')
        .length;

    final totalRevenue = snap.docs
        .where((d) => d.data()['status'] == 'verified')
        .fold<double>(
          0.0,
          (sum, d) => sum + (d.data()['amount'] ?? 0),
        );

    return {
      'totalPayments': totalPayments,
      'pendingCount': pendingCount,
      'verifiedCount': verifiedCount,
      'rejectedCount': rejectedCount,
      'totalRevenue': totalRevenue,
    };
  }

  // =============================
  // SEARCH PAYMENTS (FIRESTORE SIMPLE)
  // =============================
  Future<List<Payment>> searchPayments(String query) async {
    if (query.isEmpty) return getAllPayments();

    final snap = await _firestore
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs
        .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
        .where((payment) =>
            payment.eventTitle.toLowerCase().contains(query.toLowerCase()) ||
            payment.userId.toLowerCase().contains(query.toLowerCase()) ||
            (payment.note ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
  }

  // =============================
  // PAYMENTS FOR EVENT
  // =============================
  Future<List<Payment>> getPaymentsForEvent(String eventId) async {
    final snap = await _firestore
        .collection('payments')
        .where('eventId', isEqualTo: eventId)
        .get();

    return snap.docs.map((doc) {
      return Payment.fromFirestore(doc.data(), doc.id);
    }).toList();
  }
}
