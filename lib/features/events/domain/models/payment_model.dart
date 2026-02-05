// lib/features/events/domain/models/payment_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { transferBank, eWallet, qris, virtualAccount, creditCard }

enum PaymentStatus {
  pending,
  paid,
  verified,
  rejected,
  expired,
  cancelled,
}

// =============================
// PAYMENT MODEL (FIRESTORE)
// =============================
class Payment {
  final String id;
  final String eventId;
  final String userId;
  final String eventTitle;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? verifiedAt;
  final String? paymentProofUrl;
  final String? note;
  final String? virtualAccountNumber;
  final String? qrisImageUrl;
  final String? paymentCode;

  Payment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.eventTitle,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.verifiedAt,
    this.paymentProofUrl,
    this.note,
    this.virtualAccountNumber,
    this.qrisImageUrl,
    this.paymentCode,
  });

  Payment copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? eventTitle,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? verifiedAt,
    String? paymentProofUrl,
    String? note,
    String? virtualAccountNumber,
    String? qrisImageUrl,
    String? paymentCode,
  }) {
    return Payment(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      eventTitle: eventTitle ?? this.eventTitle,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      note: note ?? this.note,
      virtualAccountNumber: virtualAccountNumber ?? this.virtualAccountNumber,
      qrisImageUrl: qrisImageUrl ?? this.qrisImageUrl,
      paymentCode: paymentCode ?? this.paymentCode,
    );
  }

  // =============================
  // FROM FIRESTORE (FIXED VERSION)
  // =============================
  factory Payment.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    print('Parsing payment data: $data');
    
    // Helper untuk konversi safe
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int || value is double) return value.toString();
      return value.toString();
    }
    
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    DateTime? safeTimestampToDate(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return null;
    }

    return Payment(
      id: documentId,
      eventId: safeString(data['eventId']) ?? '',
      userId: safeString(data['userId']) ?? '',
      eventTitle: safeString(data['eventTitle']) ?? 'No Title',
      amount: safeDouble(data['amount']),
      method: _methodFromString(safeString(data['method'])),
      status: _statusFromString(safeString(data['status'])),
      createdAt: safeTimestampToDate(data['createdAt']) ?? DateTime.now(),
      paidAt: safeTimestampToDate(data['paidAt']),
      verifiedAt: safeTimestampToDate(data['verifiedAt']),
      paymentProofUrl: safeString(data['paymentProofUrl']),
      note: safeString(data['note']),
      virtualAccountNumber: safeString(data['virtualAccountNumber']),
      qrisImageUrl: safeString(data['qrisImageUrl']),
      paymentCode: safeString(data['paymentCode']),
    );
  }

  // =============================
  // TO FIRESTORE
  // =============================
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'eventTitle': eventTitle,
      'amount': amount,
      'method': method.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'paymentProofUrl': paymentProofUrl,
      'note': note,
      'virtualAccountNumber': virtualAccountNumber,
      'qrisImageUrl': qrisImageUrl,
      'paymentCode': paymentCode,
    };
  }

  // =============================
  // HELPERS (STRING <-> ENUM)
  // =============================
  static PaymentMethod _methodFromString(String? value) {
    final stringValue = value?.toLowerCase() ?? '';
    switch (stringValue) {
      case 'ewallet':
        return PaymentMethod.eWallet;
      case 'qris':
        return PaymentMethod.qris;
      case 'virtualaccount':
      case 'virtual_account':
        return PaymentMethod.virtualAccount;
      case 'creditcard':
      case 'credit_card':
        return PaymentMethod.creditCard;
      case 'transferbank':
      case 'transfer_bank':
      default:
        return PaymentMethod.transferBank;
    }
  }

  static PaymentStatus _statusFromString(String? value) {
    final stringValue = value?.toLowerCase() ?? 'pending';
    switch (stringValue) {
      case 'paid':
        return PaymentStatus.paid;
      case 'verified':
        return PaymentStatus.verified;
      case 'rejected':
        return PaymentStatus.rejected;
      case 'expired':
        return PaymentStatus.expired;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  // =============================
  // UI HELPERS
  // =============================
  String get methodName {
    switch (method) {
      case PaymentMethod.transferBank:
        return 'Transfer Bank';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.virtualAccount:
        return 'Virtual Account';
      case PaymentMethod.creditCard:
        return 'Kartu Kredit';
    }
  }

  IconData get methodIcon {
    switch (method) {
      case PaymentMethod.transferBank:
        return Icons.account_balance;
      case PaymentMethod.eWallet:
        return Icons.wallet;
      case PaymentMethod.qris:
        return Icons.qr_code;
      case PaymentMethod.virtualAccount:
        return Icons.credit_card;
      case PaymentMethod.creditCard:
        return Icons.credit_score;
    }
  }

  Color get statusColor {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.blue;
      case PaymentStatus.verified:
        return Colors.green;
      case PaymentStatus.rejected:
        return Colors.red;
      case PaymentStatus.expired:
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Menunggu Pembayaran';
      case PaymentStatus.paid:
        return 'Sudah Dibayar';
      case PaymentStatus.verified:
        return 'Terverifikasi';
      case PaymentStatus.rejected:
        return 'Ditolak';
      case PaymentStatus.expired:
        return 'Kedaluwarsa';
      case PaymentStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  bool get canUploadProof => status == PaymentStatus.pending;
  bool get canCancel => status == PaymentStatus.pending;
  bool get isCompleted => status == PaymentStatus.verified;
}