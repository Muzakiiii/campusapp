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
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting all events: $e');
      throw Exception('Failed to get events: $e');
    }
  }

  // =============================
  // GET ALL EVENTS STREAM (REALTIME)
  // =============================
  Stream<List<EventModel>> getAllEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    });
  }

  // =============================
  // GET EVENT BY ID
  // =============================
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) return null;

      return EventModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }

  // =============================
  // CREATE EVENT (ADMIN)
  // =============================
  Future<EventModel> createEvent(EventModel event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Admin belum login');
      }

      final eventData = event.toFirestore();
      
      // Tambahkan admin-specific fields
      final now = DateTime.now();
      eventData.addAll({
        'createdBy': user.uid,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final docRef = await _firestore.collection('events').add(eventData);

      return event.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  // =============================
  // UPDATE EVENT
  // =============================
  Future<void> updateEvent(EventModel event) async {
    try {
      final eventData = event.toFirestore();
      
      // Update timestamp
      eventData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection('events')
          .doc(event.id)
          .update(eventData);
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  // =============================
  // DELETE EVENT
  // =============================
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  // =============================
  // GET BY KATEGORI
  // =============================
  Future<List<EventModel>> getEventsByKategori(String kategori) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('kategori', isEqualTo: kategori)
          .orderBy('tanggal', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting events by kategori: $e');
      throw Exception('Failed to get events by kategori: $e');
    }
  }

  // =============================
  // DASHBOARD STATS
  // =============================
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final eventsSnap = await _firestore.collection('events').get();

      final totalEvents = eventsSnap.docs.length;

      final activeEvents = eventsSnap.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'active' || data['status'] == 'pending';
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
            (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
          );

      return AdminDashboardStats(
        totalEvents: totalEvents,
        activeEvents: activeEvents,
        pendingPayments: pendingPayments,
        verifiedPayments: verifiedPayments,
        totalParticipants: totalParticipants,
        totalRevenue: totalRevenue,
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      // Return default stats jika error
      return AdminDashboardStats(
        totalEvents: 0,
        activeEvents: 0,
        pendingPayments: 0,
        verifiedPayments: 0,
        totalParticipants: 0,
        totalRevenue: 0,
      );
    }
  }
}