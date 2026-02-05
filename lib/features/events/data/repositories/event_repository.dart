import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =============================
  // ALL EVENTS (STREAM)
  // =============================
  Stream<List<EventModel>> getAllEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('tanggal', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    });
  }

  // =============================
  // ALL EVENTS (FUTURE)
  // =============================
  Future<List<EventModel>> getAllEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('tanggal', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting all events: $e');
      return [];
    }
  }

  // =============================
  // GET SINGLE EVENT BY ID
  // =============================
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }

  // =============================
  // EVENTS BY KATEGORI
  // =============================
  Future<List<EventModel>> getEventsByKategori(String kategori) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('kategori', isEqualTo: kategori)
          .orderBy('tanggal')
          .get();

      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting events by kategori: $e');
      return [];
    }
  }

  // =============================
  // UPCOMING EVENTS (BELUM LEWAT)
  // =============================
  Stream<List<EventModel>> getUpcomingEventsStream() {
    return _firestore
        .collection('events')
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('tanggal', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    });
  }

  // =============================
  // PAST EVENTS (SUDAH LEWAT)
  // =============================
  Stream<List<EventModel>> getPastEventsStream() {
    return _firestore
        .collection('events')
        .where('tanggal', isLessThan: Timestamp.now())
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    });
  }

  // =============================
  // CREATE NEW EVENT
  // =============================
  Future<String> createEvent(EventModel event) async {
    try {
      final docRef = await _firestore.collection('events').add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  // =============================
  // UPDATE EVENT
  // =============================
  Future<void> updateEvent(String eventId, EventModel event) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .update(event.toFirestore());
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
  // SEARCH EVENTS BY JUDUL OR KATEGORI
  // =============================
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      // Search in judul
      final judulSnapshot = await _firestore
          .collection('events')
          .where('judul', isGreaterThanOrEqualTo: query)
          .where('judul', isLessThan: query + 'z')
          .get();

      // Search in kategori
      final kategoriSnapshot = await _firestore
          .collection('events')
          .where('kategori', isGreaterThanOrEqualTo: query)
          .where('kategori', isLessThan: query + 'z')
          .get();

      final allDocs = [...judulSnapshot.docs, ...kategoriSnapshot.docs];
      
      // Remove duplicates
      final uniqueDocs = allDocs.fold<Map<String, DocumentSnapshot>>({}, (map, doc) {
        map[doc.id] = doc;
        return map;
      }).values.toList();

      return uniqueDocs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  // =============================
  // GET EVENTS BY STATUS
  // =============================
  Future<List<EventModel>> getEventsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: status)
          .orderBy('tanggal')
          .get();

      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting events by status: $e');
      return [];
    }
  }

  // =============================
  // INCREMENT REGISTRATION COUNT
  // =============================
  Future<void> incrementJumlahPendaftar(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'jumlahPendaftar': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing jumlah pendaftar: $e');
      throw Exception('Failed to update jumlah pendaftar');
    }
  }

  // =============================
  // CHECK IF EVENT IS FULL
  // =============================
  Future<bool> isEventFull(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final kuota = data?['kuota'] as int? ?? 0;
        final jumlahPendaftar = data?['jumlahPendaftar'] as int? ?? 0;
        
        return jumlahPendaftar >= kuota;
      }
      return false;
    } catch (e) {
      print('Error checking if event is full: $e');
      return false;
    }
  }

  // =============================
  // TOGGLE BOOKMARK
  // =============================
  Future<void> toggleBookmark(String eventId, bool currentValue) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'isBookmarked': !currentValue,
      });
    } catch (e) {
      print('Error toggling bookmark: $e');
      throw Exception('Failed to toggle bookmark');
    }
  }

  // =============================
  // BOOKMARKED EVENTS (STREAM)
  // =============================
  Stream<List<EventModel>> getBookmarkedEventsStream() {
    return _firestore
        .collection('events')
        .where('isBookmarked', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    });
  }

  // =============================
  // GET EVENTS WITH LIMIT (UNTUK HOMEPAGE)
  // =============================
  Future<List<EventModel>> getEventsWithLimit(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('tanggal', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting limited events: $e');
      return [];
    }
  }
}