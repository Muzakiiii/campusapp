import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventModel {
  final String id;

  // === FIRESTORE ASLI ===
  final String judul;
  final String deskripsi;
  final String kategori;
  final String lokasi;
  final String posterUrl;

  final DateTime tanggal;        // untuk upcoming / past
  final DateTime batasDaftar;

  final String jamMulai;
  final String jamSelesai;

  final int kuota;
  final int jumlahPendaftar;
  final int skkm;

  final double hargaOnline;
  final double hargaOffline;

  final String linkOnline;
  final String status;

  // === TAMBAHAN FITUR (TETAP ADA) ===
  final bool isBookmarked;

  EventModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.lokasi,
    required this.posterUrl,
    required this.tanggal,
    required this.batasDaftar,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kuota,
    required this.jumlahPendaftar,
    required this.skkm,
    required this.hargaOnline,
    required this.hargaOffline,
    required this.linkOnline,
    required this.status,
    this.isBookmarked = false,
  });

  // ========================
  // UI HELPERS (TETAP ADA)
  // ========================
  Color get categoryColor {
    switch (kategori.toLowerCase()) {
      case 'seminar':
        return Colors.blue;
      case 'workshop':
        return Colors.green;
      case 'competition':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData get categoryIcon {
    switch (kategori.toLowerCase()) {
      case 'seminar':
        return Icons.school;
      case 'workshop':
        return Icons.build;
      case 'competition':
        return Icons.emoji_events;
      default:
        return Icons.event;
    }
  }

  String get dateText {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }

  bool get isGratis => hargaOnline == 0 && hargaOffline == 0;

  // ========================
  // FIRESTORE SERIALIZATION
  // ========================
  factory EventModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    final Timestamp? tanggalTs = map['tanggal'];
    final Timestamp? batasDaftarTs = map['batasDaftar'];

    return EventModel(
      id: docId,
      judul: map['judul'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      kategori: map['kategori'] ?? '',
      lokasi: map['lokasi'] ?? '',
      posterUrl: map['posterUrl'] ?? '',

      tanggal: tanggalTs != null ? tanggalTs.toDate() : DateTime.now(),
      batasDaftar:
          batasDaftarTs != null ? batasDaftarTs.toDate() : DateTime.now(),

      jamMulai: map['jamMulai'] ?? '',
      jamSelesai: map['jamSelesai'] ?? '',

      kuota: map['kuota'] ?? 0,
      jumlahPendaftar: map['jumlahPendaftar'] ?? 0,
      skkm: map['skkm'] ?? 0,

      hargaOnline: (map['hargaOnline'] as num?)?.toDouble() ?? 0,
      hargaOffline: (map['hargaOffline'] as num?)?.toDouble() ?? 0,

      linkOnline: map['linkOnline'] ?? '',
      status: map['status'] ?? '',

      isBookmarked: map['isBookmarked'] ?? false,
    );
  }

  // ========================
  // TO FIRESTORE (BARU - WAJIB)
  // ========================
  Map<String, dynamic> toFirestore() {
    return {
      'judul': judul,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'lokasi': lokasi,
      'posterUrl': posterUrl,
      'tanggal': Timestamp.fromDate(tanggal),
      'batasDaftar': Timestamp.fromDate(batasDaftar),
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'kuota': kuota,
      'jumlahPendaftar': jumlahPendaftar,
      'skkm': skkm,
      'hargaOnline': hargaOnline,
      'hargaOffline': hargaOffline,
      'linkOnline': linkOnline,
      'status': status,
      // ❌ JANGAN simpan id ke Firestore
      // ❌ isBookmarked biasanya LOCAL UI, tidak perlu disimpan
    };
  }

  // ========================
  // COPY WITH (DIPERLUAS)
  // ========================
  EventModel copyWith({
    String? id,
    String? judul,
    String? deskripsi,
    String? kategori,
    String? lokasi,
    String? posterUrl,
    DateTime? tanggal,
    DateTime? batasDaftar,
    String? jamMulai,
    String? jamSelesai,
    int? kuota,
    int? jumlahPendaftar,
    int? skkm,
    double? hargaOnline,
    double? hargaOffline,
    String? linkOnline,
    String? status,
    bool? isBookmarked,
  }) {
    return EventModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      kategori: kategori ?? this.kategori,
      lokasi: lokasi ?? this.lokasi,
      posterUrl: posterUrl ?? this.posterUrl,
      tanggal: tanggal ?? this.tanggal,
      batasDaftar: batasDaftar ?? this.batasDaftar,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      kuota: kuota ?? this.kuota,
      jumlahPendaftar: jumlahPendaftar ?? this.jumlahPendaftar,
      skkm: skkm ?? this.skkm,
      hargaOnline: hargaOnline ?? this.hargaOnline,
      hargaOffline: hargaOffline ?? this.hargaOffline,
      linkOnline: linkOnline ?? this.linkOnline,
      status: status ?? this.status,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
