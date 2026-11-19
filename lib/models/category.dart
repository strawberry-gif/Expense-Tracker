class Category {
  final int? localId;
  final int? serverId;
  final String clientUuid;
  final String? userId;
  final String name;
  final String type; // 'expense' or 'income'
  final String? icon;
  final String? color;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Category({
    this.localId,
    this.serverId,
    required this.clientUuid,
    this.userId,
    required this.name,
    this.type = 'expense',
    this.icon,
    this.color,
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
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      localId: map['local_id'] as int?,
      serverId: map['server_id'] as int?,
      clientUuid: map['client_uuid'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'expense',
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
    );
  }
}
