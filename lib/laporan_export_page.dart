import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'business_ai_service.dart';
import 'firestore_scope.dart';

enum ReportPeriod { today, last7Days, last30Days, all }

class LaporanExportPage extends StatefulWidget {
  final bool embedded;

  const LaporanExportPage({super.key, this.embedded = false});

  @override
  State<LaporanExportPage> createState() => _LaporanExportPageState();
}

class _LaporanExportPageState extends State<LaporanExportPage> {
  late final Future<FirestoreScope?> _scopeFuture;
  late final Future<BusinessAnalyticsBundle> _bundleFuture;
  ReportPeriod _selectedPeriod = ReportPeriod.last7Days;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _scopeFuture = resolveCurrentFirestoreScope();
    _bundleFuture = BusinessAiService().loadBundle();
  }

  DateTime _periodStart(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedPeriod) {
      case ReportPeriod.today:
        return today;
      case ReportPeriod.last7Days:
        return today.subtract(const Duration(days: 6));
      case ReportPeriod.last30Days:
        return today.subtract(const Duration(days: 29));
      case ReportPeriod.all:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<void> _copySummary(_ReportSnapshot snapshot) async {
    final summary = [
      'Laporan SmartLaba - ${_periodLabel(_selectedPeriod)}',
      'Omzet: ${_formatCurrency(snapshot.totalRevenue)}',
      'Laba: ${_formatCurrency(snapshot.totalProfit)}',
      'Transaksi: ${snapshot.sales.length}',
      'Avg Ticket: ${_formatCurrency(snapshot.averageTicket)}',
      'Metode Teratas: ${snapshot.topPaymentMethod}',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ringkasan laporan berhasil disalin.',
          style: GoogleFonts.poppins(fontSize: 12.5),
        ),
      ),
    );
  }

  Future<void> _exportCsv(_ReportSnapshot snapshot) async {
    if (_isExporting || snapshot.sales.isEmpty) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      final csv = _buildCsv(snapshot);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'laporan_smartlaba_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Laporan SmartLaba',
        text: 'Laporan ${_periodLabel(_selectedPeriod)}',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File CSV siap diexport.',
            style: GoogleFonts.poppins(fontSize: 12.5),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          content: Text(
            'Gagal export laporan: $error',
            style: GoogleFonts.poppins(fontSize: 12.5),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _buildCsv(_ReportSnapshot snapshot) {
    final lines = <String>[
      [
        'Tanggal',
        'Struk',
        'Kasir',
        'Metode',
        'Total',
        'Laba',
        'Store ID',
      ].map(_csvCell).join(','),
    ];

    for (final sale in snapshot.sales) {
      lines.add(
        [
          sale.createdAt == null ? '-' : _formatDateTime(sale.createdAt!),
          sale.receiptLabel,
          sale.cashierName,
          sale.paymentMethod,
          sale.total.round().toString(),
          sale.profit.round().toString(),
          sale.storeId,
        ].map(_csvCell).join(','),
      );
    }

    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      final body = const _ReportStateMessage(
        icon: Icons.person_off_outlined,
        title: 'User tidak ditemukan',
        message: 'Silakan login ulang untuk membuka laporan.',
        iconColor: Colors.redAccent,
      );
      if (widget.embedded) {
        return ColoredBox(color: const Color(0xFFE7E7E7), child: body);
      }
      return Scaffold(
        backgroundColor: const Color(0xFFE7E7E7),
        appBar: _buildAppBar(),
        body: body,
      );
    }

    final body = FutureBuilder<FirestoreScope?>(
      future: _scopeFuture,
      builder: (context, scopeSnapshot) {
        if (scopeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF162B5A)),
          );
        }

        final scope = scopeSnapshot.data;
        if (scope == null) {
          return const _ReportStateMessage(
            icon: Icons.store_mall_directory_outlined,
            title: 'Scope toko tidak ditemukan',
            message:
                'Pilih toko aktif terlebih dahulu sebelum membuka laporan.',
            iconColor: Colors.redAccent,
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ReportStateMessage(
                icon: Icons.error_outline_rounded,
                title: 'Gagal memuat laporan',
                message:
                    'Periksa koneksi atau aturan Firestore.\n${snapshot.error}',
                iconColor: Colors.redAccent,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF162B5A)),
              );
            }

            final scopedSales =
                (snapshot.data?.docs ?? const [])
                    .map(_ReportSale.fromDocument)
                    .where(
                      (sale) => _matchesReportScope(sale: sale, scope: scope),
                    )
                    .toList()
                  ..sort(
                    (a, b) =>
                        (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                            .compareTo(
                              a.createdAt ??
                                  DateTime.fromMillisecondsSinceEpoch(0),
                            ),
                  );

            final now = DateTime.now();
            final start = _periodStart(now);
            final filteredSales = _selectedPeriod == ReportPeriod.all
                ? scopedSales
                : scopedSales
                      .where(
                        (sale) =>
                            sale.createdAt != null &&
                            !sale.createdAt!.isBefore(start),
                      )
                      .toList();
            final reportSnapshot = _ReportSnapshot.fromSales(filteredSales);

            return FutureBuilder<BusinessAnalyticsBundle>(
              future: _bundleFuture,
              builder: (context, bundleSnapshot) {
                final bundle = bundleSnapshot.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReportFilterBar(
                        selectedPeriod: _selectedPeriod,
                        onSelected: (period) {
                          setState(() => _selectedPeriod = period);
                        },
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
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
                        child: Column(
                          key: ValueKey(
                            '${_selectedPeriod.name}-${reportSnapshot.sales.length}-${reportSnapshot.totalRevenue}',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ReportReveal(
                              index: 0,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxWidth = constraints.maxWidth;
                                  final crossAxisCount = maxWidth >= 960
                                      ? 4
                                      : maxWidth >= 680
                                      ? 2
                                      : 2;
                                  final childAspectRatio = maxWidth >= 960
                                      ? 1.55
                                      : 1.18;

                                  return GridView.count(
                                    crossAxisCount: crossAxisCount,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: childAspectRatio,
                                    children: [
                                      _ReportMetricCard(
                                        label: 'Omzet',
                                        value: _formatCurrency(
                                          reportSnapshot.totalRevenue,
                                        ),
                                        icon: Icons.payments_outlined,
                                        iconColor: const Color(0xFF162B5A),
                                      ),
                                      _ReportMetricCard(
                                        label: 'Laba',
                                        value: _formatCurrency(
                                          reportSnapshot.totalProfit,
                                        ),
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                        iconColor: const Color(0xFF20A029),
                                      ),
                                      _ReportMetricCard(
                                        label: 'Transaksi',
                                        value: '${reportSnapshot.sales.length}',
                                        icon: Icons.receipt_long_outlined,
                                        iconColor: const Color(0xFFFF8A1F),
                                      ),
                                      _ReportMetricCard(
                                        label: 'Avg Ticket',
                                        value: _formatCurrency(
                                          reportSnapshot.averageTicket,
                                        ),
                                        icon: Icons.shopping_bag_outlined,
                                        iconColor: const Color(0xFF4F75F2),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 1,
                              child: _buildBusinessSummaryCard(
                                reportSnapshot,
                                bundle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 2,
                              child: _buildProfitBusinessCard(
                                reportSnapshot,
                                bundle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 3,
                              child: _buildProductReportCard(
                                reportSnapshot,
                                bundle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 4,
                              child: _buildTrendChartsCard(bundle),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 5,
                              child: _buildPieChartCard(reportSnapshot),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 6,
                              child: _buildAiAnalysisCard(bundle),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 7,
                              child: _buildExportCard(reportSnapshot),
                            ),
                            const SizedBox(height: 12),
                            _ReportReveal(
                              index: 8,
                              child: _buildHistoryCard(reportSnapshot),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    if (widget.embedded) {
      return ColoredBox(color: const Color(0xFFE7E7E7), child: body);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      appBar: _buildAppBar(),
      body: body,
    );
  }

  Widget _buildBusinessSummaryCard(
    _ReportSnapshot reportSnapshot,
    BusinessAnalyticsBundle? bundle,
  ) {
    return _ReportSectionCard(
      title: 'Laporan Ringkasan Bisnis',
      subtitle:
          'Ringkasan performa bisnis, forecast, dan status operasional toko aktif.',
      child: Column(
        children: [
          _ReportInfoRow(
            label: 'Margin Laba',
            value: '${reportSnapshot.marginPercent.toStringAsFixed(1)}%',
          ),
          _ReportInfoRow(
            label: 'Metode Bayar Dominan',
            value: reportSnapshot.topPaymentMethod,
          ),
          _ReportInfoRow(
            label: 'Hari Teramai',
            value: bundle?.busiestDayLabel ?? '-',
          ),
          _ReportInfoRow(
            label: 'Forecast 7 Hari',
            value: bundle == null
                ? '-'
                : _formatCurrency(bundle.forecastNext7Days),
          ),
          _ReportInfoRow(
            label: 'Skor Health',
            value: bundle == null ? '-' : bundle.healthScore.toStringAsFixed(0),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitBusinessCard(
    _ReportSnapshot reportSnapshot,
    BusinessAnalyticsBundle? bundle,
  ) {
    return _ReportSectionCard(
      title: 'Laporan Laba Usaha',
      subtitle:
          'Lihat omzet, laba, margin, dan kualitas profit usaha pada periode terpilih.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: 'Omzet',
                  value: _formatCurrency(reportSnapshot.totalRevenue),
                  accentColor: const Color(0xFF162B5A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  label: 'Laba',
                  value: _formatCurrency(reportSnapshot.totalProfit),
                  accentColor: const Color(0xFF20A029),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  label: 'Margin',
                  value: '${reportSnapshot.marginPercent.toStringAsFixed(1)}%',
                  accentColor: const Color(0xFFFF8A1F),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  label: 'AOV 30 Hari',
                  value: bundle == null
                      ? '-'
                      : _formatCurrency(bundle.averageOrderValue),
                  accentColor: const Color(0xFF4F75F2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductReportCard(
    _ReportSnapshot reportSnapshot,
    BusinessAnalyticsBundle? bundle,
  ) {
    return _ReportSectionCard(
      title: 'Laporan Produk',
      subtitle:
          'Produk paling laris di periode ini dan daftar produk yang perlu restock.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produk Teratas',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 10),
          if (reportSnapshot.topProducts.isEmpty)
            _buildMutedText(
              'Belum ada detail produk dari transaksi periode ini.',
            )
          else
            ...reportSnapshot.topProducts
                .take(5)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ProductReportRow(
                      name: product.name,
                      quantityLabel: '${product.quantity} terjual',
                      valueLabel: _formatCurrency(product.revenue),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          Text(
            'Stok Perlu Dipantau',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 10),
          if (bundle == null || bundle.lowStockProducts.isEmpty)
            _buildMutedText('Belum ada produk low stock yang terdeteksi.')
          else
            ...bundle.lowStockProducts
                .take(5)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ProductReportRow(
                      name: product.name,
                      quantityLabel: 'Stok ${product.stock}',
                      valueLabel: product.category,
                      warning: true,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTrendChartsCard(BusinessAnalyticsBundle? bundle) {
    return _ReportSectionCard(
      title: 'Grafik Omzet & Laba',
      subtitle:
          'Pergerakan omzet dan laba 7 hari terakhir dari toko yang sedang aktif.',
      child: Column(
        children: [
          _ChartCard(
            title: 'Grafik Omzet',
            chartColor: const Color(0xFF162B5A),
            metrics: bundle?.last7Days ?? const [],
            selector: (metric) => metric.revenue,
            emptyMessage: 'Belum ada data omzet untuk digrafikkan.',
          ),
          const SizedBox(height: 12),
          _ChartCard(
            title: 'Grafik Laba',
            chartColor: const Color(0xFF20A029),
            metrics: bundle?.last7Days ?? const [],
            selector: (metric) => metric.profit,
            emptyMessage: 'Belum ada data laba untuk digrafikkan.',
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(_ReportSnapshot reportSnapshot) {
    return _ReportSectionCard(
      title: 'Pie Chart Metode Pembayaran',
      subtitle:
          'Komposisi transaksi berdasarkan metode pembayaran pada periode terpilih.',
      child: reportSnapshot.paymentBreakdown.isEmpty
          ? _buildMutedText(
              'Belum ada distribusi pembayaran untuk ditampilkan.',
            )
          : _PaymentPieSection(
              paymentBreakdown: reportSnapshot.paymentBreakdown,
            ),
    );
  }

  Widget _buildAiAnalysisCard(BusinessAnalyticsBundle? bundle) {
    final insights = bundle == null
        ? const <BusinessAiInsight>[]
        : [
            ...bundle.financeInsights,
            ...bundle.predictionInsights,
            ...bundle.healthInsights,
          ];

    return _ReportSectionCard(
      title: 'Laporan Analisis AI',
      subtitle:
          'Insight AI untuk keuangan, prediksi, dan kesehatan bisnis dari toko aktif.',
      child: insights.isEmpty
          ? _buildMutedText('Insight AI belum tersedia untuk data saat ini.')
          : Column(
              children: insights.take(6).map((insight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AiInsightTile(insight: insight),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMutedText(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: const Color(0xFF777777),
        ),
      ),
    );
  }

  Widget _buildExportCard(_ReportSnapshot reportSnapshot) {
    return _ReportSectionCard(
      title: 'Export Laporan',
      subtitle: 'Bagikan laporan CSV atau salin ringkasan cepat.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reportSnapshot.sales.isEmpty
                      ? null
                      : () => _copySummary(reportSnapshot),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: Color(0xFF162B5A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.content_copy_rounded,
                    size: 18,
                    color: Color(0xFF162B5A),
                  ),
                  label: Text(
                    'Salin Ringkasan',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF162B5A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: reportSnapshot.sales.isEmpty || _isExporting
                      ? null
                      : () => _exportCsv(reportSnapshot),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0xFF162B5A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.ios_share_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isExporting ? 'Menyiapkan...' : 'Export CSV',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReportInfoRow(
            label: 'Metode Bayar Teratas',
            value: reportSnapshot.topPaymentMethod,
          ),
          _ReportInfoRow(
            label: 'Periode',
            value: _periodLabel(_selectedPeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(_ReportSnapshot reportSnapshot) {
    return _ReportSectionCard(
      title: 'Laporan Penjualan',
      subtitle: 'Riwayat penjualan pada periode yang dipilih.',
      child: reportSnapshot.sales.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: _ReportStateMessage(
                icon: Icons.description_outlined,
                title: 'Belum ada data laporan',
                message:
                    'Transaksi pada periode yang dipilih akan tampil di sini.',
                iconColor: Color(0xFFFF8A1F),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reportSnapshot.sales.length > 20
                  ? 20
                  : reportSnapshot.sales.length,
              separatorBuilder: (_, __) => Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 0.6,
                color: const Color(0xFFD0D0D0),
              ),
              itemBuilder: (context, index) {
                final sale = reportSnapshot.sales[index];
                return _ReportSaleTile(sale: sale);
              },
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: Colors.black,
      ),
      titleSpacing: 0,
      title: Text(
        'Laporan & Export',
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
    );
  }
}

class _ReportFilterBar extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final ValueChanged<ReportPeriod> onSelected;

  const _ReportFilterBar({
    required this.selectedPeriod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ReportPeriod.values.map((period) {
          final selected = selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              showCheckmark: false,
              label: Text(
                _periodLabel(period),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF162B5A)
                      : const Color(0xFF666666),
                ),
              ),
              selectedColor: const Color(0xFFE7EEF9),
              backgroundColor: const Color(0xFFF7F7F7),
              side: const BorderSide(color: Color(0xFFD2D2D2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (_) => onSelected(period),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ReportSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReportReveal extends StatefulWidget {
  final int index;
  final Widget child;

  const _ReportReveal({required this.index, required this.child});

  @override
  State<_ReportReveal> createState() => _ReportRevealState();
}

class _ReportRevealState extends State<_ReportReveal> {
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

class _ReportMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ReportMetricCard({
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

class _ReportInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A2A2A),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductReportRow extends StatelessWidget {
  final String name;
  final String quantityLabel;
  final String valueLabel;
  final bool warning;

  const _ProductReportRow({
    required this.name,
    required this.quantityLabel,
    required this.valueLabel,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quantityLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valueLabel,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: warning
                  ? const Color(0xFFE45353)
                  : const Color(0xFF162B5A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Color chartColor;
  final List<BusinessDailyMetric> metrics;
  final num Function(BusinessDailyMetric metric) selector;
  final String emptyMessage;

  const _ChartCard({
    required this.title,
    required this.chartColor,
    required this.metrics,
    required this.selector,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = metrics.any((item) => selector(item) > 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
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
          const SizedBox(height: 10),
          if (!hasData)
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF777777),
              ),
            )
          else ...[
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _BarChartPainter(
                  values: metrics.map(selector).toList(),
                  color: chartColor,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: metrics.map((metric) {
                return Expanded(
                  child: Text(
                    _shortMonthDayLabel(metric.date),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF7A7A7A),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentPieSection extends StatelessWidget {
  final Map<String, int> paymentBreakdown;

  const _PaymentPieSection({required this.paymentBreakdown});

  @override
  Widget build(BuildContext context) {
    final entries = paymentBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(
      0,
      (currentTotal, entry) => currentTotal + entry.value,
    );
    final colors = _pieColors;
    final isCompact = MediaQuery.sizeOf(context).width < 430;

    return isCompact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _PieChartPainter(
                      values: entries
                          .map((entry) => entry.value.toDouble())
                          .toList(),
                      colors: List.generate(
                        entries.length,
                        (index) => colors[index % colors.length],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...entries.asMap().entries.map((entry) {
                final color = colors[entry.key % colors.length];
                final percent = total == 0
                    ? 0
                    : (entry.value.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.key,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF2A2A2A),
                          ),
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF162B5A),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    values: entries
                        .map((entry) => entry.value.toDouble())
                        .toList(),
                    colors: List.generate(
                      entries.length,
                      (index) => colors[index % colors.length],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: entries.asMap().entries.map((entry) {
                    final color = colors[entry.key % colors.length];
                    final percent = total == 0
                        ? 0
                        : (entry.value.value / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value.key,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF2A2A2A),
                              ),
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF162B5A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
  }
}

class _AiInsightTile extends StatelessWidget {
  final BusinessAiInsight insight;

  const _AiInsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _aiSeverityColor(insight.severity);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_aiSeverityIcon(insight.severity), color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
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

class _ReportSaleTile extends StatelessWidget {
  final _ReportSale sale;

  const _ReportSaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final createdAt = sale.createdAt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                createdAt == null
                    ? '--'
                    : createdAt.day.toString().padLeft(2, '0'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                createdAt == null ? '-' : _shortMonthLabel(createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      sale.receiptLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A2A2A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ReportPaymentChip(method: sale.paymentMethod),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Kasir: ${sale.cashierName}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF7A7A7A),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatCurrency(sale.total),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF162B5A),
                      ),
                    ),
                  ),
                  Text(
                    'Laba ${_formatCurrency(sale.profit)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF20A029),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportPaymentChip extends StatelessWidget {
  final String method;

  const _ReportPaymentChip({required this.method});

  @override
  Widget build(BuildContext context) {
    final color = _paymentChipColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        method.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ReportStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

  const _ReportStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF7A7A7A),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<num> values;
  final Color color;

  const _BarChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxValue <= 0) {
      return;
    }

    const horizontalGap = 10.0;
    final chartHeight = size.height - 12;
    final barWidth =
        (size.width - (horizontalGap * (values.length - 1))) / values.length;
    final basePaint = Paint()
      ..color = const Color(0xFFE9EDF5)
      ..style = PaintingStyle.fill;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var index = 0; index < values.length; index++) {
      final x = index * (barWidth + horizontalGap);
      final value = values[index].toDouble();
      final normalizedHeight = (value / maxValue) * chartHeight;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, chartHeight),
        const Radius.circular(10),
      );
      canvas.drawRRect(barRect, basePaint);

      final valueRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          chartHeight - normalizedHeight,
          barWidth,
          normalizedHeight,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(valueRect, valuePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final total = values.fold<double>(
      0,
      (currentTotal, value) => currentTotal + value,
    );
    if (total <= 0) {
      return;
    }

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );
    var startAngle = -1.5708;

    for (var index = 0; index < values.length; index++) {
      final sweepAngle = (values[index] / total) * 6.28318;
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    final innerPaint = Paint()
      ..color = const Color(0xFFF7F7F7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.22,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class _ReportSnapshot {
  final List<_ReportSale> sales;
  final num totalRevenue;
  final num totalProfit;
  final double averageTicket;
  final double marginPercent;
  final String topPaymentMethod;
  final Map<String, int> paymentBreakdown;
  final List<_ReportProductSummary> topProducts;

  const _ReportSnapshot({
    required this.sales,
    required this.totalRevenue,
    required this.totalProfit,
    required this.averageTicket,
    required this.marginPercent,
    required this.topPaymentMethod,
    required this.paymentBreakdown,
    required this.topProducts,
  });

  factory _ReportSnapshot.fromSales(List<_ReportSale> sales) {
    final totalRevenue = sales.fold<num>(
      0,
      (totalAmount, sale) => totalAmount + sale.total,
    );
    final totalProfit = sales.fold<num>(
      0,
      (totalProfitAmount, sale) => totalProfitAmount + sale.profit,
    );
    final double averageTicket = sales.isEmpty
        ? 0
        : totalRevenue.toDouble() / sales.length;
    final double marginPercent = totalRevenue <= 0
        ? 0
        : (totalProfit.toDouble() / totalRevenue.toDouble()) * 100;
    final paymentCounts = <String, int>{};
    final productBuckets = <String, _ReportProductSummaryAccumulator>{};
    for (final sale in sales) {
      paymentCounts.update(
        sale.paymentMethod,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      for (final item in sale.items) {
        final normalizedName = item.name.trim();
        if (normalizedName.isEmpty) {
          continue;
        }

        final bucket = productBuckets.putIfAbsent(
          normalizedName.toLowerCase(),
          () => _ReportProductSummaryAccumulator(name: normalizedName),
        );
        bucket.quantity += item.quantity;
        bucket.revenue += item.revenue;
      }
    }

    final topPaymentMethod = paymentCounts.entries.isEmpty
        ? '-'
        : (paymentCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    final topProducts = productBuckets.values.toList()
      ..sort((a, b) {
        final quantityCompare = b.quantity.compareTo(a.quantity);
        if (quantityCompare != 0) {
          return quantityCompare;
        }
        return b.revenue.compareTo(a.revenue);
      });

    return _ReportSnapshot(
      sales: sales,
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      averageTicket: averageTicket,
      marginPercent: marginPercent,
      topPaymentMethod: topPaymentMethod,
      paymentBreakdown: paymentCounts,
      topProducts: topProducts
          .map(
            (product) => _ReportProductSummary(
              name: product.name,
              quantity: product.quantity,
              revenue: product.revenue,
            ),
          )
          .toList(),
    );
  }
}

class _ReportProductSummary {
  final String name;
  final int quantity;
  final num revenue;

  const _ReportProductSummary({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

class _ReportProductSummaryAccumulator {
  final String name;
  int quantity = 0;
  num revenue = 0;

  _ReportProductSummaryAccumulator({required this.name});
}

class _ReportSale {
  final String id;
  final num total;
  final num profit;
  final DateTime? createdAt;
  final String receiptLabel;
  final String paymentMethod;
  final String cashierName;
  final String storeId;
  final String ownerUid;
  final List<_ReportSaleItem> items;

  const _ReportSale({
    required this.id,
    required this.total,
    required this.profit,
    required this.createdAt,
    required this.receiptLabel,
    required this.paymentMethod,
    required this.cashierName,
    required this.storeId,
    required this.ownerUid,
    required this.items,
  });

  factory _ReportSale.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _ReportSale(
      id: doc.id,
      total: _readNumber(data, const ['total', 'grandTotal', 'amount']),
      profit: _readNumber(data, const ['laba', 'profit']),
      createdAt: _readDate(data, const [
        'createdAt',
        'timestamp',
        'tanggal',
        'transactionDate',
        'date',
      ]),
      receiptLabel: _readString(data, const [
        'nomorStruk',
        'receiptNumber',
        'invoiceNumber',
        'struk',
      ], fallback: _fallbackReceiptLabel(doc.id)),
      paymentMethod: _readString(data, const [
        'paymentMethod',
        'metodePembayaran',
        'metode',
        'payment',
      ], fallback: 'Tunai'),
      cashierName: _readString(data, const [
        'kasir',
        'cashierName',
        'namaKasir',
        'createdByName',
      ], fallback: 'Tidak diketahui'),
      storeId: _readString(data, const ['storeId'], fallback: ''),
      ownerUid: _readString(data, const ['ownerUid'], fallback: ''),
      items: _readItemMaps(data)
          .map(_ReportSaleItem.fromMap)
          .where((item) => item.name.isNotEmpty)
          .toList(),
    );
  }
}

class _ReportSaleItem {
  final String name;
  final int quantity;
  final num revenue;

  const _ReportSaleItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  factory _ReportSaleItem.fromMap(Map<String, dynamic> data) {
    final quantity = _readNumber(data, const [
      'qty',
      'quantity',
      'jumlah',
      'count',
    ]).round();
    final subtotal = _readNumber(data, const ['subtotal', 'total', 'amount']);
    final unitPrice = _readNumber(data, const ['hargaJual', 'price', 'harga']);
    final normalizedQty = quantity <= 0 ? 1 : quantity;

    return _ReportSaleItem(
      name: _readString(data, const [
        'namaProduk',
        'productName',
        'name',
        'nama',
        'title',
      ], fallback: ''),
      quantity: normalizedQty,
      revenue: subtotal > 0
          ? subtotal
          : (unitPrice > 0 ? unitPrice * normalizedQty : normalizedQty),
    );
  }
}

bool _matchesReportScope({
  required _ReportSale sale,
  required FirestoreScope scope,
}) {
  return matchesStoreScopedRecord(
    recordOwnerUid: sale.ownerUid,
    recordStoreId: sale.storeId,
    scope: scope,
    includeLegacyOwnerFallback: true,
  );
}

String _periodLabel(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.today:
      return 'Hari Ini';
    case ReportPeriod.last7Days:
      return '7 Hari';
    case ReportPeriod.last30Days:
      return '30 Hari';
    case ReportPeriod.all:
      return 'Semua';
  }
}

String _formatCurrency(num value) {
  final raw = value.round().toString();
  final formatted = raw.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $formatted';
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String _shortMonthLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return months[date.month - 1];
}

Color _paymentChipColor(String paymentMethod) {
  final normalized = paymentMethod.trim().toLowerCase();
  if (normalized.contains('tunai') || normalized.contains('cash')) {
    return const Color(0xFFE45353);
  }
  if (normalized.contains('qris') ||
      normalized.contains('debit') ||
      normalized.contains('kartu') ||
      normalized.contains('transfer')) {
    return const Color(0xFF2563EB);
  }
  return const Color(0xFF7C3AED);
}

String _fallbackReceiptLabel(String docId) {
  final shortId = docId.length > 6 ? docId.substring(0, 6) : docId;
  return 'Struk ${shortId.toUpperCase()}';
}

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
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

String _shortMonthDayLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${_shortMonthLabel(date)}';
}

IconData _aiSeverityIcon(String severity) {
  switch (severity) {
    case 'high':
      return Icons.error_outline_rounded;
    case 'medium':
      return Icons.lightbulb_outline_rounded;
    case 'good':
      return Icons.trending_up_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

Color _aiSeverityColor(String severity) {
  switch (severity) {
    case 'high':
      return const Color(0xFFE45353);
    case 'medium':
      return const Color(0xFFFF8A1F);
    case 'good':
      return const Color(0xFF20A029);
    default:
      return const Color(0xFF4F75F2);
  }
}

const _pieColors = [
  Color(0xFF162B5A),
  Color(0xFFFF8A1F),
  Color(0xFF20A029),
  Color(0xFF4F75F2),
  Color(0xFF7C3AED),
];
