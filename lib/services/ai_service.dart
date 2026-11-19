import 'package:uuid/uuid.dart';

import '../models/ai_insight.dart';
import 'api_service.dart';

class ParsedExpense {
  final double? amount;
  final String category;
  final String description;
  final String? merchant;
  final String? paymentMethod;
  final String? expenseDate;
  final bool isLocal;

  ParsedExpense({
    this.amount,
    required this.category,
    required this.description,
    this.merchant,
    this.paymentMethod,
    this.expenseDate,
    this.isLocal = false,
  });
}

class CategorySuggestion {
  final String category;
  final String confidence;
  final String reason;
  final bool isLocal;

  CategorySuggestion({
    required this.category,
    this.confidence = 'low',
    this.reason = '',
    this.isLocal = false,
  });
}

class AIService {
  AIService._();

  static const _uuid = Uuid();
  static const String _insightNamespaceUrl =
      '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  static Future<ParsedExpense?> parseExpense(String text) async {
    final result = await ApiService.post('/api/ai/parse-expense', {
      'text': text,
    });

    if (result.ok && result.body != null) {
      final data = result.body!['data'];
      if (data is Map) {
        return ParsedExpense(
          amount: _toDouble(data['amount']),
          category: (data['category'] as String?) ?? 'Other',
          description: (data['description'] as String?) ?? text,
          merchant: data['merchant'] as String?,
          paymentMethod: data['payment_method'] as String?,
          expenseDate: data['expense_date'] as String?,
          isLocal: false,
        );
      }
    }

    return LocalParser.parse(text);
  }

  static Future<CategorySuggestion> categorize({
    required String text,
    String? merchant,
  }) async {
    final body = <String, dynamic>{'text': text};
    if (merchant != null && merchant.trim().isNotEmpty) {
      body['merchant'] = merchant.trim();
    }

    final result = await ApiService.post('/api/ai/categorize', body);

    if (result.ok && result.body != null) {
      final data = result.body!['data'];
      if (data is Map) {
        return CategorySuggestion(
          category: (data['category'] as String?) ?? 'Other',
          confidence: (data['confidence'] as String?) ?? 'low',
          reason: (data['reason'] as String?) ?? '',
          isLocal: false,
        );
      }
    }

    final guess = LocalParser.guessCategory(text, merchant);
    return CategorySuggestion(
      category: guess,
      confidence: guess == 'Other' ? 'low' : 'medium',
      reason: 'Guessed from keywords (offline)',
      isLocal: true,
    );
  }

  static Future<AiInsight?> fetchInsight({required String userId}) async {
    final result = await ApiService.post('/api/ai/insights', {});

    if (!result.ok || result.body == null) return null;

    final data = result.body!['data'];
    if (data is! Map) return null;

    final insightMap = data['insight'];
    if (insightMap is! Map) return null;

    final now = DateTime.now();

    final rawSuggestions = insightMap['suggestions'];
    final suggestions = <String>[];
    if (rawSuggestions is List) {
      for (final s in rawSuggestions) {
        if (s is String && s.trim().isNotEmpty) {
          suggestions.add(s.trim());
        }
      }
    }

    final type = (insightMap['type'] as String?) ?? 'info';
    final title = (insightMap['title'] as String?) ?? 'Insight';
    final message = (insightMap['message'] as String?) ?? '';

    final clientUuid = _uuid.v5(
      _insightNamespaceUrl,
      '$userId|$type|$title|$message|${suggestions.join(';')}',
    );

    return AiInsight(
      clientUuid: clientUuid,
      userId: userId,
      type: type,
      title: title,
      message: message,
      suggestions: suggestions,
      generatedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class LocalParser {
  LocalParser._();

  static const _categoryKeywords = <String, List<String>>{
    'Food': [
      'lunch', 'dinner', 'breakfast', 'snack', 'coffee', 'jollibee',
      'mcdo', 'mcdonald', 'kfc', 'chowking', 'food', 'eat', 'meal',
      'restaurant', 'cafe', 'grocery',
    ],
    'Transportation': [
      'grab', 'taxi', 'jeep', 'tricycle', 'bus', 'mrt', 'lrt', 'fare',
      'gas', 'gasoline', 'fuel', 'ride', 'transport',
    ],
    'Shopping': [
      'shirt', 'shoes', 'bag', 'clothes', 'shopee', 'lazada', 'shopping',
      'buy', 'bought',
    ],
    'Utilities': [
      'electric', 'water', 'internet', 'wifi', 'bill', 'load', 'postpaid',
      'globe', 'smart', 'pldt', 'meralco',
    ],
    'Entertainment': [
      'movie', 'cinema', 'netflix', 'spotify', 'game', 'concert', 'ticket',
    ],
    'Health': ['medicine', 'doctor', 'hospital', 'pharmacy', 'gym'],
    'Education': ['book', 'tuition', 'school', 'course', 'pen', 'notebook'],
  };

  static ParsedExpense? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final extraction = _extractAmount(trimmed);
    final category = guessCategory(trimmed, null);
    final desc = _buildDescription(trimmed, extraction.matchedText);

    return ParsedExpense(
      amount: extraction.amount,
      category: category,
      description: desc,
      isLocal: true,
    );
  }

  static String guessCategory(String text, String? merchant) {
    final combined =
        '${text.toLowerCase()} ${(merchant ?? '').toLowerCase()}';

    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((kw) => combined.contains(kw))) {
        return entry.key;
      }
    }
    return 'Other';
  }

  static ({double? amount, String? matchedText}) _extractAmount(String text) {
    final currencyRegex = RegExp(
      r'(?:[₱$]|php|peso[s]?)\s*(\d[\d.,]*\d|\d)',
      caseSensitive: false,
    );
    final currencyMatch = currencyRegex.firstMatch(text);
    if (currencyMatch != null) {
      final token = currencyMatch.group(1)!;
      final parsed = _parseAmountToken(token);
      if (parsed != null) {
        return (amount: parsed, matchedText: token);
      }
    }

    final numberRegex = RegExp(r'\d[\d.,]*\d|\d');
    double? best;
    String? bestToken;
    for (final m in numberRegex.allMatches(text)) {
      final token = m.group(0)!;
      final parsed = _parseAmountToken(token);
      if (parsed != null && (best == null || parsed > best)) {
        best = parsed;
        bestToken = token;
      }
    }
    return (amount: best, matchedText: bestToken);
  }

  static double? _parseAmountToken(String token) {
    var s = token.trim();
    if (s.isEmpty) return null;

    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');

    if (lastDot > lastComma &&
        lastDot < s.length - 1 &&
        s.length - lastDot - 1 <= 2) {
      final intPart = s
          .substring(0, lastDot)
          .replaceAll(RegExp(r'[.,]'), '');
      final decPart = s.substring(lastDot + 1);
      s = '$intPart.$decPart';
    } else {
      s = s.replaceAll(RegExp(r'[.,]'), '');
    }

    final parsed = double.tryParse(s);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static String _buildDescription(String text, String? matchedAmount) {
    var result = text;
    result = result.replaceAll(RegExp(r'[₱$]'), '');
    result = result.replaceAll(RegExp(r'\bphp\b', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'\bpeso[s]?\b', caseSensitive: false), '');
    if (matchedAmount != null && matchedAmount.isNotEmpty) {
      result = result.replaceFirst(matchedAmount, '');
    }
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (result.isEmpty) {
      return text.length > 80 ? text.substring(0, 80) : text;
    }
    return result.length > 80 ? result.substring(0, 80) : result;
  }
}