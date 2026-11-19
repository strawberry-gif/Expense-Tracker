import '../database/sqlite_database.dart';
import 'export_writer.dart';

class ExportResult {
  final bool ok;
  final String? path;
  final String? error;

  ExportResult({required this.ok, this.path, this.error});
}

class ExportService {
  ExportService._();

  static final _db = SQLiteDatabase();

  static Future<ExportResult> exportExpenses() async {
    try {
      final expenses = await _db.getAllExpenses();

      final buffer = StringBuffer();
      buffer.write('\uFEFF');
      buffer.writeln(
        'Date,Amount,Category,Description,Merchant,Payment Method,Sync Status',
      );

      for (final e in expenses) {
        buffer.writeln([
          _csvDate(e.expenseDate),
          e.amount.toStringAsFixed(2),
          _csv(e.category),
          _csv(e.description),
          _csv(e.merchant ?? ''),
          _csv(e.paymentMethod ?? ''),
          _csv(e.syncStatus),
        ].join(','));
      }

      return await _finalize('expenses', buffer.toString());
    } catch (e) {
      return ExportResult(ok: false, error: e.toString());
    }
  }

  static Future<ExportResult> exportIncome() async {
    try {
      final items = await _db.getAllIncome();

      final buffer = StringBuffer();
      buffer.write('\uFEFF');
      buffer.writeln('Date,Amount,Source,Description,Sync Status');

      for (final i in items) {
        buffer.writeln([
          _csvDate(i.incomeDate),
          i.amount.toStringAsFixed(2),
          _csv(i.source),
          _csv(i.description ?? ''),
          _csv(i.syncStatus),
        ].join(','));
      }

      return await _finalize('income', buffer.toString());
    } catch (e) {
      return ExportResult(ok: false, error: e.toString());
    }
  }

  static Future<ExportResult> exportBudgets() async {
    try {
      final budgets = await _db.getAllBudgets();

      final buffer = StringBuffer();
      buffer.write('\uFEFF');
      buffer.writeln('Category,Budget Amount,Period,Sync Status');

      for (final b in budgets) {
        buffer.writeln([
          _csv(b.category ?? 'Overall'),
          b.amount.toStringAsFixed(2),
          _csv(b.period),
          _csv(b.syncStatus),
        ].join(','));
      }

      return await _finalize('budgets', buffer.toString());
    } catch (e) {
      return ExportResult(ok: false, error: e.toString());
    }
  }

  static Future<ExportResult> _finalize(String prefix, String content) async {
    final path = await writeExportFile(prefix, content);
    return ExportResult(ok: true, path: path);
  }

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n') ||
        escaped.contains('\r')) {
      return '"$escaped"';
    }
    return escaped;
  }

  static String _csvDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}