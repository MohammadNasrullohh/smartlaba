import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'firestore_scope.dart';

class BusinessAiInsight {
  final String title;
  final String message;
  final String severity;

  const BusinessAiInsight({
    required this.title,
    required this.message,
    required this.severity,
  });
}

class BusinessDailyMetric {
  final DateTime date;
  final num revenue;
  final num profit;
  final int transactions;

  const BusinessDailyMetric({
    required this.date,
    required this.revenue,
    required this.profit,
    required this.transactions,
  });
}

class BusinessLowStockItem {
  final String name;
  final int stock;
  final String category;
  final num price;

  const BusinessLowStockItem({
    required this.name,
    required this.stock,
    required this.category,
    required this.price,
  });
}

class BusinessTopProduct {
  final String name;
  final int quantity;
  final num revenue;

  const BusinessTopProduct({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

class BusinessAnalyticsBundle {
  final num revenueToday;
  final num revenue7d;
  final num revenue30d;
  final num profitToday;
  final num profit7d;
  final num profit30d;
  final int transactionsToday;
  final int transactions30d;
  final double averageOrderValue;
  final double marginPercent;
  final double growthPercent;
  final double healthScore;
  final double salesConsistencyScore;
  final double marginScore;
  final double inventoryScore;
  final double customerScore;
  final double forecastNext7Days;
  final double forecastNext30Days;
  final String busiestDayLabel;
  final String topPaymentMethod;
  final List<BusinessDailyMetric> last7Days;
  final List<BusinessAiInsight> financeInsights;
  final List<BusinessAiInsight> predictionInsights;
  final List<BusinessAiInsight> healthInsights;
  final List<BusinessLowStockItem> lowStockProducts;
  final List<BusinessTopProduct> topProducts;

  const BusinessAnalyticsBundle({
    required this.revenueToday,
    required this.revenue7d,
    required this.revenue30d,
    required this.profitToday,
    required this.profit7d,
    required this.profit30d,
    required this.transactionsToday,
    required this.transactions30d,
    required this.averageOrderValue,
    required this.marginPercent,
    required this.growthPercent,
    required this.healthScore,
    required this.salesConsistencyScore,
    required this.marginScore,
    required this.inventoryScore,
    required this.customerScore,
    required this.forecastNext7Days,
    required this.forecastNext30Days,
    required this.busiestDayLabel,
    required this.topPaymentMethod,
    required this.last7Days,
    required this.financeInsights,
    required this.predictionInsights,
    required this.healthInsights,
    required this.lowStockProducts,
    required this.topProducts,
  });
}

class BusinessAiService {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
  static final Map<String, _CachedGeminiInsights> _geminiCache = {};

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BusinessAiService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<BusinessAnalyticsBundle> loadBundle() async {
    final scope = await resolveCurrentFirestoreScope(
      firestore: _firestore,
      auth: _auth,
    );
    if (scope == null) {
      return _emptyBundle();
    }

    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      _firestore.collection('transactions').get(),
      _firestore
          .collection('users')
          .doc(scope.dataOwnerUid)
          .collection('produk')
          .get(),
    ]);

    final transactionSnapshot = results[0];
    final productSnapshot = results[1];

    final transactions =
        transactionSnapshot.docs
            .map(_BusinessTransaction.fromDocument)
            .where((item) => _matchesScope(transaction: item, scope: scope))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final products = productSnapshot.docs
        .map(_BusinessProduct.fromDocument)
        .toList();

    final bundle = _buildBundle(transactions: transactions, products: products);
    return _augmentWithGeminiInsights(bundle);
  }

  BusinessAnalyticsBundle _buildBundle({
    required List<_BusinessTransaction> transactions,
    required List<_BusinessProduct> products,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final start7 = todayStart.subtract(const Duration(days: 6));
    final start30 = todayStart.subtract(const Duration(days: 29));
    final prev7Start = todayStart.subtract(const Duration(days: 13));
    final prev7End = todayStart.subtract(const Duration(days: 7));

    final todayTransactions = transactions
        .where((item) => _sameDay(item.createdAt, todayStart))
        .toList();
    final last7Transactions = transactions
        .where((item) => !item.createdAt.isBefore(start7))
        .toList();
    final last30Transactions = transactions
        .where((item) => !item.createdAt.isBefore(start30))
        .toList();
    final previous7Transactions = transactions
        .where(
          (item) =>
              !item.createdAt.isBefore(prev7Start) &&
              item.createdAt.isBefore(prev7End),
        )
        .toList();

    final revenueToday = _sumRevenue(todayTransactions);
    final revenue7d = _sumRevenue(last7Transactions);
    final revenue30d = _sumRevenue(last30Transactions);
    final profitToday = _sumProfit(todayTransactions);
    final profit7d = _sumProfit(last7Transactions);
    final profit30d = _sumProfit(last30Transactions);
    final transactionsToday = todayTransactions.length;
    final transactions30d = last30Transactions.length;
    final double averageOrderValue = transactions30d == 0
        ? 0
        : revenue30d.toDouble() / transactions30d;
    final double marginPercent = revenue30d <= 0
        ? 0
        : (profit30d.toDouble() / revenue30d.toDouble()) * 100;
    final prevRevenue7 = _sumRevenue(previous7Transactions);
    final double growthPercent = prevRevenue7 <= 0
        ? (revenue7d > 0 ? 100 : 0)
        : ((revenue7d.toDouble() - prevRevenue7.toDouble()) /
                  prevRevenue7.toDouble()) *
              100;

    final last7Days = List.generate(7, (index) {
      final date = start7.add(Duration(days: index));
      final dayTransactions = last7Transactions
          .where((item) => _sameDay(item.createdAt, date))
          .toList();
      return BusinessDailyMetric(
        date: date,
        revenue: _sumRevenue(dayTransactions),
        profit: _sumProfit(dayTransactions),
        transactions: dayTransactions.length,
      );
    });

    final paymentCounts = <String, int>{};
    for (final item in last30Transactions) {
      paymentCounts.update(
        item.paymentMethod,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final topPaymentMethod = paymentCounts.entries.isEmpty
        ? 'Tunai'
        : (paymentCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    final lowStockProducts = products.where((item) => item.stock <= 10).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    final topProductTotals = <String, _TopProductAccumulator>{};
    for (final transaction in last30Transactions) {
      for (final item in transaction.items) {
        final normalizedName = item.name.trim();
        if (normalizedName.isEmpty) {
          continue;
        }

        final key = normalizedName.toLowerCase();
        final bucket = topProductTotals.putIfAbsent(
          key,
          () => _TopProductAccumulator(name: normalizedName),
        );
        bucket.quantity += item.quantity;
        bucket.revenue += item.revenue;
      }
    }

    final topProducts = topProductTotals.values.toList()
      ..sort((a, b) {
        final quantityCompare = b.quantity.compareTo(a.quantity);
        if (quantityCompare != 0) {
          return quantityCompare;
        }
        return b.revenue.compareTo(a.revenue);
      });

    final transactionsPerDay = last7Days
        .map((item) => item.transactions)
        .toList();
    final busiestIndex = transactionsPerDay.isEmpty
        ? 0
        : transactionsPerDay.indexOf(
            transactionsPerDay.reduce((a, b) => a > b ? a : b),
          );
    final busiestDayLabel = _weekdayLabel(
      start7.add(Duration(days: busiestIndex)),
    );

    final activeDays = last30Transactions
        .map(
          (item) => DateTime(
            item.createdAt.year,
            item.createdAt.month,
            item.createdAt.day,
          ),
        )
        .toSet()
        .length;
    final salesConsistencyScore = ((activeDays / 30) * 100)
        .clamp(0, 100)
        .toDouble();
    final marginScore = (marginPercent * 2.5).clamp(0, 100).toDouble();
    final inventoryScore = products.isEmpty
        ? 50.0
        : (((products.length - lowStockProducts.length) / products.length) *
                  100)
              .clamp(0, 100)
              .toDouble();
    final double customerScore = averageOrderValue <= 0
        ? 0
        : math.min(100, (averageOrderValue / 25000) * 100).toDouble();
    final healthScore =
        ((salesConsistencyScore * 0.3) +
                (marginScore * 0.3) +
                (inventoryScore * 0.2) +
                (customerScore * 0.2))
            .clamp(0, 100)
            .toDouble();

    final double dailyAverage7 = revenue7d.toDouble() / 7;
    final double dailyAverage30 = revenue30d.toDouble() / 30;
    final double forecastNext7Days =
        ((dailyAverage7 * 0.65) + (dailyAverage30 * 0.35)) * 7;
    final double forecastNext30Days =
        ((dailyAverage7 * 0.55) + (dailyAverage30 * 0.45)) * 30;

    final financeInsights = _buildFinanceInsights(
      growthPercent: growthPercent,
      marginPercent: marginPercent,
      topPaymentMethod: topPaymentMethod,
      lowStockProducts: lowStockProducts,
      averageOrderValue: averageOrderValue,
    );
    final predictionInsights = _buildPredictionInsights(
      forecastNext7Days: forecastNext7Days,
      busiestDayLabel: busiestDayLabel,
      lowStockProducts: lowStockProducts,
      growthPercent: growthPercent,
    );
    final healthInsights = _buildHealthInsights(
      healthScore: healthScore,
      inventoryScore: inventoryScore,
      marginScore: marginScore,
      salesConsistencyScore: salesConsistencyScore,
    );

    return BusinessAnalyticsBundle(
      revenueToday: revenueToday,
      revenue7d: revenue7d,
      revenue30d: revenue30d,
      profitToday: profitToday,
      profit7d: profit7d,
      profit30d: profit30d,
      transactionsToday: transactionsToday,
      transactions30d: transactions30d,
      averageOrderValue: averageOrderValue.toDouble(),
      marginPercent: marginPercent.toDouble(),
      growthPercent: growthPercent.toDouble(),
      healthScore: healthScore,
      salesConsistencyScore: salesConsistencyScore,
      marginScore: marginScore,
      inventoryScore: inventoryScore,
      customerScore: customerScore,
      forecastNext7Days: forecastNext7Days,
      forecastNext30Days: forecastNext30Days,
      busiestDayLabel: busiestDayLabel,
      topPaymentMethod: topPaymentMethod,
      last7Days: last7Days,
      financeInsights: financeInsights,
      predictionInsights: predictionInsights,
      healthInsights: healthInsights,
      lowStockProducts: lowStockProducts
          .take(5)
          .map(
            (item) => BusinessLowStockItem(
              name: item.name,
              stock: item.stock,
              category: item.category,
              price: item.sellPrice,
            ),
          )
          .toList(),
      topProducts: topProducts
          .take(5)
          .map(
            (item) => BusinessTopProduct(
              name: item.name,
              quantity: item.quantity,
              revenue: item.revenue,
            ),
          )
          .toList(),
    );
  }

  Future<BusinessAnalyticsBundle> _augmentWithGeminiInsights(
    BusinessAnalyticsBundle base,
  ) async {
    if (_geminiApiKey.isEmpty) {
      return base;
    }

    if (base.transactions30d == 0 && base.lowStockProducts.isEmpty) {
      return base;
    }

    final cacheKey = _geminiCacheKey(base);
    final cached = _geminiCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) <
            const Duration(minutes: 5)) {
      return _mergeGeminiInsights(base, cached.payload);
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent',
            ),
            headers: const {
              'Content-Type': 'application/json',
              'x-goog-api-key': _geminiApiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': _geminiPrompt(base)},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.35,
                'topP': 0.9,
                'maxOutputTokens': 1200,
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return base;
      }

      final payload = _parseGeminiInsights(response.body);
      if (payload == null) {
        return base;
      }

      _geminiCache[cacheKey] = _CachedGeminiInsights(
        createdAt: DateTime.now(),
        payload: payload,
      );

      return _mergeGeminiInsights(base, payload);
    } on TimeoutException {
      return base;
    } catch (_) {
      return base;
    }
  }

  String _geminiCacheKey(BusinessAnalyticsBundle bundle) {
    return jsonEncode({
      'revenueToday': bundle.revenueToday,
      'revenue7d': bundle.revenue7d,
      'revenue30d': bundle.revenue30d,
      'profit7d': bundle.profit7d,
      'profit30d': bundle.profit30d,
      'transactions30d': bundle.transactions30d,
      'marginPercent': bundle.marginPercent.toStringAsFixed(2),
      'growthPercent': bundle.growthPercent.toStringAsFixed(2),
      'healthScore': bundle.healthScore.toStringAsFixed(2),
      'busiestDayLabel': bundle.busiestDayLabel,
      'topPaymentMethod': bundle.topPaymentMethod,
      'lowStockProducts': bundle.lowStockProducts
          .map((item) => '${item.name}:${item.stock}')
          .toList(),
      'topProducts': bundle.topProducts
          .map((item) => '${item.name}:${item.quantity}')
          .toList(),
    });
  }

  String _geminiPrompt(BusinessAnalyticsBundle bundle) {
    final metrics = {
      'revenue_today': bundle.revenueToday,
      'revenue_7_days': bundle.revenue7d,
      'revenue_30_days': bundle.revenue30d,
      'profit_today': bundle.profitToday,
      'profit_7_days': bundle.profit7d,
      'profit_30_days': bundle.profit30d,
      'transactions_today': bundle.transactionsToday,
      'transactions_30_days': bundle.transactions30d,
      'average_order_value': bundle.averageOrderValue,
      'margin_percent': bundle.marginPercent,
      'growth_percent': bundle.growthPercent,
      'health_score': bundle.healthScore,
      'sales_consistency_score': bundle.salesConsistencyScore,
      'margin_score': bundle.marginScore,
      'inventory_score': bundle.inventoryScore,
      'customer_score': bundle.customerScore,
      'forecast_next_7_days': bundle.forecastNext7Days,
      'forecast_next_30_days': bundle.forecastNext30Days,
      'busiest_day': bundle.busiestDayLabel,
      'top_payment_method': bundle.topPaymentMethod,
      'last_7_days': bundle.last7Days
          .map(
            (item) => {
              'date': item.date.toIso8601String(),
              'revenue': item.revenue,
              'profit': item.profit,
              'transactions': item.transactions,
            },
          )
          .toList(),
      'low_stock_products': bundle.lowStockProducts
          .map(
            (item) => {
              'name': item.name,
              'stock': item.stock,
              'category': item.category,
              'price': item.price,
            },
          )
          .toList(),
      'top_products': bundle.topProducts
          .map(
            (item) => {
              'name': item.name,
              'quantity': item.quantity,
              'revenue': item.revenue,
            },
          )
          .toList(),
    };

    return '''
Anda adalah analis bisnis retail Indonesia. Jawab hanya JSON valid tanpa markdown, singkat, akurat, tidak mengarang angka, dan fokus pada tindakan nyata.

Analisis data bisnis berikut dan kembalikan JSON valid dengan format:
{
  "finance": [{"title": "...", "message": "...", "severity": "info|good|medium|high"}],
  "prediction": [{"title": "...", "message": "...", "severity": "info|good|medium|high"}],
  "health": [{"title": "...", "message": "...", "severity": "info|good|medium|high"}]
}

Aturan:
- Bahasa Indonesia.
- Maksimal 3 insight per kategori.
- Judul singkat, message 1 kalimat padat dan action-oriented.
- Jangan mengarang angka atau kondisi yang tidak ada di data.
- Jika data tipis, katakan secara jujur.

Data:
${jsonEncode(metrics)}
''';
  }

  _GeminiInsightPayload? _parseGeminiInsights(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) {
      return null;
    }

    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }

    final parts = content['parts'];
    if (parts is! List) {
      return null;
    }

    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => (part['text'] ?? '').toString())
        .join()
        .trim();
    if (text.isEmpty) {
      return null;
    }

    final cleanedText = _extractJsonText(text);
    final parsed = jsonDecode(cleanedText);
    if (parsed is! Map<String, dynamic>) {
      return null;
    }

    return _GeminiInsightPayload(
      finance: _parseGeminiInsightList(parsed['finance']),
      prediction: _parseGeminiInsightList(parsed['prediction']),
      health: _parseGeminiInsightList(parsed['health']),
    );
  }

  String _extractJsonText(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      return trimmed.substring(firstBrace, lastBrace + 1);
    }

    return trimmed;
  }

  List<BusinessAiInsight> _parseGeminiInsightList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final title = (item['title'] ?? '').toString().trim();
          final message = (item['message'] ?? '').toString().trim();
          final severity = _normalizeSeverity(
            (item['severity'] ?? 'info').toString(),
          );
          if (title.isEmpty || message.isEmpty) {
            return null;
          }
          return BusinessAiInsight(
            title: title,
            message: message,
            severity: severity,
          );
        })
        .whereType<BusinessAiInsight>()
        .take(3)
        .toList();
  }

  String _normalizeSeverity(String severity) {
    switch (severity.trim().toLowerCase()) {
      case 'high':
      case 'medium':
      case 'good':
      case 'info':
        return severity.trim().toLowerCase();
      default:
        return 'info';
    }
  }

  BusinessAnalyticsBundle _mergeGeminiInsights(
    BusinessAnalyticsBundle base,
    _GeminiInsightPayload payload,
  ) {
    return BusinessAnalyticsBundle(
      revenueToday: base.revenueToday,
      revenue7d: base.revenue7d,
      revenue30d: base.revenue30d,
      profitToday: base.profitToday,
      profit7d: base.profit7d,
      profit30d: base.profit30d,
      transactionsToday: base.transactionsToday,
      transactions30d: base.transactions30d,
      averageOrderValue: base.averageOrderValue,
      marginPercent: base.marginPercent,
      growthPercent: base.growthPercent,
      healthScore: base.healthScore,
      salesConsistencyScore: base.salesConsistencyScore,
      marginScore: base.marginScore,
      inventoryScore: base.inventoryScore,
      customerScore: base.customerScore,
      forecastNext7Days: base.forecastNext7Days,
      forecastNext30Days: base.forecastNext30Days,
      busiestDayLabel: base.busiestDayLabel,
      topPaymentMethod: base.topPaymentMethod,
      last7Days: base.last7Days,
      financeInsights: payload.finance.isNotEmpty
          ? payload.finance
          : base.financeInsights,
      predictionInsights: payload.prediction.isNotEmpty
          ? payload.prediction
          : base.predictionInsights,
      healthInsights: payload.health.isNotEmpty
          ? payload.health
          : base.healthInsights,
      lowStockProducts: base.lowStockProducts,
      topProducts: base.topProducts,
    );
  }

  List<BusinessAiInsight> _buildFinanceInsights({
    required double growthPercent,
    required double marginPercent,
    required String topPaymentMethod,
    required List<_BusinessProduct> lowStockProducts,
    required double averageOrderValue,
  }) {
    final insights = <BusinessAiInsight>[];

    if (growthPercent < -10) {
      insights.add(
        BusinessAiInsight(
          title: 'Anomali Pendapatan',
          message:
              'Pendapatan 7 hari terakhir turun ${growthPercent.abs().toStringAsFixed(1)}%. Periksa promo dan jam ramai toko.',
          severity: 'high',
        ),
      );
    } else if (growthPercent > 10) {
      insights.add(
        BusinessAiInsight(
          title: 'Pertumbuhan Positif',
          message:
              'Pendapatan naik ${growthPercent.toStringAsFixed(1)}%. Momentum ini cocok untuk dorong bundling produk.',
          severity: 'good',
        ),
      );
    }

    if (marginPercent < 20) {
      insights.add(
        BusinessAiInsight(
          title: 'Margin Perlu Diperbaiki',
          message:
              'Margin rata-rata baru ${marginPercent.toStringAsFixed(1)}%. Review harga jual dan biaya bahan baku.',
          severity: 'medium',
        ),
      );
    }

    if (lowStockProducts.isNotEmpty) {
      insights.add(
        BusinessAiInsight(
          title: 'Risiko Stok',
          message:
              '${lowStockProducts.length} produk mendekati habis. Prioritaskan restock agar omzet tidak terhambat.',
          severity: 'medium',
        ),
      );
    }

    insights.add(
      BusinessAiInsight(
        title: 'Metode Bayar Dominan',
        message:
            'Metode pembayaran terbanyak saat ini adalah $topPaymentMethod. Pertimbangkan optimasi promo di channel ini.',
        severity: 'info',
      ),
    );

    if (averageOrderValue > 0) {
      insights.add(
        BusinessAiInsight(
          title: 'AI Saran Ticket Size',
          message:
              'Rata-rata belanja ${_currency(averageOrderValue)}. Tambahkan upsell kecil untuk menaikkan nilai per transaksi.',
          severity: 'info',
        ),
      );
    }

    return insights;
  }

  List<BusinessAiInsight> _buildPredictionInsights({
    required num forecastNext7Days,
    required String busiestDayLabel,
    required List<_BusinessProduct> lowStockProducts,
    required double growthPercent,
  }) {
    final insights = <BusinessAiInsight>[
      BusinessAiInsight(
        title: 'Prediksi 7 Hari',
        message:
            'AI memproyeksikan omzet 7 hari ke depan sekitar ${_currency(forecastNext7Days)} jika pola saat ini bertahan.',
        severity: 'info',
      ),
      BusinessAiInsight(
        title: 'Hari Ramai',
        message:
            'Hari paling aktif dalam pola terbaru adalah $busiestDayLabel. Jadwalkan stok dan kasir lebih siap di hari ini.',
        severity: 'good',
      ),
    ];

    if (lowStockProducts.isNotEmpty) {
      final first = lowStockProducts.first;
      insights.add(
        BusinessAiInsight(
          title: 'Prioritas Restock',
          message:
              'Produk ${first.name} tersisa ${first.stock}. AI merekomendasikan restock lebih dulu pada kategori ${first.category}.',
          severity: 'high',
        ),
      );
    }

    insights.add(
      BusinessAiInsight(
        title: 'Rencana Operasional',
        message: growthPercent >= 0
            ? 'Pertahankan menu terlaris, siapkan stok tambahan, dan uji promo bundling ringan.'
            : 'Perkuat promosi lokal, evaluasi jam sepi, dan dorong produk margin tinggi.',
        severity: 'info',
      ),
    );

    return insights;
  }

  List<BusinessAiInsight> _buildHealthInsights({
    required double healthScore,
    required double inventoryScore,
    required double marginScore,
    required double salesConsistencyScore,
  }) {
    final insights = <BusinessAiInsight>[];

    insights.add(
      BusinessAiInsight(
        title: 'Status Kesehatan Bisnis',
        message: healthScore >= 75
            ? 'Skor kesehatan bisnis berada di level baik dan cukup stabil.'
            : healthScore >= 55
            ? 'Skor kesehatan bisnis berada di level menengah dan masih bisa ditingkatkan.'
            : 'Skor kesehatan bisnis berada di level rendah dan butuh tindakan prioritas.',
        severity: healthScore >= 75
            ? 'good'
            : healthScore >= 55
            ? 'medium'
            : 'high',
      ),
    );

    if (inventoryScore < 70) {
      insights.add(
        BusinessAiInsight(
          title: 'Inventori Belum Stabil',
          message:
              'Skor inventori ${inventoryScore.toStringAsFixed(0)}. Kurangi produk yang terlalu sering kosong.',
          severity: 'medium',
        ),
      );
    }

    if (marginScore < 65) {
      insights.add(
        BusinessAiInsight(
          title: 'Profitabilitas Perlu Dijaga',
          message:
              'Skor margin ${marginScore.toStringAsFixed(0)}. Fokus ke produk dengan margin sehat untuk memperbaiki skor.',
          severity: 'medium',
        ),
      );
    }

    if (salesConsistencyScore < 55) {
      insights.add(
        BusinessAiInsight(
          title: 'Penjualan Belum Konsisten',
          message:
              'Skor konsistensi ${salesConsistencyScore.toStringAsFixed(0)}. Buat promo periodik agar trafik lebih stabil.',
          severity: 'high',
        ),
      );
    }

    return insights;
  }

  BusinessAnalyticsBundle _emptyBundle() {
    return const BusinessAnalyticsBundle(
      revenueToday: 0,
      revenue7d: 0,
      revenue30d: 0,
      profitToday: 0,
      profit7d: 0,
      profit30d: 0,
      transactionsToday: 0,
      transactions30d: 0,
      averageOrderValue: 0,
      marginPercent: 0,
      growthPercent: 0,
      healthScore: 0,
      salesConsistencyScore: 0,
      marginScore: 0,
      inventoryScore: 0,
      customerScore: 0,
      forecastNext7Days: 0,
      forecastNext30Days: 0,
      busiestDayLabel: '-',
      topPaymentMethod: 'Tunai',
      last7Days: [],
      financeInsights: [],
      predictionInsights: [],
      healthInsights: [],
      lowStockProducts: [],
      topProducts: [],
    );
  }
}

class _BusinessTransaction {
  final num revenue;
  final num profit;
  final DateTime createdAt;
  final String paymentMethod;
  final String ownerUid;
  final String storeId;
  final List<_BusinessTransactionItem> items;

  const _BusinessTransaction({
    required this.revenue,
    required this.profit,
    required this.createdAt,
    required this.paymentMethod,
    required this.ownerUid,
    required this.storeId,
    required this.items,
  });

  factory _BusinessTransaction.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final revenue = _readNumber(data, const ['total', 'grandTotal', 'amount']);
    final profit = _readNumber(data, const ['laba', 'profit']);
    final createdAt =
        _readDate(data, const [
          'createdAt',
          'timestamp',
          'tanggal',
          'transactionDate',
          'date',
        ]) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return _BusinessTransaction(
      revenue: revenue,
      profit: profit,
      createdAt: createdAt,
      paymentMethod: _readString(data, const [
        'paymentMethod',
        'metodePembayaran',
        'metode',
        'payment',
      ], fallback: 'Tunai'),
      ownerUid: _readString(data, const ['ownerUid'], fallback: ''),
      storeId: _readString(data, const ['storeId'], fallback: ''),
      items: _readItemMaps(data)
          .map(_BusinessTransactionItem.fromMap)
          .where((item) => item.name.isNotEmpty)
          .toList(),
    );
  }
}

class _GeminiInsightPayload {
  final List<BusinessAiInsight> finance;
  final List<BusinessAiInsight> prediction;
  final List<BusinessAiInsight> health;

  const _GeminiInsightPayload({
    required this.finance,
    required this.prediction,
    required this.health,
  });
}

class _CachedGeminiInsights {
  final DateTime createdAt;
  final _GeminiInsightPayload payload;

  const _CachedGeminiInsights({required this.createdAt, required this.payload});
}

class _BusinessTransactionItem {
  final String name;
  final int quantity;
  final num revenue;

  const _BusinessTransactionItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  factory _BusinessTransactionItem.fromMap(Map<String, dynamic> data) {
    final quantity = math.max(
      1,
      _readNumber(data, const ['qty', 'quantity', 'jumlah', 'count']).round(),
    );
    final subtotal = _readNumber(data, const ['subtotal', 'total', 'amount']);
    final unitPrice = _readNumber(data, const ['hargaJual', 'price', 'harga']);
    final revenue = subtotal > 0 ? subtotal : unitPrice * quantity;

    return _BusinessTransactionItem(
      name: _readString(data, const [
        'namaProduk',
        'productName',
        'name',
        'nama',
        'title',
      ], fallback: ''),
      quantity: quantity,
      revenue: revenue > 0 ? revenue : quantity,
    );
  }
}

class _BusinessProduct {
  final String name;
  final String category;
  final int stock;
  final num sellPrice;

  const _BusinessProduct({
    required this.name,
    required this.category,
    required this.stock,
    required this.sellPrice,
  });

  factory _BusinessProduct.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _BusinessProduct(
      name: (data['namaProduk'] ?? 'Produk').toString(),
      category: (data['kategori'] ?? '-').toString(),
      stock: _readNumber(data, const ['stok', 'stokAwal']).round(),
      sellPrice: _readNumber(data, const ['hargaJual']),
    );
  }
}

class _TopProductAccumulator {
  final String name;
  int quantity = 0;
  num revenue = 0;

  _TopProductAccumulator({required this.name});
}

bool _matchesScope({
  required _BusinessTransaction transaction,
  required FirestoreScope scope,
}) {
  return matchesStoreScopedRecord(
    recordOwnerUid: transaction.ownerUid,
    recordStoreId: transaction.storeId,
    scope: scope,
    includeLegacyOwnerFallback: true,
  );
}

num _sumRevenue(List<_BusinessTransaction> transactions) {
  return transactions.fold<num>(
    0,
    (totalRevenue, item) => totalRevenue + item.revenue,
  );
}

num _sumProfit(List<_BusinessTransaction> transactions) {
  return transactions.fold<num>(
    0,
    (totalProfit, item) => totalProfit + item.profit,
  );
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _weekdayLabel(DateTime date) {
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  return days[date.weekday - 1];
}

String _currency(num value) {
  final raw = value.round().toString();
  final formatted = raw.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $formatted';
}

String _readString(
  Map<String, dynamic> data,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return fallback;
}

num _readNumber(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is num) {
      return value;
    }
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
      final parsed = num.tryParse(normalized.replaceAll(',', '.'));
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

DateTime? _readDate(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

List<Map<String, dynamic>> _readItemMaps(Map<String, dynamic> data) {
  for (final key in const [
    'items',
    'produk',
    'products',
    'cart',
    'keranjang',
    'itemPenjualan',
    'detailItems',
    'details',
  ]) {
    final value = data[key];
    if (value is! Iterable) {
      continue;
    }

    final result = <Map<String, dynamic>>[];
    for (final entry in value) {
      if (entry is Map) {
        result.add(Map<String, dynamic>.from(entry));
      }
    }

    if (result.isNotEmpty) {
      return result;
    }
  }

  return const [];
}
