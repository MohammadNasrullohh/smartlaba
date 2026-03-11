import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_transitions.dart';
import 'akun_page.dart';
import 'auth_service.dart';
import 'business_ai_pages.dart';
import 'dashboard.dart';
import 'firestore_scope.dart';
import 'laporan_export_page.dart';
import 'login_page.dart';
import 'manajemen_produk_page.dart';
import 'manajemen_user_page.dart';
import 'user_service.dart';

enum _SalesPeriod { daily, last7Days, last30Days, all }

class PenjualanPage extends StatelessWidget {
  final bool embedded;

  const PenjualanPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return const PenjualanContent();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      drawer: const _PenjualanDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF162B5A)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Penjualan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        toolbarHeight: 64,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: const Color(0xFF4D4D4F),
            height: 0.5,
            width: double.infinity,
          ),
        ),
      ),
      body: const PenjualanContent(),
    );
  }
}

class PenjualanContent extends StatefulWidget {
  const PenjualanContent({super.key});

  @override
  State<PenjualanContent> createState() => _PenjualanContentState();
}

class _PenjualanContentState extends State<PenjualanContent> {
  late final Future<FirestoreScope?> _scopeFuture;
  final TextEditingController _searchController = TextEditingController();
  _SalesPeriod _selectedPeriod = _SalesPeriod.daily;
  String? _selectedDateKey;

  @override
  void initState() {
    super.initState();
    _scopeFuture = resolveCurrentFirestoreScope();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SalesRecord> _filterSalesByPeriod(
    List<_SalesRecord> sales,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedPeriod) {
      case _SalesPeriod.daily:
        return sales
            .where(
              (sale) =>
                  sale.createdAt != null && _isSameDay(sale.createdAt!, today),
            )
            .toList();
      case _SalesPeriod.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return sales
            .where(
              (sale) =>
                  sale.createdAt != null && !sale.createdAt!.isBefore(start),
            )
            .toList();
      case _SalesPeriod.last30Days:
        final start = today.subtract(const Duration(days: 29));
        return sales
            .where(
              (sale) =>
                  sale.createdAt != null && !sale.createdAt!.isBefore(start),
            )
            .toList();
      case _SalesPeriod.all:
        return sales;
    }
  }

  List<String> _buildAvailableDateKeys(List<_SalesRecord> sales) {
    final keys = <String>[];
    for (final sale in sales) {
      if (sale.createdAt == null) {
        continue;
      }
      final key = _dateKey(sale.createdAt!);
      if (!keys.contains(key)) {
        keys.add(key);
      }
    }
    return keys;
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4D4D4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFC3C3C3), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Cari Nomor Struk',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFFC3C3C3),
                ),
              ),
            ),
          ),
          if (_searchController.text.trim().isNotEmpty)
            InkWell(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF9B9B9B),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required List<String> availableDateKeys,
    required String? selectedDateKey,
  }) {
    return Row(
      children: [
        Expanded(
          child: _SalesDropdown<_SalesPeriod>(
            value: _selectedPeriod,
            items: const [
              DropdownMenuItem(
                value: _SalesPeriod.daily,
                child: Text('Periode Harian'),
              ),
              DropdownMenuItem(
                value: _SalesPeriod.last7Days,
                child: Text('7 Hari Terakhir'),
              ),
              DropdownMenuItem(
                value: _SalesPeriod.last30Days,
                child: Text('30 Hari Terakhir'),
              ),
              DropdownMenuItem(
                value: _SalesPeriod.all,
                child: Text('Semua Data'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedPeriod = value;
                _selectedDateKey = null;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SalesDropdown<String>(
            value: selectedDateKey,
            hint: 'Semua Tanggal',
            items: [
              const DropdownMenuItem<String>(
                value: '__all__',
                child: Text('Semua Tanggal'),
              ),
              ...availableDateKeys.map(
                (key) => DropdownMenuItem<String>(
                  value: key,
                  child: Text(_readableDateFromKey(key)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedDateKey = value == null || value == '__all__'
                    ? null
                    : value;
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const _SalesStatusState(
        icon: Icons.person_off_outlined,
        title: 'User tidak ditemukan',
        message: 'Silakan login ulang untuk membuka data penjualan.',
        iconColor: Colors.redAccent,
      );
    }

    return FutureBuilder<FirestoreScope?>(
      future: _scopeFuture,
      builder: (context, scopeSnapshot) {
        if (scopeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF162B5A)),
          );
        }

        final scope = scopeSnapshot.data;
        if (scope == null) {
          return const _SalesStatusState(
            icon: Icons.store_mall_directory_outlined,
            title: 'Scope toko tidak ditemukan',
            message:
                'Pilih toko aktif terlebih dahulu sebelum membuka penjualan.',
            iconColor: Colors.redAccent,
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _SalesStatusState(
                icon: Icons.error_outline_rounded,
                title: 'Gagal memuat data penjualan',
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
                    .map(_SalesRecord.fromDocument)
                    .where(
                      (sale) => _matchesSalesScope(sale: sale, scope: scope),
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
            final todaySales = scopedSales
                .where(
                  (sale) =>
                      sale.createdAt != null &&
                      _isSameDay(sale.createdAt!, now),
                )
                .toList();

            final totalPendapatan = todaySales.fold<num>(
              0,
              (runningTotal, sale) => runningTotal + sale.total,
            );

            final periodSales = _filterSalesByPeriod(scopedSales, now);
            final availableDateKeys = _buildAvailableDateKeys(periodSales);
            final selectedDateKey = availableDateKeys.contains(_selectedDateKey)
                ? _selectedDateKey
                : (availableDateKeys.isNotEmpty
                      ? availableDateKeys.first
                      : null);
            final filteredSales = periodSales.where((sale) {
              final matchesDate =
                  selectedDateKey == null ||
                  sale.createdAt == null ||
                  _dateKey(sale.createdAt!) == selectedDateKey;
              final query = _searchController.text.trim().toLowerCase();
              final matchesQuery =
                  query.isEmpty ||
                  sale.receiptLabel.toLowerCase().contains(query) ||
                  sale.cashierName.toLowerCase().contains(query);
              return matchesDate && matchesQuery;
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? 12.0
                    : 16.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SalesSummaryCard(
                              icon: Icons.attach_money_rounded,
                              iconBackground: const Color(0xFF1B2C5D),
                              iconColor: Colors.white,
                              value: _formatCurrency(totalPendapatan),
                              label: 'Pendapatan Hari Ini',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SalesSummaryCard(
                              icon: Icons.shopping_bag_outlined,
                              iconBackground: const Color(0xFFFF8A1F),
                              iconColor: Colors.white,
                              value: '${todaySales.length}',
                              label: 'Transaksi',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          'Riwayat Penjualan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF4A5A8F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      _buildFilterRow(
                        availableDateKeys: availableDateKeys,
                        selectedDateKey: selectedDateKey,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD5D5D5)),
                          ),
                          child: todaySales.isEmpty
                              ? const _SalesStatusState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Belum ada penjualan hari ini',
                                  message:
                                      'Transaksi yang masuk hari ini akan tampil di sini.',
                                  iconColor: Color(0xFFFF8A1F),
                                )
                              : filteredSales.isEmpty
                              ? const _SalesStatusState(
                                  icon: Icons.search_off_rounded,
                                  title: 'Data tidak ditemukan',
                                  message:
                                      'Coba ubah pencarian atau filter tanggal transaksi.',
                                  iconColor: Color(0xFF4A5A8F),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredSales.length,
                                  separatorBuilder: (_, __) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    height: 0.6,
                                    color: const Color(0xFFD0D0D0),
                                  ),
                                  itemBuilder: (context, index) {
                                    return _SalesHistoryCard(
                                      sale: filteredSales[index],
                                    );
                                  },
                                ),
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
  }
}

class _SalesSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;

  const _SalesSummaryCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
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
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: const Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: const Color(0xFF6F6F6F),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesHistoryCard extends StatelessWidget {
  final _SalesRecord sale;

  const _SalesHistoryCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final paymentColor = _paymentChipColor(sale.paymentMethod);
    final createdAt = sale.createdAt;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            buildSmoothRoute(_SalesReceiptPage(sale: sale)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(dateTime: createdAt),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              sale.receiptLabel,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 10.5,
                                color: const Color(0xFF7E7E7E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PaymentChip(
                            paymentColor: paymentColor,
                            paymentMethod: sale.paymentMethod,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              _formatCurrency(sale.total),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: const Color(0xFF20A029),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Kasir : ${sale.cashierName}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                                color: const Color(0xFF5C5C5C),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final Color paymentColor;
  final String paymentMethod;

  const _PaymentChip({required this.paymentColor, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: paymentColor.withValues(alpha: 0.9)),
      ),
      child: Text(
        paymentMethod.toUpperCase(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 8.5,
          color: paymentColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime? dateTime;

  const _DateBadge({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final date = dateTime;

    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A1F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            date == null ? '--' : date.day.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date == null ? '-' : _monthYearLabel(date),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 7,
              color: const Color(0xFF111111),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            date == null ? '--:--' : _timeLabel(date),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 7,
              color: const Color(0xFF4B2B00),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SalesDropdown({
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4D4D4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint ?? '',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF9B9B9B),
          ),
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: const Color(0xFF4D4D4F),
          ),
          borderRadius: BorderRadius.circular(16),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SalesReceiptPage extends StatelessWidget {
  final _SalesRecord sale;

  const _SalesReceiptPage({required this.sale});

  @override
  Widget build(BuildContext context) {
    final items = sale.items;
    final totalQty = items.fold<int>(
      0,
      (totalQty, item) => totalQty + item.quantity,
    );
    final totalItems = items.isEmpty ? 1 : totalQty;
    final paidAmount = sale.paidAmount > 0
        ? sale.paidAmount
        : (sale.paymentMethod.toLowerCase().contains('tunai')
              ? sale.total
              : sale.total);
    final changeAmount = sale.changeAmount > 0 ? sale.changeAmount : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            sale.receiptLabel,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: const Color(0xFF000000), height: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Transaksi',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _ReceiptMetaRow(label: 'Dibuat Oleh', value: sale.cashierName),
            const SizedBox(height: 8),
            _ReceiptMetaRow(label: 'Pembayaran', value: sale.paymentMethod),
            const SizedBox(height: 8),
            _ReceiptMetaRow(
              label: 'Tanggal Transaksi',
              value: sale.createdAt == null
                  ? '-'
                  : _fullDateTimeLabel(sale.createdAt!),
            ),
            const SizedBox(height: 14),
            Container(height: 0.5, color: const Color(0xFFBFBFBF)),
            const SizedBox(height: 16),
            Text(
              'Pesanan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const _ReceiptHeaderRow(),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'Tidak ada detail item pada transaksi ini.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B6B6B),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReceiptItemRow(item: item),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Total QTY : $totalItems',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
            ),
            const SizedBox(height: 8),
            _ReceiptSummaryRow(
              label: 'Total Pesanan',
              value: _formatCurrency(sale.total),
            ),
            const SizedBox(height: 8),
            _ReceiptSummaryRow(
              label: 'Total',
              value: _formatCurrency(sale.total),
            ),
            const SizedBox(height: 8),
            _ReceiptSummaryRow(
              label: 'Bayar',
              value: _formatCurrency(paidAmount),
            ),
            const SizedBox(height: 8),
            _ReceiptSummaryRow(
              label: 'Kembali',
              value: _formatCurrency(changeAmount),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptMetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF2A2A2A),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF2A2A2A),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptHeaderRow extends StatelessWidget {
  const _ReceiptHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            'Nama Barang',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Jumlah',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Harga',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  final _SalesLineItem item;

  const _ReceiptItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            item.name,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '${_formatCurrency(item.unitPrice)} x ${item.quantity}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.black),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            _formatCurrency(item.subtotal),
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class _ReceiptSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
        ),
      ],
    );
  }
}

class _SalesStatusState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

  const _SalesStatusState({
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: const Color(0xFF222222),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: const Color(0xFF7A7A7A),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesDrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SalesDrawerMenuItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? const Color(0xFFE7EEF9)
        : Colors.transparent;
    final foregroundColor = selected
        ? const Color(0xFF162B5A)
        : const Color(0xFF4D4D4F);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap ?? () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: selected ? 1.04 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(icon, color: foregroundColor, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: GoogleFonts.poppins(
                        color: foregroundColor,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PenjualanDrawer extends StatelessWidget {
  const _PenjualanDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.84 > 292
          ? 292
          : MediaQuery.sizeOf(context).width * 0.84,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 18,
                            left: 14,
                            right: 14,
                            bottom: 0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'SmartLaba',
                              style: GoogleFonts.unbounded(
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: const Color(0xFF162B5A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          height: 0.3,
                          color: const Color(0xFF4D4D4F),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SalesDrawerMenuItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        buildSmoothRoute(const DashboardPage()),
                      );
                    },
                  ),
                  _SalesDrawerMenuItem(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Penjualan',
                    selected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _SalesDrawerMenuItem(
                    icon: Icons.analytics_rounded,
                    label: 'Analisis Laba & Keuangan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        buildSmoothRoute(const AiFinancePage()),
                      );
                    },
                  ),
                  _SalesDrawerMenuItem(
                    icon: Icons.auto_graph_rounded,
                    label: 'Prediksi & Perencanaan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        buildSmoothRoute(const AiPredictionPage()),
                      );
                    },
                  ),
                  _SalesDrawerMenuItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Business Health Score',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        buildSmoothRoute(const BusinessHealthScorePage()),
                      );
                    },
                  ),
                  _SalesDrawerMenuItem(
                    icon: Icons.description_outlined,
                    label: 'Laporan & Export',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        buildSmoothRoute(const LaporanExportPage()),
                      );
                    },
                  ),
                  StreamBuilder<UserProfile?>(
                    stream: UserService().streamUserProfile(),
                    builder: (context, snapshot) {
                      final role = snapshot.data?.role;
                      if (role != 'Owner') {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          _SalesDrawerMenuItem(
                            icon: Icons.inventory_2_outlined,
                            label: 'Manajemen Produk',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                buildSmoothRoute(const ManajemenProdukPage()),
                              );
                            },
                          ),
                          _SalesDrawerMenuItem(
                            icon: Icons.people_outline_rounded,
                            label: 'Manajemen User',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                buildSmoothRoute(const ManajemenUserPage()),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.black12),
            const SizedBox(height: 8),
            StreamBuilder<UserProfile?>(
              stream: UserService().streamUserProfile(),
              builder: (context, snapshot) {
                final userService = UserService();
                final currentUser = FirebaseAuth.instance.currentUser;

                UserProfile? profile = snapshot.data;

                if (currentUser != null) {
                  final nama = profile?.nama.isNotEmpty == true
                      ? profile!.nama
                      : (currentUser.displayName?.isNotEmpty == true
                            ? currentUser.displayName!
                            : currentUser.email?.split('@')[0] ?? 'User');
                  final email = currentUser.email ?? profile?.email ?? '';

                  profile = UserProfile(
                    uid: currentUser.uid,
                    nama: nama,
                    email: email,
                    nomorHP: profile?.nomorHP ?? '',
                    fotoURL: profile?.fotoURL,
                    role: profile?.role ?? 'Owner',
                  );
                }

                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(context, buildSmoothRoute(const AkunPage()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE8E8E8),
                          backgroundImage: profile?.fotoURL != null
                              ? NetworkImage(profile!.fotoURL!)
                              : null,
                          child: profile?.fotoURL == null
                              ? Text(
                                  userService.getInitials(
                                    profile?.nama ?? 'User',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.nama ?? 'User',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                profile?.email ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          profile?.role ?? 'Owner',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFFF7B1A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
              child: InkWell(
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final rootNavigator = Navigator.of(
                    context,
                    rootNavigator: true,
                  );
                  await AuthService().signOut();
                  if (!context.mounted) {
                    return;
                  }
                  navigator.pop();
                  Future.microtask(() {
                    rootNavigator.pushAndRemoveUntil(
                      buildSmoothRoute(const LoginPage()),
                      (route) => false,
                    );
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Color(0xFFFF3B30),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Keluar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesRecord {
  final String id;
  final num total;
  final DateTime? createdAt;
  final String receiptLabel;
  final String paymentMethod;
  final String cashierName;
  final String storeId;
  final String ownerUid;
  final num paidAmount;
  final num changeAmount;
  final List<_SalesLineItem> items;

  const _SalesRecord({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.receiptLabel,
    required this.paymentMethod,
    required this.cashierName,
    required this.storeId,
    required this.ownerUid,
    required this.paidAmount,
    required this.changeAmount,
    required this.items,
  });

  factory _SalesRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return _SalesRecord(
      id: doc.id,
      total: _readNumber(data, const ['total', 'grandTotal', 'amount']),
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
      paidAmount: _readNumber(data, const [
        'paidAmount',
        'amountPaid',
        'bayar',
        'dibayar',
        'cashReceived',
      ]),
      changeAmount: _readNumber(data, const [
        'changeAmount',
        'kembalian',
        'change',
      ]),
      items: _readItemMaps(data)
          .map(_SalesLineItem.fromMap)
          .where((item) => item.name.isNotEmpty)
          .toList(),
    );
  }
}

class _SalesLineItem {
  final String name;
  final int quantity;
  final num unitPrice;
  final num subtotal;

  const _SalesLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory _SalesLineItem.fromMap(Map<String, dynamic> data) {
    final quantity = _readNumber(data, const [
      'qty',
      'quantity',
      'jumlah',
      'count',
    ]).round();
    final subtotal = _readNumber(data, const ['subtotal', 'total', 'amount']);
    final unitPrice = _readNumber(data, const ['hargaJual', 'price', 'harga']);
    final normalizedQty = quantity <= 0 ? 1 : quantity;

    return _SalesLineItem(
      name: _readString(data, const [
        'namaProduk',
        'productName',
        'name',
        'nama',
        'title',
      ], fallback: ''),
      quantity: normalizedQty,
      unitPrice: unitPrice > 0
          ? unitPrice
          : (subtotal > 0 ? subtotal / normalizedQty : 0),
      subtotal: subtotal > 0
          ? subtotal
          : (unitPrice > 0 ? unitPrice * normalizedQty : 0),
    );
  }
}

bool _matchesSalesScope({
  required _SalesRecord sale,
  required FirestoreScope scope,
}) {
  return matchesStoreScopedRecord(
    recordOwnerUid: sale.ownerUid,
    recordStoreId: sale.storeId,
    scope: scope,
    includeLegacyOwnerFallback: true,
  );
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _formatCurrency(num value) {
  final wholeNumber = value.round();
  final raw = wholeNumber.toString();
  final formatted = raw.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $formatted';
}

String _monthYearLabel(DateTime date) {
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

  return '${months[date.month - 1]} ${date.year}';
}

String _fullMonthLabel(int month) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return months[month - 1];
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _readableDateFromKey(String key) {
  final parsed = DateTime.tryParse(key);
  if (parsed == null) {
    return key;
  }
  final day = parsed.day.toString().padLeft(2, '0');
  return '$day ${_fullMonthLabel(parsed.month)}';
}

String _timeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _fullDateTimeLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return '$day ${_fullMonthLabel(date.month)} ${date.year} $hour:$minute:$second';
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
