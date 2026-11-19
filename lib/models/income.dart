class Income {
  final int? localId;
  final int? serverId;
  final String clientUuid;
  final String userId;
  final double amount;
  final String source;
  final String? description;
  final DateTime incomeDate;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Income({
    this.localId,
    this.serverId,
    required this.clientUuid,
    required this.userId,
    required this.amount,
    required this.source,
    this.description,
    required this.incomeDate,
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
      'amount': amount,
      'source': source,
      'description': description,
      'income_date': incomeDate.toIso8601String(),
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      localId: map['local_id'] as int?,
      serverId: map['server_id'] as int?,
      clientUuid: map['client_uuid'] as String,
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      source: map['source'] as String,
      description: map['description'] as String?,
      incomeDate: DateTime.parse(map['income_date'] as String),
      syncStatus: map['sync_status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
    );
  }
}