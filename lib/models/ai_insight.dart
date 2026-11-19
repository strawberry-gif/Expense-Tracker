class AiInsight {
  final int? localId;
  final int? serverId;
  final String clientUuid;
  final String userId;

  /// 'warning' | 'info' | 'positive'
  final String type;

  /// Short headline.
  final String title;

  /// Main message.
  final String message;

  /// 0-2 short tips.
  final List<String> suggestions;

  final DateTime generatedAt;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  AiInsight({
    this.localId,
    this.serverId,
    required this.clientUuid,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.suggestions = const [],
    required this.generatedAt,
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
      'type': type,
      'insight_text': _encodeText(),
      'metadata_json': null,
      'generated_at': generatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  String _encodeText() {
    final s = suggestions.join(';;');
    return '$title||$message||$s';
  }

  static List<String> _decodeSuggestions(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw.split(';;').where((s) => s.isNotEmpty).toList();
  }

  factory AiInsight.fromMap(Map<String, dynamic> map) {
    final text = (map['insight_text'] as String?) ?? '';
    final parts = text.split('||');
    final title = parts.isNotEmpty ? parts[0] : 'Insight';
    final message = parts.length > 1 ? parts[1] : text;
    final suggestionsRaw = parts.length > 2 ? parts[2] : '';

    return AiInsight(
      localId: map['local_id'] as int?,
      serverId: map['server_id'] as int?,
      clientUuid: map['client_uuid'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: title,
      message: message,
      suggestions: _decodeSuggestions(suggestionsRaw),
      generatedAt: DateTime.parse(map['generated_at'] as String),
      syncStatus: map['sync_status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
    );
  }
}