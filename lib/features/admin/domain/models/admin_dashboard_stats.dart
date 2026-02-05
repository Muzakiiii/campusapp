class AdminDashboardStats {
  final int totalEvents;
  final int activeEvents;
  final int pendingPayments;
  final int verifiedPayments;
  final int totalParticipants;
  final double totalRevenue;

  const AdminDashboardStats({
    required this.totalEvents,
    required this.activeEvents,
    required this.pendingPayments,
    required this.verifiedPayments,
    required this.totalParticipants,
    required this.totalRevenue,
  });

  // ========================
  // DEFAULT / INITIAL STATE
  // ========================
  factory AdminDashboardStats.initial() {
    return const AdminDashboardStats(
      totalEvents: 0,
      activeEvents: 0,
      pendingPayments: 0,
      verifiedPayments: 0,
      totalParticipants: 0,
      totalRevenue: 0.0,
    );
  }

  // ========================
  // COPY WITH (OPTIONAL, TAPI BAGUS UNTUK STATE MANAGEMENT)
  // ========================
  AdminDashboardStats copyWith({
    int? totalEvents,
    int? activeEvents,
    int? pendingPayments,
    int? verifiedPayments,
    int? totalParticipants,
    double? totalRevenue,
  }) {
    return AdminDashboardStats(
      totalEvents: totalEvents ?? this.totalEvents,
      activeEvents: activeEvents ?? this.activeEvents,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      verifiedPayments: verifiedPayments ?? this.verifiedPayments,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      totalRevenue: totalRevenue ?? this.totalRevenue,
    );
  }

  // ========================
  // SERIALIZATION
  // ========================
  Map<String, dynamic> toMap() {
    return {
      'totalEvents': totalEvents,
      'activeEvents': activeEvents,
      'pendingPayments': pendingPayments,
      'verifiedPayments': verifiedPayments,
      'totalParticipants': totalParticipants,
      'totalRevenue': totalRevenue,
    };
  }

  factory AdminDashboardStats.fromMap(Map<String, dynamic> map) {
    return AdminDashboardStats(
      totalEvents: (map['totalEvents'] as num?)?.toInt() ?? 0,
      activeEvents: (map['activeEvents'] as num?)?.toInt() ?? 0,
      pendingPayments: (map['pendingPayments'] as num?)?.toInt() ?? 0,
      verifiedPayments: (map['verifiedPayments'] as num?)?.toInt() ?? 0,
      totalParticipants: (map['totalParticipants'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
