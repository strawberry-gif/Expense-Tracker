import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;

class AppConstants {
  AppConstants._();

  static const String appName = 'Alkan';

  static String get apiBaseUrl {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) return envBaseUrl;

    if (kReleaseMode) {
      return 'https://api.alkan.app/expense_tracker_api';
    }

    if (kIsWeb) return 'http://localhost/expense_tracker_api';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/expense_tracker_api';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost/expense_tracker_api';
    }
    return 'http://127.0.0.1/expense_tracker_api';
  }

  static const List<String> defaultCategories = [
    'Food',
    'Transportation',
    'Shopping',
    'Utilities',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'Card',
    'GCash',
    'Maya',
    'Bank Transfer',
    'Other',
  ];

  static const List<String> incomeSources = [
    'Allowance',
    'Salary',
    'Freelance',
    'Business',
    'Gift',
    'Other',
  ];

  static const Map<String, String> sortOptions = {
    'date_desc': 'Newest first',
    'date_asc': 'Oldest first',
    'amount_desc': 'Highest amount',
    'amount_asc': 'Lowest amount',
  };

  static const String currencySymbol = '₱';

  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
  static const String syncFailed = 'failed';

  static const String overallBudgetLabel = 'Overall';
}