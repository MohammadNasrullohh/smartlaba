import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'business_ai_service.dart';

class AiFinancePage extends StatelessWidget {
  final bool embedded;

  const AiFinancePage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return _BusinessAiPageFrame(
      title: 'Analisis Laba & Keuangan',
      embedded: embedded,
      builder: (bundle) => [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.18,
          children: [
            _AiMetricCard(
              label: 'Omzet 7 Hari',
              value: _currency(bundle.revenue7d),
              icon: Icons.payments_outlined,
              iconColor: const Color(0xFF162B5A),
            ),
            _AiMetricCard(
              label: 'Laba 7 Hari',
              value: _currency(bundle.profit7d),
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF20A029),
            ),
            _AiMetricCard(
              label: 'Margin',
              value: '${bundle.marginPercent.toStringAsFixed(1)}%',
              icon: Icons.percent_rounded,
              iconColor: const Color(0xFFFF8A1F),
            ),
            _AiMetricCard(
              label: 'Avg Order',
              value: _currency(bundle.averageOrderValue),
              icon: Icons.shopping_bag_outlined,
              iconColor: const Color(0xFF6D4CFF),
            ),
          ],
        ),
        _AiSectionCard(
          title: 'Tren Omzet dan Laba',
          subtitle: '7 hari terakhir',
          child: bundle.last7Days.every((item) => item.revenue == 0)
              ? const _AiEmptyChartLabel(
                  message:
                      'Belum ada cukup data transaksi untuk analisis tren.',
                )
              : _RevenueProfitChart(metrics: bundle.last7Days),
        ),
        _AiSectionCard(
          title: 'Komposisi Keuangan',
          child: Column(
            children: [
              _AiInfoRow(
                label: 'Omzet Hari Ini',
                value: _currency(bundle.revenueToday),
              ),
              _AiInfoRow(
                label: 'Laba Hari Ini',
                value: _currency(bundle.profitToday),
              ),
              _AiInfoRow(
                label: 'Omzet 30 Hari',
                value: _currency(bundle.revenue30d),
              ),
              _AiInfoRow(
                label: 'Laba 30 Hari',
                value: _currency(bundle.profit30d),
              ),
              _AiInfoRow(
                label: 'Metode Bayar Dominan',
                value: bundle.topPaymentMethod,
              ),
              _AiInfoRow(
                label: 'Pertumbuhan 7 Hari',
                value: '${bundle.growthPercent.toStringAsFixed(1)}%',
                valueColor: bundle.growthPercent >= 0
                    ? const Color(0xFF20A029)
                    : const Color(0xFFE45353),
              ),
            ],
          ),
        ),
        _AiSectionCard(
          title: 'AI Insight Keuangan',
          child: Column(
            children: bundle.financeInsights
                .map((item) => _AiInsightTile(insight: item))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class AiPredictionPage extends StatelessWidget {
  final bool embedded;

  const AiPredictionPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return _BusinessAiPageFrame(
      title: 'Prediksi & Perencanaan',
      embedded: embedded,
      builder: (bundle) => [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.18,
          children: [
            _AiMetricCard(
              label: 'Prediksi 7 Hari',
              value: _currency(bundle.forecastNext7Days),
              icon: Icons.timeline_rounded,
              iconColor: const Color(0xFF162B5A),
            ),
            _AiMetricCard(
              label: 'Prediksi 30 Hari',
              value: _currency(bundle.forecastNext30Days),
              icon: Icons.show_chart_rounded,
              iconColor: const Color(0xFF20A029),
            ),
            _AiMetricCard(
              label: 'Hari Paling Sibuk',
              value: bundle.busiestDayLabel,
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFFFF8A1F),
            ),
            _AiMetricCard(
              label: 'Transaksi 30 Hari',
              value: '${bundle.transactions30d}',
              icon: Icons.receipt_long_outlined,
              iconColor: const Color(0xFF6D4CFF),
            ),
          ],
        ),
        _AiSectionCard(
          title: 'Arah Prediksi Penjualan',
          subtitle: 'Berdasarkan pola 7 hari terakhir',
          child: bundle.last7Days.every((item) => item.revenue == 0)
              ? const _AiEmptyChartLabel(
                  message: 'Belum ada pola penjualan yang bisa diproyeksikan.',
                )
              : _ForecastBarChart(metrics: bundle.last7Days),
        ),
        _AiSectionCard(
          title: 'Rencana Restock Prioritas',
          child: bundle.lowStockProducts.isEmpty
              ? Text(
                  'Tidak ada produk kritis. Stok utama masih aman.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF666666),
                  ),
                )
              : Column(
                  children: bundle.lowStockProducts
                      .map(
                        (item) => _AiStockTile(
                          title: item.name,
                          subtitle: item.category,
                          stock: item.stock,
                          price: _currency(item.price),
                        ),
                      )
                      .toList(),
                ),
        ),
        _AiSectionCard(
          title: 'AI Rencana Aksi',
          child: Column(
            children: bundle.predictionInsights
                .map((item) => _AiInsightTile(insight: item))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class BusinessHealthScorePage extends StatelessWidget {
  final bool embedded;

  const BusinessHealthScorePage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return _BusinessAiPageFrame(
      title: 'Business Health Score',
      embedded: embedded,
      builder: (bundle) => [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF19326D), Color(0xFF2D57C8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Health Summary',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _HealthScoreRing(score: bundle.healthScore),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      bundle.healthScore >= 75
                          ? 'Bisnis berada di zona sehat. Fokus berikutnya adalah menjaga konsistensi dan margin.'
                          : bundle.healthScore >= 55
                          ? 'Bisnis cukup stabil, tetapi masih ada area yang perlu diperkuat agar lebih tahan.'
                          : 'Bisnis butuh tindakan prioritas pada margin, stok, dan konsistensi penjualan.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.16,
          children: [
            _AiScoreCard(
              title: 'Konsistensi',
              score: bundle.salesConsistencyScore,
            ),
            _AiScoreCard(title: 'Margin', score: bundle.marginScore),
            _AiScoreCard(title: 'Inventori', score: bundle.inventoryScore),
            _AiScoreCard(title: 'Customer Value', score: bundle.customerScore),
          ],
        ),
        _AiSectionCard(
          title: 'AI Insight Kesehatan Bisnis',
          child: Column(
            children: bundle.healthInsights
                .map((item) => _AiInsightTile(insight: item))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _BusinessAiPageFrame extends StatelessWidget {
  final String title;
  final List<Widget> Function(BusinessAnalyticsBundle bundle) builder;
  final bool embedded;

  const _BusinessAiPageFrame({
    required this.title,
    required this.builder,
    required this.embedded,
  });

  Widget _buildBody() {
    return FutureBuilder<BusinessAnalyticsBundle>(
      future: BusinessAiService().loadBundle(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Center(
              key: ValueKey('error-$title'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat analisis AI.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const AnimatedSwitcher(
            duration: Duration(milliseconds: 220),
            child: Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(color: Color(0xFF162B5A)),
            ),
          );
        }

        final bundle = snapshot.data!;
        final sections = builder(bundle);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            key: ValueKey(
              '$title-${bundle.transactions30d}-${bundle.healthScore.toStringAsFixed(0)}',
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < sections.length; i++) ...[
                  _StaggeredReveal(index: i, child: sections[i]),
                  if (i != sections.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return ColoredBox(color: const Color(0xFFE7E7E7), child: _buildBody());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: Colors.black,
        ),
        titleSpacing: 0,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(height: 0.6, color: Colors.black),
        ),
      ),
      body: _buildBody(),
    );
  }
}

class _StaggeredReveal extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredReveal({required this.index, required this.child});

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.04),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _AiSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _AiSectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2D2D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: const Color(0xFF777777),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AiMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _AiMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2D2D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6F6F6F),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _AiInfoRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF2A2A2A),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightTile extends StatelessWidget {
  final BusinessAiInsight insight;

  const _AiInsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final accent = switch (insight.severity) {
      'high' => const Color(0xFFE45353),
      'medium' => const Color(0xFFFF8A1F),
      'good' => const Color(0xFF20A029),
      _ => const Color(0xFF4F75F2),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.45,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiScoreCard extends StatelessWidget {
  final String title;
  final double score;

  const _AiScoreCard({required this.title, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? const Color(0xFF20A029)
        : score >= 55
        ? const Color(0xFFFF8A1F)
        : const Color(0xFFE45353);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD2D2D2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                animatedScore.toStringAsFixed(0),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: animatedScore / 100,
                  backgroundColor: const Color(0xFFE6E6E6),
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HealthScoreRing extends StatelessWidget {
  final double score;

  const _HealthScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, child) {
        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: animatedScore / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    score >= 75
                        ? const Color(0xFF72F34F)
                        : score >= 55
                        ? const Color(0xFFFFD04B)
                        : const Color(0xFFFF7B7B),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    animatedScore.toStringAsFixed(0),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevenueProfitChart extends StatelessWidget {
  final List<BusinessDailyMetric> metrics;

  const _RevenueProfitChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: CustomPaint(
        painter: _RevenueProfitChartPainter(metrics: metrics),
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 6, bottom: 8),
          child: Column(
            children: [
              const Expanded(child: SizedBox()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: metrics
                    .map(
                      (item) => Text(
                        _shortDay(item.date),
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: const Color(0xFF8A8A8A),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForecastBarChart extends StatelessWidget {
  final List<BusinessDailyMetric> metrics;

  const _ForecastBarChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = metrics
        .map((item) => item.revenue)
        .fold<num>(0, (max, item) => item > max ? item : max);

    return Column(
      children: metrics.map((item) {
        final ratio = maxRevenue <= 0 ? 0.0 : item.revenue / maxRevenue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  _shortDay(item.date),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF666666),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: ratio.toDouble(),
                    backgroundColor: const Color(0xFFE6E6E6),
                    color: const Color(0xFFF58A2A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 74,
                child: Text(
                  _currency(item.revenue),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AiStockTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int stock;
  final String price;

  const _AiStockTile({
    required this.title,
    required this.subtitle,
    required this.stock,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: Color(0xFFFF8A1F),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Stok $stock',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: stock <= 5
                      ? const Color(0xFFE45353)
                      : const Color(0xFFFF8A1F),
                ),
              ),
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiEmptyChartLabel extends StatelessWidget {
  final String message;

  const _AiEmptyChartLabel({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF8A8A8A),
          ),
        ),
      ),
    );
  }
}

class _RevenueProfitChartPainter extends CustomPainter {
  final List<BusinessDailyMetric> metrics;

  const _RevenueProfitChartPainter({required this.metrics});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 24.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 22.0;
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    final maxValue = math.max<num>(
      metrics.map((item) => item.revenue).fold(0, math.max),
      metrics.map((item) => item.profit).fold(0, math.max),
    );
    final safeMax = maxValue <= 0 ? 1 : maxValue;

    final gridPaint = Paint()
      ..color = const Color(0xFFDADADA)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = topPad + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        gridPaint,
      );
    }

    final revenuePath = Path();
    final profitPath = Path();
    for (int i = 0; i < metrics.length; i++) {
      final x = leftPad + (chartWidth / (metrics.length - 1)) * i;
      final revenueY =
          topPad + chartHeight * (1 - (metrics[i].revenue / safeMax));
      final profitY =
          topPad + chartHeight * (1 - (metrics[i].profit / safeMax));

      if (i == 0) {
        revenuePath.moveTo(x, revenueY.toDouble());
        profitPath.moveTo(x, profitY.toDouble());
      } else {
        revenuePath.lineTo(x, revenueY.toDouble());
        profitPath.lineTo(x, profitY.toDouble());
      }
    }

    final revenuePaint = Paint()
      ..color = const Color(0xFFF58A2A)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final profitPaint = Paint()
      ..color = const Color(0xFF4F75F2)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(revenuePath, revenuePaint);
    canvas.drawPath(profitPath, profitPaint);
  }

  @override
  bool shouldRepaint(covariant _RevenueProfitChartPainter oldDelegate) {
    return oldDelegate.metrics != metrics;
  }
}

String _currency(num value) {
  final raw = value.round().toString();
  final formatted = raw.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $formatted';
}

String _shortDay(DateTime date) {
  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  return days[date.weekday - 1];
}
