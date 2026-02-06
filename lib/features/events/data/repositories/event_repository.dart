// lib/features/events/data/repositories/event_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =============================
  // CLOUDINARY CONFIG
  // =============================
  static const String _cloudinaryCloudName = 'dvf7f78gl'; // Cloud name Anda
  static const String _cloudinaryUploadPreset = 'ml_default';
  static const String _eventsFolder = 'campusapp/events';

  // =============================
  // UPLOAD GAMBAR KE CLOUDINARY
  // =============================
  Future<String> uploadEventImage({
    required Uint8List imageBytes,
    required String eventId,
    required String eventTitle,
  }) async {
    try {
      print('📤 Uploading event image to Cloudinary...');
      print('📁 Event ID: $eventId | Title: $eventTitle');
      
      // Validasi ukuran gambar (maks 5MB)
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw Exception('Ukuran gambar terlalu besar (maks 5MB)');
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeEventTitle = eventTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_')
          .toLowerCase()
          .substring(0, min(eventTitle.length, 20));
      
      final fileName = 'event_${eventId}_${safeEventTitle}_$timestamp.jpg';
      
      // Buat multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload'),
      );
      
      // Tambah fields
      request.fields['upload_preset'] = _cloudinaryUploadPreset;
      request.fields['folder'] = _eventsFolder;
      request.fields['public_id'] = fileName;
      
      // Tambah file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));
      
      print('🚀 Mengirim gambar ke Cloudinary...');
      
      // Kirim request
      final response = await request.send().timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Upload gambar event timeout');
        },
      );
      
      // Baca response
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final imageUrl = jsonResponse['secure_url'] ?? jsonResponse['url'];
        
        if (imageUrl == null) {
          throw Exception('URL gambar tidak ditemukan dalam response Cloudinary');
        }
        
        print('✅ Event image uploaded: ${imageUrl.substring(0, 50)}...');
        return imageUrl.toString();
      } else {
        final errorMessage = jsonResponse['error']?['message'] ?? 'Unknown error';
        print('❌ Cloudinary error: $errorMessage');
        throw Exception('Gagal upload gambar: $errorMessage');
      }
    } on TimeoutException catch (e) {
      print('⏰ Timeout uploading event image: $e');
      throw Exception('Upload gambar timeout. Pastikan koneksi internet stabil.');
    } on http.ClientException catch (e) {
      print('🌐 Network error: $e');
      throw Exception('Gagal terhubung ke server Cloudinary.');
    } catch (e) {
      print('❌ Error uploading event image: $e');
      rethrow;
    }
  }

  int min(int a, int b) => a < b ? a : b;

  // =============================
  // CREATE EVENT WITH IMAGE
  // =============================
  Future<String> createEventWithImage({
    required Map<String, dynamic> eventData,
    required Uint8List? imageBytes,
  }) async {
    try {
      print('🔄 Creating new event with image...');
      
      // 1. Upload gambar ke Cloudinary jika ada
      String? posterUrl;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        print('📸 Uploading event image to Cloudinary...');
        posterUrl = await uploadEventImage(
          imageBytes: imageBytes,
          eventId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          eventTitle: eventData['judul'] ?? 'Event',
        );
      }
      
      // 2. Siapkan data event
      final now = DateTime.now();
      final eventDoc = {
        'judul': eventData['judul'],
        'deskripsi': eventData['deskripsi'],
        'kategori': eventData['kategori'],
        'lokasi': eventData['lokasi'],
        'posterUrl': posterUrl ?? '', // Gunakan URL Cloudinary
        'linkOnline': eventData['linkOnline'] ?? '',
        'tanggal': Timestamp.fromDate(eventData['tanggal']),
        'batasDaftar': Timestamp.fromDate(eventData['batasDaftar']),
        'jamMulai': eventData['jamMulai'],
        'jamSelesai': eventData['jamSelesai'],
        'kuota': eventData['kuota'],
        'jumlahPendaftar': 0,
        'skkm': eventData['skkm'] ?? 0,
        'hargaOnline': eventData['hargaOnline'] ?? 0,
        'hargaOffline': eventData['hargaOffline'] ?? 0,
        'status': eventData['status'] ?? 'pending',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isBookmarked': false,
      };
      
      // 3. Simpan ke Firestore
      final docRef = await _firestore.collection('events').add(eventDoc);
      print('✅ Event created successfully: ${docRef.id}');
      
      // 4. Jika ada gambar, update dengan ID asli
      if (posterUrl != null && posterUrl!.isNotEmpty) {
        await uploadEventImage(
          imageBytes: imageBytes!,
          eventId: docRef.id,
          eventTitle: eventData['judul'],
        );
      }
      
      return docRef.id;
    } catch (e) {
      print('❌ Error creating event: $e');
      throw Exception('Gagal membuat event: $e');
    }
  }

  // =============================
  // UPDATE EVENT WITH IMAGE
  // =============================
  Future<void> updateEventWithImage({
    required String eventId,
    required Map<String, dynamic> updatedData,
    required Uint8List? newImageBytes,
    required bool removeImage,
  }) async {
    try {
      print('🔄 Updating event: $eventId');
      
      String? posterUrl;
      
      // Jika ada gambar baru, upload ke Cloudinary
      if (newImageBytes != null && newImageBytes.isNotEmpty) {
        print('📸 Uploading new event image...');
        
        // Ambil judul event untuk nama file
        final eventDoc = await _firestore.collection('events').doc(eventId).get();
        final eventTitle = eventDoc.data()?['judul'] ?? 'Event';
        
        posterUrl = await uploadEventImage(
          imageBytes: newImageBytes,
          eventId: eventId,
          eventTitle: eventTitle,
        );
        
        updatedData['posterUrl'] = posterUrl;
      }
      
      // Jika hapus gambar
      if (removeImage) {
        updatedData['posterUrl'] = '';
      }
      
      // Tambah updatedAt timestamp
      updatedData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update di Firestore
      await _firestore
          .collection('events')
          .doc(eventId)
          .update(updatedData);
      
      print('✅ Event updated successfully: $eventId');
    } catch (e) {
      print('❌ Error updating event: $e');
      throw Exception('Gagal update event: $e');
    }
  }

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
  // CREATE NEW EVENT (DEPRECATED - GUNAKAN createEventWithImage)
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
  // UPDATE EVENT (DEPRECATED - GUNAKAN updateEventWithImage)
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