import 'dart:async';

import '../database/sqlite_database.dart';
import 'api_service.dart';
import 'auth_service.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncResult {
  final int pushed;
  final int pulled;
  final String? error;

  SyncResult({this.pushed = 0, this.pulled = 0, this.error});

  bool get ok => error == null;
}

class SyncService {
  SyncService._();

  static final _db = SQLiteDatabase();
  static final _statusController = StreamController<SyncStatus>.broadcast();
  static final _pendingController = StreamController<int>.broadcast();

  static Stream<SyncStatus> get onStatus => _statusController.stream;
  static Stream<int> get onPendingChange => _pendingController.stream;

  static bool _running = false;

  static Future<void> refreshPendingCount() async {
    final n = await _db.countPending();
    _pendingController.add(n);
  }

  static Future<SyncResult> syncAll() async {
    if (_running) return SyncResult();

    final activeUserId = _db.activeUserId;
    if (activeUserId == null) {
      return SyncResult(error: 'Not signed in');
    }

    _running = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final pushed = await _push();
      final pulled = await _pull(activeUserId);
      await _db.setMetadata('last_sync', _nowSql());
      _statusController.add(SyncStatus.success);
      await refreshPendingCount();
      return SyncResult(pushed: pushed, pulled: pulled);
    } catch (e) {
      final errorMsg = e.toString();
      _statusController.add(SyncStatus.error);
      await refreshPendingCount();
      return SyncResult(error: errorMsg);
    } finally {
      _running = false;
    }
  }

  static Future<int> _push() async {
    final pendingExpenses = await _db.getPendingRows('expenses');
    final pendingBudgets = await _db.getPendingRows('budgets');
    final pendingIncome = await _db.getPendingRows('income');

    if (pendingExpenses.isEmpty &&
        pendingBudgets.isEmpty &&
        pendingIncome.isEmpty) {
      return 0;
    }

    final payload = {
      'expenses': pendingExpenses.map(_mapExpense).toList(),
      'budgets': pendingBudgets.map(_mapBudget).toList(),
      'income': pendingIncome.map(_mapIncome).toList(),
    };

    final result = await ApiService.post('/api/sync/push', payload);
    if (!result.ok || result.body == null) {
      throw Exception(result.error ?? 'Push failed');
    }

    final data = result.body!['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Malformed push response');

    int count = 0;

    for (final table in ['expenses', 'budgets', 'income']) {
      final list = data[table];
      if (list is! List) continue;
      for (final item in list) {
        if (item is! Map) continue;
        final uuid = item['client_uuid'] as String?;
        final serverId = item['server_id'];
        if (uuid == null || serverId is! int) continue;
        await _db.markSynced(
          table: table,
          clientUuid: uuid,
          serverId: serverId,
        );
        count++;
      }
    }

    return count;
  }

  static Future<int> _pull(String activeUserId) async {
    final lastSync =
        await _db.getMetadata('last_sync') ?? '1970-01-01 00:00:00';

    final result = await ApiService.get(
      '/api/sync/pull?since=${Uri.encodeComponent(lastSync)}',
    );
    if (!result.ok || result.body == null) {
      throw Exception(result.error ?? 'Pull failed');
    }

    final data = result.body!['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Malformed pull response');

    final currentUser = await AuthService.getStoredUser();
    final userId = currentUser?.id.toString() ?? activeUserId;

    int count = 0;

    for (final table in ['expenses', 'budgets', 'income']) {
      final list = data[table];
      if (list is! List) continue;
      for (final item in list) {
        if (item is! Map) continue;
        await _db.upsertFromServer(
          table: table,
          serverRow: Map<String, dynamic>.from(item),
          userId: userId,
        );
        count++;
      }
    }

    final serverTime = data['server_time'] as String?;
    if (serverTime != null) {
      await _db.setMetadata('last_sync', serverTime);
    }

    return count;
  }

  static Map<String, dynamic> _mapExpense(Map<String, dynamic> row) {
    final serverId = row['server_id'];
    final deletedAt = row['deleted_at'];

    String operation;
    if (deletedAt != null) {
      operation = 'DELETE';
    } else if (serverId == null) {
      operation = 'INSERT';
    } else {
      operation = 'UPDATE';
    }

    return {
      'client_uuid': row['client_uuid'],
      'operation': operation,
      'amount': row['amount'],
      'category': row['category'],
      'description': row['description'],
      'merchant': row['merchant'],
      'payment_method': row['payment_method'],
      'expense_date': _sqlDate(row['expense_date']),
      'created_at': _sqlDate(row['created_at']),
      'updated_at': _sqlDate(row['updated_at']),
      'deleted_at': deletedAt == null ? null : _sqlDate(deletedAt),
    };
  }

  static Map<String, dynamic> _mapBudget(Map<String, dynamic> row) {
    final serverId = row['server_id'];
    final deletedAt = row['deleted_at'];

    String operation;
    if (deletedAt != null) {
      operation = 'DELETE';
    } else if (serverId == null) {
      operation = 'INSERT';
    } else {
      operation = 'UPDATE';
    }

    return {
      'client_uuid': row['client_uuid'],
      'operation': operation,
      'category': row['category'],
      'amount': row['amount'],
      'period': row['period'],
      'start_date': _sqlDate(row['start_date']),
      'end_date': _sqlDate(row['end_date']),
      'created_at': _sqlDate(row['created_at']),
      'updated_at': _sqlDate(row['updated_at']),
      'deleted_at': deletedAt == null ? null : _sqlDate(deletedAt),
    };
  }

  static Map<String, dynamic> _mapIncome(Map<String, dynamic> row) {
    final serverId = row['server_id'];
    final deletedAt = row['deleted_at'];

    String operation;
    if (deletedAt != null) {
      operation = 'DELETE';
    } else if (serverId == null) {
      operation = 'INSERT';
    } else {
      operation = 'UPDATE';
    }

    return {
      'client_uuid': row['client_uuid'],
      'operation': operation,
      'amount': row['amount'],
      'source': row['source'],
      'description': row['description'],
      'income_date': _sqlDate(row['income_date']),
      'created_at': _sqlDate(row['created_at']),
      'updated_at': _sqlDate(row['updated_at']),
      'deleted_at': deletedAt == null ? null : _sqlDate(deletedAt),
    };
  }

  static String _sqlDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return dt
          .toIso8601String()
          .split('.')
          .first
          .replaceFirst('T', ' ');
    } catch (_) {
      return iso;
    }
  }

  static String _nowSql() {
    return DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceFirst('T', ' ');
  }
}