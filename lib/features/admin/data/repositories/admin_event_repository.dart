import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusapp/features/events/domain/models/event_model.dart';
import 'package:campusapp/features/admin/domain/models/admin_dashboard_stats.dart';

class AdminEventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =============================
  // GET ALL EVENTS (ADMIN)
  // =============================
  Future<List<EventModel>> getAllEvents() async {
    final snapshot = await _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return EventModel.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // =============================
  // GET EVENT BY ID
  // =============================
  Future<EventModel?> getEventById(String eventId) async {
    final doc =
        await _firestore.collection('events').doc(eventId).get();

    if (!doc.exists) return null;

    return EventModel.fromFirestore(doc.data()!, doc.id);
  }

  // =============================
  // CREATE EVENT (ADMIN)
  // =============================
  Future<EventModel> createEvent(EventModel event) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Admin belum login');
    }

    final docRef = await _firestore.collection('events').add({
      ...event.toFirestore(),
      'createdBy': user.uid,
      'status': 'active', // untuk statistik
      'createdAt': FieldValue.serverTimestamp(),
    });

    return event.copyWith(id: docRef.id);
  }

  // =============================
  // UPDATE EVENT
  // =============================
  Future<void> updateEvent(EventModel event) async {
    await _firestore
        .collection('events')
        .doc(event.id)
        .update({
      ...event.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =============================
  // DELETE EVENT
  // =============================
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  // =============================
  // GET BY CATEGORY
  // =============================
  Future<List<EventModel>> getEventsBykategori(String kategori) async {
    final snapshot = await _firestore
        .collection('events')
        .where('kategori', isEqualTo: kategori)
        .get();

    return snapshot.docs.map((doc) {
      return EventModel.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // =============================
  // DASHBOARD STATS (REAL)
  // =============================
  Future<AdminDashboardStats> getDashboardStats() async {
    final eventsSnap = await _firestore.collection('events').get();

    final totalEvents = eventsSnap.docs.length;

    final activeEvents = eventsSnap.docs.where((doc) {
      return doc.data()['status'] == 'active';
    }).length;

    // Hitung peserta dari collection registrations
    final regSnap = await _firestore.collection('registrations').get();
    final totalParticipants = regSnap.docs.length;

    // Payments
    final paymentsSnap = await _firestore.collection('payments').get();

    final pendingPayments = paymentsSnap.docs
        .where((doc) => doc.data()['status'] == 'pending')
        .length;

    final verifiedPayments = paymentsSnap.docs
        .where((doc) => doc.data()['status'] == 'verified')
        .length;

    final totalRevenue = paymentsSnap.docs
        .where((doc) => doc.data()['status'] == 'verified')
        .fold<double>(
          0.0,
          (sum, doc) => sum + (doc.data()['amount'] ?? 0),
        );

    return AdminDashboardStats(
      totalEvents: totalEvents,
      activeEvents: activeEvents,
      pendingPayments: pendingPayments,
      verifiedPayments: verifiedPayments,
      totalParticipants: totalParticipants,
      totalRevenue: totalRevenue,
    );
  }
}
