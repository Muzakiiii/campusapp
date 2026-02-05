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
        .orderBy('tanggal')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // =============================
  // EVENTS BY CATEGORY (FIX ERROR)
  // =============================
  Future<List<EventModel>> getEventsBykategori(String kategori) async {
    final snapshot = await _firestore
        .collection('events')
        .where('kategori', isEqualTo: kategori)
        .orderBy('tanggal')
        .get();

    return snapshot.docs.map((doc) {
      return EventModel.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // =============================
  // TOGGLE BOOKMARK (SIMPLE GLOBAL)
  // =============================
  Future<void> toggleBookmark(String eventId, bool currentValue) async {
    await _firestore.collection('events').doc(eventId).update({
      'isBookmarked': !currentValue,
    });
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
        return EventModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
}
