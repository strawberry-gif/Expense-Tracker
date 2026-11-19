import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ai_insight.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';

class SQLiteDatabase {
  static final SQLiteDatabase _instance = SQLiteDatabase._internal();
  factory SQLiteDatabase() => _instance;
  SQLiteDatabase._internal();

  static const String _dbName = 'expense_tracker.db';
  static const int _dbVersion = 2;
  static const String _legacyClaimKey = 'local_user_claimed_by';
  static const String _legacyUserId = 'local_user';

  Future<Database>? _dbFuture;
  String? _activeUserId;

  String? get activeUserId => _activeUserId;

  void setActiveUser(String? userId) {
    _activeUserId = userId;
  }

  void clearActiveUser() {
    _activeUserId = null;
  }

  Future<Database> get database {
    final cached = _dbFuture;
    if (cached != null) return cached;
    final future = _openDatabase();
    _dbFuture = future;
    future.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_dbFuture, future)) _dbFuture = null;
      },
    );
    return future;
  }

  Future<Database> _openDatabase() async {
    if (kIsWeb) {
      return openDatabase(
        _dbName,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    }

    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, _dbName);

    return openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        local_id       INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id      INTEGER,
        client_uuid    TEXT NOT NULL UNIQUE,
        user_id        TEXT NOT NULL,
        amount         REAL NOT NULL,
        category       TEXT NOT NULL,
        description    TEXT NOT NULL,
        merchant       TEXT,
        payment_method TEXT,
        expense_date   TEXT NOT NULL,
        sync_status    TEXT NOT NULL DEFAULT 'pending',
        created_at     TEXT NOT NULL,
        updated_at     TEXT NOT NULL,
        deleted_at     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        local_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id    INTEGER,
        client_uuid  TEXT NOT NULL UNIQUE,
        user_id      TEXT NOT NULL,
        category     TEXT,
        amount       REAL NOT NULL,
        period       TEXT NOT NULL,
        start_date   TEXT NOT NULL,
        end_date     TEXT NOT NULL,
        sync_status  TEXT NOT NULL DEFAULT 'pending',
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        deleted_at   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE income (
        local_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id    INTEGER,
        client_uuid  TEXT NOT NULL UNIQUE,
        user_id      TEXT NOT NULL,
        amount       REAL NOT NULL,
        source       TEXT NOT NULL,
        description  TEXT,
        income_date  TEXT NOT NULL,
        sync_status  TEXT NOT NULL DEFAULT 'pending',
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        deleted_at   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        local_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id    INTEGER,
        client_uuid  TEXT NOT NULL UNIQUE,
        user_id      TEXT,
        name         TEXT NOT NULL,
        type         TEXT NOT NULL DEFAULT 'expense',
        icon         TEXT,
        color        TEXT,
        sync_status  TEXT NOT NULL DEFAULT 'pending',
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL,
        deleted_at   TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_insights (
        local_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id     INTEGER,
        client_uuid   TEXT NOT NULL UNIQUE,
        user_id       TEXT NOT NULL,
        type          TEXT NOT NULL,
        insight_text  TEXT NOT NULL,
        metadata_json TEXT,
        generated_at  TEXT NOT NULL,
        sync_status   TEXT NOT NULL DEFAULT 'pending',
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL,
        deleted_at    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id         TEXT NOT NULL,
        table_name      TEXT NOT NULL,
        record_local_id INTEGER NOT NULL,
        operation       TEXT NOT NULL,
        payload_json    TEXT NOT NULL,
        retry_count     INTEGER NOT NULL DEFAULT 0,
        last_error      TEXT,
        next_retry_at   TEXT,
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_metadata (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createIndexes(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_user_date '
      'ON expenses(user_id, expense_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_user_sync '
      'ON expenses(user_id, sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budgets_user_sync '
      'ON budgets(user_id, sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_income_user_date '
      'ON income(user_id, income_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_income_user_sync '
      'ON income(user_id, sync_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_user '
      'ON categories(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_insights_user_gen '
      'ON ai_insights(user_id, generated_at)',
    );
  }

  Future<void> claimLocalUserData(String userId) async {
    final db = await database;
    final existing = await getMetadata(_legacyClaimKey);
    if (existing != null) return;

    await db.transaction((txn) async {
      for (final table in const [
        'expenses',
        'budgets',
        'income',
        'categories',
        'ai_insights',
      ]) {
        await txn.update(
          table,
          {'user_id': userId},
          where: 'user_id = ? OR user_id IS NULL',
          whereArgs: [_legacyUserId],
        );
      }
      await txn.insert(
        'app_metadata',
        {'key': _legacyClaimKey, 'value': userId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final map = Map<String, dynamic>.from(expense.toMap());
    map['user_id'] = _activeUserId ?? _legacyUserId;
    return db.insert('expenses', map);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'expenses',
      where: uid == null
          ? 'deleted_at IS NULL'
          : 'deleted_at IS NULL AND user_id = ?',
      whereArgs: uid == null ? null : [uid],
      orderBy: 'expense_date DESC',
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<Expense?> getExpenseById(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'expenses',
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'expenses',
      {
        'amount': expense.amount,
        'category': expense.category,
        'description': expense.description,
        'merchant': expense.merchant,
        'payment_method': expense.paymentMethod,
        'expense_date': expense.expenseDate.toIso8601String(),
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [expense.localId] : [expense.localId, uid],
    );
  }

  Future<int> softDeleteExpense(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'expenses',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending',
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
    );
  }

  Future<List<Expense>> searchExpenses({
    String query = '',
    String? category,
    String sortBy = 'date_desc',
  }) async {
    final db = await database;

    final whereParts = <String>['deleted_at IS NULL'];
    final whereArgs = <dynamic>[];

    final uid = _activeUserId;
    if (uid != null) {
      whereParts.add('user_id = ?');
      whereArgs.add(uid);
    }

    if (query.trim().isNotEmpty) {
      whereParts.add(
        "(description LIKE ? ESCAPE '\\' OR category LIKE ? ESCAPE '\\' "
        "OR IFNULL(merchant, '') LIKE ? ESCAPE '\\')",
      );
      final raw = query
          .trim()
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      final like = '%$raw%';
      whereArgs.add(like);
      whereArgs.add(like);
      whereArgs.add(like);
    }

    if (category != null && category != 'All') {
      whereParts.add('category = ?');
      whereArgs.add(category);
    }

    String orderBy;
    switch (sortBy) {
      case 'date_asc':
        orderBy = 'expense_date ASC';
        break;
      case 'amount_desc':
        orderBy = 'amount DESC';
        break;
      case 'amount_asc':
        orderBy = 'amount ASC';
        break;
      case 'date_desc':
      default:
        orderBy = 'expense_date DESC';
    }

    final rows = await db.query(
      'expenses',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<int> deleteAllExpenses() async {
    final uid = _activeUserId;
    if (uid == null) return 0;
    final db = await database;
    return db.delete(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [uid],
    );
  }

  String _userClause(String base) {
    return _activeUserId == null ? base : '$base AND user_id = ?';
  }

  List<Object?>? _userArgs(List<Object?>? args) {
    final uid = _activeUserId;
    if (uid == null) return args;
    return [...?args, uid];
  }

  Future<double> getTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery(
      _userClause(
        'SELECT SUM(amount) AS total FROM expenses WHERE deleted_at IS NULL',
      ),
      _userArgs(null),
    );
    return _toDouble(result.first['total']);
  }

  Future<double> getSpendingBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      _userClause(
        'SELECT SUM(amount) AS total FROM expenses '
        'WHERE deleted_at IS NULL AND expense_date >= ? AND expense_date < ?',
      ),
      _userArgs([start.toIso8601String(), end.toIso8601String()]),
    );
    return _toDouble(result.first['total']);
  }

  Future<double> getSpendingToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getSpendingBetween(start, end);
  }

  Future<double> getSpendingThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return getSpendingBetween(start, end);
  }

  Future<double> getSpendingForCategoryThisMonth(String category) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final db = await database;
    final result = await db.rawQuery(
      _userClause(
        'SELECT SUM(amount) AS total FROM expenses '
        'WHERE deleted_at IS NULL AND category = ? '
        'AND expense_date >= ? AND expense_date < ?',
      ),
      _userArgs([
        category,
        start.toIso8601String(),
        end.toIso8601String(),
      ]),
    );
    return _toDouble(result.first['total']);
  }

  Future<MapEntry<String, double>?> getTopCategoryThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final rows = await db.rawQuery(
      _userClause(
        'SELECT category, SUM(amount) AS total FROM expenses '
        'WHERE deleted_at IS NULL AND expense_date >= ? AND expense_date < ? '
        'GROUP BY category ORDER BY total DESC LIMIT 1',
      ),
      _userArgs([start.toIso8601String(), end.toIso8601String()]),
    );

    if (rows.isEmpty) return null;
    return MapEntry(
      rows.first['category'] as String,
      _toDouble(rows.first['total']),
    );
  }

  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'expenses',
      where: uid == null
          ? 'deleted_at IS NULL'
          : 'deleted_at IS NULL AND user_id = ?',
      whereArgs: uid == null ? null : [uid],
      orderBy: 'expense_date DESC',
      limit: limit,
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<Map<DateTime, double>> getDailyTotals({int days = 7}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));

    final db = await database;
    final rows = await db.rawQuery(
      _userClause(
        'SELECT expense_date, amount FROM expenses '
        'WHERE deleted_at IS NULL AND expense_date >= ? AND expense_date < ?',
      ),
      _userArgs([start.toIso8601String(), end.toIso8601String()]),
    );

    final totals = <DateTime, double>{};
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      totals[DateTime(d.year, d.month, d.day)] = 0;
    }

    for (final row in rows) {
      final d = DateTime.parse(row['expense_date'] as String);
      final key = DateTime(d.year, d.month, d.day);
      totals[key] = (totals[key] ?? 0) + _toDouble(row['amount']);
    }

    return totals;
  }

  Future<Map<String, double>> getCategoryTotalsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      _userClause(
        'SELECT category, SUM(amount) AS total FROM expenses '
        'WHERE deleted_at IS NULL AND expense_date >= ? AND expense_date < ? '
        'GROUP BY category ORDER BY total DESC',
      ),
      _userArgs([start.toIso8601String(), end.toIso8601String()]),
    );
    final map = <String, double>{};
    for (final row in rows) {
      map[row['category'] as String] = _toDouble(row['total']);
    }
    return map;
  }

  Future<Map<int, double>> getMonthlyTotalsForYear(int year) async {
    final db = await database;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    final rows = await db.rawQuery(
      _userClause(
        'SELECT expense_date, amount FROM expenses '
        'WHERE deleted_at IS NULL AND expense_date >= ? AND expense_date < ?',
      ),
      _userArgs([start.toIso8601String(), end.toIso8601String()]),
    );

    final totals = <int, double>{};
    for (int m = 1; m <= 12; m++) {
      totals[m] = 0;
    }
    for (final row in rows) {
      final d = DateTime.parse(row['expense_date'] as String);
      totals[d.month] = (totals[d.month] ?? 0) + _toDouble(row['amount']);
    }
    return totals;
  }

  Future<List<MapEntry<DateTime, double>>> getLastNMonthTotals({
    int monthsBack = 6,
  }) async {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, double>>[];

    for (int i = monthsBack - 1; i >= 0; i--) {
      final anchor = DateTime(now.year, now.month - i, 1);
      final start = DateTime(anchor.year, anchor.month, 1);
      final end = DateTime(anchor.year, anchor.month + 1, 1);
      final total = await getSpendingBetween(start, end);
      result.add(MapEntry(start, total));
    }
    return result;
  }

  Future<int> getExpenseCountBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      _userClause(
        'SELECT COUNT(*) AS c FROM expenses '
        'WHERE deleted_at IS NULL AND expense_date >= ? AND expense_date < ?',
      ),
      _userArgs([start.toIso8601String(), end.toIso8601String()]),
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    final map = Map<String, dynamic>.from(budget.toMap());
    map['user_id'] = _activeUserId ?? _legacyUserId;
    return db.insert('budgets', map);
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'budgets',
      {
        'category': budget.category,
        'amount': budget.amount,
        'period': budget.period,
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [budget.localId] : [budget.localId, uid],
    );
  }

  Future<int> softDeleteBudget(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'budgets',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending',
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
    );
  }

  Future<Budget?> getBudgetById(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'budgets',
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<Budget?> findBudgetByCategory(String? category) async {
    final db = await database;
    final uid = _activeUserId;
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (category == null) {
      conditions.add('category IS NULL');
    } else {
      conditions.add('category = ?');
      args.add(category);
    }

    if (uid != null) {
      conditions.add('user_id = ?');
      args.add(uid);
    }

    final rows = await db.query(
      'budgets',
      where: conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'budgets',
      where: uid == null
          ? 'deleted_at IS NULL'
          : 'deleted_at IS NULL AND user_id = ?',
      whereArgs: uid == null ? null : [uid],
    );
    final list = rows.map((row) => Budget.fromMap(row)).toList();
    list.sort((a, b) {
      if (a.category == null && b.category != null) return -1;
      if (a.category != null && b.category == null) return 1;
      return (a.category ?? '').compareTo(b.category ?? '');
    });
    return list;
  }

  Future<double> getTotalBudgetAmount() async {
    final db = await database;
    final result = await db.rawQuery(
      _userClause(
        'SELECT SUM(amount) AS total FROM budgets WHERE deleted_at IS NULL',
      ),
      _userArgs(null),
    );
    return _toDouble(result.first['total']);
  }

  Future<int> insertIncome(Income income) async {
    final db = await database;
    final map = Map<String, dynamic>.from(income.toMap());
    map['user_id'] = _activeUserId ?? _legacyUserId;
    return db.insert('income', map);
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'income',
      {
        'amount': income.amount,
        'source': income.source,
        'description': income.description,
        'income_date': income.incomeDate.toIso8601String(),
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [income.localId] : [income.localId, uid],
    );
  }

  Future<int> softDeleteIncome(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'income',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending',
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
    );
  }

  Future<Income?> getIncomeById(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'income',
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Income.fromMap(rows.first);
  }

  Future<List<Income>> getAllIncome() async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'income',
      where: uid == null
          ? 'deleted_at IS NULL'
          : 'deleted_at IS NULL AND user_id = ?',
      whereArgs: uid == null ? null : [uid],
      orderBy: 'income_date DESC',
    );
    return rows.map((row) => Income.fromMap(row)).toList();
  }

  Future<double> getIncomeThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final db = await database;
    final result = await db.rawQuery(
      _userClause(
        'SELECT SUM(amount) AS total FROM income '
        'WHERE deleted_at IS NULL AND income_date >= ? AND income_date < ?',
      ),
      _userArgs([start.toIso8601String(), end.toIso8601String()]),
    );
    return _toDouble(result.first['total']);
  }

  Future<int> insertAiInsight(AiInsight insight) async {
    final db = await database;
    final map = Map<String, dynamic>.from(insight.toMap());
    map['user_id'] = _activeUserId ?? _legacyUserId;
    return db.insert(
      'ai_insights',
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<AiInsight?> getLatestAiInsight() async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'ai_insights',
      where: uid == null
          ? 'deleted_at IS NULL'
          : 'deleted_at IS NULL AND user_id = ?',
      whereArgs: uid == null ? null : [uid],
      orderBy: 'generated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AiInsight.fromMap(rows.first);
  }

  Future<List<AiInsight>> getRecentAiInsights({int limit = 10}) async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'ai_insights',
      where: uid == null
          ? 'deleted_at IS NULL'
          : 'deleted_at IS NULL AND user_id = ?',
      whereArgs: uid == null ? null : [uid],
      orderBy: 'generated_at DESC',
      limit: limit,
    );
    return rows.map((row) => AiInsight.fromMap(row)).toList();
  }

  Future<void> pruneAiInsights({int keep = 20}) async {
    final db = await database;
    final uid = _activeUserId;
    if (uid == null) {
      await db.rawDelete(
        'DELETE FROM ai_insights WHERE local_id NOT IN ('
        'SELECT local_id FROM ai_insights '
        'ORDER BY generated_at DESC LIMIT ?'
        ')',
        [keep],
      );
    } else {
      await db.rawDelete(
        'DELETE FROM ai_insights WHERE user_id = ? AND local_id NOT IN ('
        'SELECT local_id FROM ai_insights WHERE user_id = ? '
        'ORDER BY generated_at DESC LIMIT ?'
        ')',
        [uid, uid, keep],
      );
    }
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    final map = Map<String, dynamic>.from(category.toMap());
    if (map['user_id'] == null) {
      map['user_id'] = _activeUserId ?? _legacyUserId;
    }
    return db.insert('categories', map);
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'categories',
      {
        'name': category.name,
        'type': category.type,
        'icon': category.icon,
        'color': category.color,
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [category.localId] : [category.localId, uid],
    );
  }

  Future<int> softDeleteCategory(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'categories',
      {
        'deleted_at': now,
        'updated_at': now,
        'sync_status': 'pending',
      },
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
    );
  }

  Future<Category?> getCategoryById(int localId) async {
    final db = await database;
    final uid = _activeUserId;
    final rows = await db.query(
      'categories',
      where: uid == null ? 'local_id = ?' : 'local_id = ? AND user_id = ?',
      whereArgs: uid == null ? [localId] : [localId, uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<List<Category>> getAllCategories({String? type}) async {
    final db = await database;
    final uid = _activeUserId;
    final conditions = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }
    if (uid != null) {
      conditions.add('user_id = ?');
      args.add(uid);
    }

    final rows = await db.query(
      'categories',
      where: conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name ASC',
    );
    return rows.map((row) => Category.fromMap(row)).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingRows(String table) async {
    final uid = _activeUserId;
    if (uid == null) return const [];
    final db = await database;
    return db.query(
      table,
      where: 'sync_status = ? AND user_id = ?',
      whereArgs: ['pending', uid],
    );
  }

  Future<int> countPending() async {
    final uid = _activeUserId;
    if (uid == null) return 0;
    final db = await database;
    final result = await db.rawQuery(
      "SELECT "
      "(SELECT COUNT(*) FROM expenses WHERE sync_status = 'pending' AND user_id = ?) + "
      "(SELECT COUNT(*) FROM budgets  WHERE sync_status = 'pending' AND user_id = ?) + "
      "(SELECT COUNT(*) FROM income   WHERE sync_status = 'pending' AND user_id = ?) + "
      "(SELECT COUNT(*) FROM categories WHERE sync_status = 'pending' AND user_id = ?) "
      "AS c",
      [uid, uid, uid, uid],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<void> markSynced({
    required String table,
    required String clientUuid,
    required int serverId,
  }) async {
    final db = await database;
    final uid = _activeUserId;
    await db.update(
      table,
      {'sync_status': 'synced', 'server_id': serverId},
      where: uid == null
          ? 'client_uuid = ?'
          : 'client_uuid = ? AND user_id = ?',
      whereArgs: uid == null ? [clientUuid] : [clientUuid, uid],
    );
  }

  Future<void> upsertFromServer({
    required String table,
    required Map<String, dynamic> serverRow,
    required String userId,
  }) async {
    final db = await database;
    final uuid = serverRow['client_uuid'] as String?;
    if (uuid == null || uuid.isEmpty) return;

    final existing = await db.query(
      table,
      where: 'client_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );

    final data = <String, dynamic>{
      'server_id': serverRow['id'],
      'client_uuid': uuid,
      'user_id': userId,
      'sync_status': 'synced',
      'created_at': serverRow['created_at'],
      'updated_at': serverRow['updated_at'],
      'deleted_at': serverRow['deleted_at'],
    };

    if (table == 'expenses') {
      data.addAll({
        'amount': (serverRow['amount'] as num).toDouble(),
        'category': serverRow['category'],
        'description': serverRow['description'],
        'merchant': serverRow['merchant'],
        'payment_method': serverRow['payment_method'],
        'expense_date': serverRow['expense_date'],
      });
    } else if (table == 'budgets') {
      data.addAll({
        'category': serverRow['category'],
        'amount': (serverRow['amount'] as num).toDouble(),
        'period': serverRow['period'],
        'start_date': serverRow['start_date'],
        'end_date': serverRow['end_date'],
      });
    } else if (table == 'income') {
      data.addAll({
        'amount': (serverRow['amount'] as num).toDouble(),
        'source': serverRow['source'],
        'description': serverRow['description'],
        'income_date': serverRow['income_date'],
      });
    } else if (table == 'categories') {
      data.addAll({
        'name': serverRow['name'],
        'type': serverRow['type'] ?? 'expense',
        'icon': serverRow['icon'],
        'color': serverRow['color'],
      });
    }

    if (existing.isEmpty) {
      await db.insert(table, data);
      return;
    }

    final local = existing.first;
    final localStatus = local['sync_status'] as String? ?? 'synced';
    final localUpdated = local['updated_at'] as String? ?? '';
    final serverUpdated = (serverRow['updated_at'] as String?) ?? '';

    if (localStatus == 'pending' &&
        localUpdated.compareTo(serverUpdated) > 0) {
      return;
    }

    await db.update(
      table,
      data,
      where: 'local_id = ?',
      whereArgs: [local['local_id']],
    );
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}