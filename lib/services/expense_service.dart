import '../models/expense.dart';
import 'api_service.dart';

@Deprecated(
  'Dead code. SyncService and ApiService already provide this functionality. '
  'Safe to delete after confirming zero callers with: grep -r ExpenseService lib/',
)
class ExpenseService {
  ExpenseService._();

  @Deprecated('Dead code. No callers in lib/.')
  static Future<bool> ping() async {
    final result = await ApiService.get('/api/ping');
    return result.ok;
  }

  @Deprecated('Dead code. No callers in lib/.')
  static Future<List<Expense>> fetchAll(String userId) async {
    final result = await ApiService.get('/api/expenses');
    if (!result.ok || result.body == null) return [];

    final data = result.body!['data'];
    if (data is! List) return [];

    final list = <Expense>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        list.add(
          Expense(
            serverId: item['id'] as int?,
            clientUuid: item['client_uuid'] as String,
            userId: userId,
            amount: (item['amount'] as num).toDouble(),
            category: item['category'] as String,
            description: item['description'] as String,
            merchant: item['merchant'] as String?,
            paymentMethod: item['payment_method'] as String?,
            expenseDate: _parseExpenseDate(item['expense_date'] as String),
            syncStatus: 'synced',
            createdAt: DateTime.parse(item['created_at'] as String),
            updatedAt: DateTime.parse(item['updated_at'] as String),
          ),
        );
      }
    }
    return list;
  }

  @Deprecated('Dead code. No callers in lib/.')
  static Future<int?> push(Expense e) async {
    final body = {
      'client_uuid': e.clientUuid,
      'amount': e.amount,
      'category': e.category,
      'description': e.description,
      'merchant': e.merchant,
      'payment_method': e.paymentMethod,
      'expense_date': _formatExpenseDate(e.expenseDate),
    };

    final result = await ApiService.post('/api/expenses', body);
    if (!result.ok) return null;

    final data = result.body?['data'];
    if (data is Map && data['id'] is int) return data['id'] as int;
    return null;
  }

  static String _formatExpenseDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseExpenseDate(String dateStr) {
    try {
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      return DateTime.parse('${dateStr}T00:00:00Z');
    } catch (_) {
      return DateTime.now();
    }
  }
}