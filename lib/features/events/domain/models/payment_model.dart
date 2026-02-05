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
// BANK
// =============================
class Bank {
  final String name;
  final String number;
  final String holder;
  final String? logoUrl;

  Bank({
    required this.name,
    required this.number,
    required this.holder,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'number': number,
        'holder': holder,
        'logoUrl': logoUrl,
      };

  factory Bank.fromMap(Map<String, dynamic> map) => Bank(
        name: map['name'] ?? '',
        number: map['number'] ?? '',
        holder: map['holder'] ?? '',
        logoUrl: map['logoUrl'],
      );
}

// =============================
// EWALLET
// =============================
class EWallet {
  final String name;
  final String number;
  final String? logoUrl;

  EWallet({required this.name, required this.number, this.logoUrl});

  Map<String, dynamic> toMap() =>
      {'name': name, 'number': number, 'logoUrl': logoUrl};

  factory EWallet.fromMap(Map<String, dynamic> map) => EWallet(
        name: map['name'] ?? '',
        number: map['number'] ?? '',
        logoUrl: map['logoUrl'],
      );
}

// =============================
// PAYMENT METHOD DETAIL (UI)
// =============================
class PaymentMethodDetail {
  final PaymentMethod method;
  final String name;
  final String description;
  final IconData icon;
  final List<Bank>? banks;
  final List<EWallet>? wallets;
  final String? qrisCode;
  final Color? color;

  PaymentMethodDetail({
    required this.method,
    required this.name,
    required this.description,
    required this.icon,
    this.banks,
    this.wallets,
    this.qrisCode,
    this.color,
  });

  static IconData getIconFromMethod(PaymentMethod method) {
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

  static Color getColorFromMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.transferBank:
        return Colors.blue;
      case PaymentMethod.eWallet:
        return Colors.green;
      case PaymentMethod.qris:
        return Colors.purple;
      case PaymentMethod.virtualAccount:
        return Colors.orange;
      case PaymentMethod.creditCard:
        return Colors.red;
    }
  }
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
      virtualAccountNumber:
          virtualAccountNumber ?? this.virtualAccountNumber,
      qrisImageUrl: qrisImageUrl ?? this.qrisImageUrl,
      paymentCode: paymentCode ?? this.paymentCode,
    );
  }


  // =============================
  // FROM FIRESTORE (WAJIB)
  // =============================
  factory Payment.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return Payment(
      id: documentId,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      method: _methodFromString(data['method']),
      status: _statusFromString(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      paymentProofUrl: data['paymentProofUrl'],
      note: data['note'],
      virtualAccountNumber: data['virtualAccountNumber'],
      qrisImageUrl: data['qrisImageUrl'],
      paymentCode: data['paymentCode'],
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
      'method': method.name, // STRING
      'status': status.name, // STRING
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
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
    switch (value) {
      case 'eWallet':
        return PaymentMethod.eWallet;
      case 'qris':
        return PaymentMethod.qris;
      case 'virtualAccount':
        return PaymentMethod.virtualAccount;
      case 'creditCard':
        return PaymentMethod.creditCard;
      case 'transferBank':
      default:
        return PaymentMethod.transferBank;
    }
  }

  static PaymentStatus _statusFromString(String? value) {
    switch (value) {
      case 'paid':
        return PaymentStatus.paid;
      case 'verified':
        return PaymentStatus.verified;
      case 'rejected':
        return PaymentStatus.rejected;
      case 'expired':
        return PaymentStatus.expired;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  // =============================
  // UI HELPERS (TETAP ADA)
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

  IconData get methodIcon =>
      PaymentMethodDetail.getIconFromMethod(method);

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
