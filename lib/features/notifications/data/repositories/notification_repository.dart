import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =============================
  // STREAM NOTIFIKASI USER
  // =============================
  Stream<List<NotificationModel>> getNotifikasiStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // =============================
  // JUMLAH BELUM DIBACA
  // =============================
  Stream<int> getJumlahBelumDibacaStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // =============================
  // TANDAI 1 NOTIFIKASI
  // =============================
  Future<void> tandaiSudahDibaca(String id) async {
    await _firestore.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }

  // =============================
  // TANDAI SEMUA
  // =============================
  Future<void> tandaiSemuaSudahDibaca(String userId) async {
    final query = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // =============================
  // HAPUS NOTIFIKASI
  // =============================
  Future<void> hapusNotifikasi(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }
}
