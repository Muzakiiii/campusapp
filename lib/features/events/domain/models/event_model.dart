import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventModel {
  final String id;

  // === STRUKTUR FIREBASE ASLI ===
  final String judul;            // dari field "judul"
  final String deskripsi;        // dari field "deskripsi"
  final String kategori;         // dari field "kategori"
  final String lokasi;           // dari field "lokasi"
  final String posterUrl;        // dari field "posterUrl"
  final String linkOnline;       // dari field "linkOnline"

  final DateTime tanggal;        // dari field "tanggal"
  final DateTime batasDaftar;    // dari field "batasDaftar"

  final String jamMulai;         // dari field "jamMulai" (format: "09.00")
  final String jamSelesai;       // dari field "jamSelesai" (format: "12.00")

  final int kuota;               // dari field "kuota"
  final int jumlahPendaftar;     // dari field "jumlahPendaftar"
  final int skkm;                // dari field "skkm"

  final int hargaOnline;         // dari field "hargaOnline"
  final int hargaOffline;        // dari field "hargaOffline"

  final String status;           // dari field "status"

  final DateTime createdAt;      // dari field "createdAt"
  final DateTime updatedAt;      // dari field "updatedAt"

  // === TAMBAHAN UNTUK UI ===
  final bool isBookmarked;

  EventModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.lokasi,
    required this.posterUrl,
    required this.linkOnline,
    required this.tanggal,
    required this.batasDaftar,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kuota,
    required this.jumlahPendaftar,
    required this.skkm,
    required this.hargaOnline,
    required this.hargaOffline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isBookmarked = false,
  });

  // ========================
  // GETTER UNTUK KOMPATIBILITAS DENGAN KODE LAMA
  // ========================
  String get name => judul;
  String get description => deskripsi;
  String get category => kategori;
  String get location => lokasi;
  DateTime get date => tanggal;
  DateTime get deadline => batasDaftar;
  String get startTime => jamMulai;
  String get endTime => jamSelesai;
  int get quota => kuota;
  int get onlinePrice => hargaOnline;
  int get offlinePrice => hargaOffline;
  String get onlineLink => linkOnline;

  // ========================
  // UI HELPERS
  // ========================
  Color get categoryColor {
    switch (kategori.toLowerCase()) {
      case 'seminar':
        return Colors.blue;
      case 'workshop':
        return Colors.green;
      case 'kompetisi':
      case 'lomba':
        return Colors.orange;
      case 'pelatihan':
        return Colors.purple;
      case 'webinar':
        return Colors.red;
      case 'teknologi':
        return Colors.blue.shade700;
      case 'kesehatan':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData get categoryIcon {
    switch (kategori.toLowerCase()) {
      case 'seminar':
        return Icons.school;
      case 'workshop':
        return Icons.build;
      case 'kompetisi':
      case 'lomba':
        return Icons.emoji_events;
      case 'pelatihan':
        return Icons.people;
      case 'webinar':
        return Icons.video_call;
      case 'teknologi':
        return Icons.computer;
      case 'kesehatan':
        return Icons.health_and_safety;
      default:
        return Icons.event;
    }
  }

  String get dateText {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }

  bool get isGratis => hargaOnline == 0 && hargaOffline == 0;

  String get formattedTime {
    // Format: "09.00" tetap seperti itu, atau konversi jika perlu
    return jamMulai;
  }

  String get formattedEndTime {
    return jamSelesai;
  }

  // ========================
  // FIRESTORE SERIALIZATION
  // ========================
  factory EventModel.fromFirestore(
    DocumentSnapshot doc,
  ) {
    final map = doc.data() as Map<String, dynamic>;
    
    // Helper untuk parsing
    DateTime parseTimestamp(Timestamp? ts, DateTime fallback) {
      return ts != null ? ts.toDate() : fallback;
    }
    
    int parseInt(dynamic value) => (value as num?)?.toInt() ?? 0;
    String parseString(dynamic value) => value?.toString() ?? '';
    
    return EventModel(
      id: doc.id,
      judul: parseString(map['judul']),
      deskripsi: parseString(map['deskripsi']),
      kategori: parseString(map['kategori']),
      lokasi: parseString(map['lokasi']),
      posterUrl: parseString(map['posterUrl']),
      linkOnline: parseString(map['linkOnline']),
      tanggal: parseTimestamp(map['tanggal'] as Timestamp?, DateTime.now()),
      batasDaftar: parseTimestamp(map['batasDaftar'] as Timestamp?, DateTime.now()),
      jamMulai: parseString(map['jamMulai']),
      jamSelesai: parseString(map['jamSelesai']),
      kuota: parseInt(map['kuota']),
      jumlahPendaftar: parseInt(map['jumlahPendaftar']),
      skkm: parseInt(map['skkm']),
      hargaOnline: parseInt(map['hargaOnline']),
      hargaOffline: parseInt(map['hargaOffline']),
      status: parseString(map['status']),
      createdAt: parseTimestamp(map['createdAt'] as Timestamp?, DateTime.now()),
      updatedAt: parseTimestamp(map['updatedAt'] as Timestamp?, DateTime.now()),
      isBookmarked: map['isBookmarked'] == true,
    );
  }

  // ========================
  // TO FIRESTORE
  // ========================
  Map<String, dynamic> toFirestore() {
    return {
      'judul': judul,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'lokasi': lokasi,
      'posterUrl': posterUrl,
      'linkOnline': linkOnline,
      'tanggal': Timestamp.fromDate(tanggal),
      'batasDaftar': Timestamp.fromDate(batasDaftar),
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'kuota': kuota,
      'jumlahPendaftar': jumlahPendaftar,
      'skkm': skkm,
      'hargaOnline': hargaOnline,
      'hargaOffline': hargaOffline,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      // Jangan simpan id dan isBookmarked ke Firestore
    };
  }

  // ========================
  // COPY WITH
  // ========================
  EventModel copyWith({
    String? id,
    String? judul,
    String? deskripsi,
    String? kategori,
    String? lokasi,
    String? posterUrl,
    String? linkOnline,
    DateTime? tanggal,
    DateTime? batasDaftar,
    String? jamMulai,
    String? jamSelesai,
    int? kuota,
    int? jumlahPendaftar,
    int? skkm,
    int? hargaOnline,
    int? hargaOffline,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBookmarked,
  }) {
    return EventModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      kategori: kategori ?? this.kategori,
      lokasi: lokasi ?? this.lokasi,
      posterUrl: posterUrl ?? this.posterUrl,
      linkOnline: linkOnline ?? this.linkOnline,
      tanggal: tanggal ?? this.tanggal,
      batasDaftar: batasDaftar ?? this.batasDaftar,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      kuota: kuota ?? this.kuota,
      jumlahPendaftar: jumlahPendaftar ?? this.jumlahPendaftar,
      skkm: skkm ?? this.skkm,
      hargaOnline: hargaOnline ?? this.hargaOnline,
      hargaOffline: hargaOffline ?? this.hargaOffline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  // ========================
  // VALIDATION METHODS
  // ========================
  bool get isValid {
    return judul.isNotEmpty &&
        deskripsi.isNotEmpty &&
        kategori.isNotEmpty &&
        lokasi.isNotEmpty;
  }

  bool get isFull {
    return jumlahPendaftar >= kuota;
  }

  bool get canRegister {
    return !isFull && batasDaftar.isAfter(DateTime.now());
  }

  // ========================
  // FORMATTED PRICE STRING
  // ========================
  String get formattedOnlinePrice {
    if (hargaOnline == 0) return 'Gratis';
    return 'Rp $hargaOnline';
  }

  String get formattedOfflinePrice {
    if (hargaOffline == 0) return 'Gratis';
    return 'Rp $hargaOffline';
  }

  get tags => null;

  @override
  String toString() {
    return 'EventModel(id: $id, judul: $judul, kategori: $kategori, tanggal: $dateText)';
  }
}