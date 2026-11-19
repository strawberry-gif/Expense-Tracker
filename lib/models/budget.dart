class Budget {
  final int? localId;
  final int? serverId;
  final String clientUuid;
  final String userId;

  /// null = overall monthly budget. Otherwise a category name.
  final String? category;

  final double amount;

  /// 'monthly' for now.
  final String period;

  final DateTime startDate;
  final DateTime endDate;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Budget({
    this.localId,
    this.serverId,
    required this.clientUuid,
    required this.userId,
    this.category,
    required this.amount,
    this.period = 'monthly',
    required this.startDate,
    required this.endDate,
    this.syncStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'client_uuid': clientUuid,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      localId: map['local_id'] as int?,
      serverId: map['server_id'] as int?,
      clientUuid: map['client_uuid'] as String,
      userId: map['user_id'] as String,
      category: map['category'] as String?,
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      syncStatus: map['sync_status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
    );
  }

  String get displayName => category ?? 'Overall';
}