import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'akun_page.dart';
import 'auth_service.dart';
import 'business_ai_pages.dart';
import 'firestore_scope.dart';
import 'laporan_export_page.dart';
import 'manajemen_produk_page.dart';
import 'manajemen_user_page.dart';
import 'penjualan_page.dart';
import 'user_service.dart';

class WebAdminPage extends StatefulWidget {
  const WebAdminPage({super.key});

  @override
  State<WebAdminPage> createState() => _WebAdminPageState();
}

class _WebAdminPageState extends State<WebAdminPage> {
  int _selectedIndex = 0;

  static const _sections = [
    _WebAdminSection(
      label: 'Dashboard',
      title: 'Dashboard Workspace',
      subtitle:
          'Pantau ringkasan toko, penjualan, dan sinkronisasi owner web dengan aplikasi mobile.',
      icon: Icons.dashboard_outlined,
    ),
    _WebAdminSection(
      label: 'Manajemen Produk',
      title: 'Manajemen Produk',
      subtitle: 'Kelola produk dari workspace web SmartLaba.',
      icon: Icons.inventory_2_outlined,
    ),
    _WebAdminSection(
      label: 'Penjualan',
      title: 'Penjualan',
      subtitle: 'Transaksi realtime yang sama dengan aplikasi mobile.',
      icon: Icons.shopping_cart_outlined,
    ),
    _WebAdminSection(
      label: 'Analisis Laba & Keuangan',
      title: 'Analisis Laba & Keuangan',
      subtitle: 'Ringkasan omzet, laba, margin, dan insight AI.',
      icon: Icons.analytics_outlined,
    ),
    _WebAdminSection(
      label: 'Prediksi & Perencanaan',
      title: 'Prediksi & Perencanaan',
      subtitle: 'Arah penjualan dan rencana aksi bisnis berikutnya.',
      icon: Icons.timeline_rounded,
    ),
    _WebAdminSection(
      label: 'Business Health Score',
      title: 'Business Health Score',
      subtitle: 'Pantau kesehatan bisnis dan prioritas perbaikannya.',
      icon: Icons.favorite_border_rounded,
    ),
    _WebAdminSection(
      label: 'Laporan & Export',
      title: 'Laporan & Export',
      subtitle: 'Filter laporan dan export data seperti di aplikasi.',
      icon: Icons.file_download_outlined,
    ),
    _WebAdminSection(
      label: 'Manajemen User',
      title: 'Manajemen User',
      subtitle: 'Atur owner dan kasir dari workspace yang sama.',
      icon: Icons.people_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F0E9),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F4EE), Color(0xFFEAE4D7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1720),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stackedLayout = constraints.maxWidth < 1180;

                    final navigationPanel = _WebAdminSidebar(
                      stacked: stackedLayout,
                      selectedIndex: _selectedIndex,
                      onSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      sections: _sections,
                    );

                    final workspaceContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WebAdminHeader(section: section),
                        const SizedBox(height: 20),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7F4),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: const Color(0xFFD8DDE7),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x120F172A),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: IndexedStack(
                                index: _selectedIndex,
                                children: const [
                                  WebAdminOverview(),
                                  ManajemenProdukPage(embedded: true),
                                  PenjualanContent(),
                                  AiFinancePage(embedded: true),
                                  AiPredictionPage(embedded: true),
                                  BusinessHealthScorePage(embedded: true),
                                  LaporanExportPage(embedded: true),
                                  ManajemenUserPage(embedded: true),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );

                    if (stackedLayout) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          navigationPanel,
                          const SizedBox(height: 18),
                          Expanded(child: workspaceContent),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 332, child: navigationPanel),
                        const SizedBox(width: 22),
                        Expanded(child: workspaceContent),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebAdminHeader extends StatelessWidget {
  final _WebAdminSection section;

  const _WebAdminHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final chips = [
      (section.icon, section.label),
      (Icons.sync_alt_rounded, 'Sinkron mobile'),
      (Icons.calendar_month_rounded, formattedDate),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF162B5A), Color(0xFF21408A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22162B5A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: chips
                          .map(
                            (chip) =>
                                _HeaderBadge(icon: chip.$1, label: chip.$2),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      section.title,
                      style: GoogleFonts.unbounded(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      section.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: GoogleFonts.unbounded(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            section.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.84),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: chips
                          .map(
                            (chip) =>
                                _HeaderBadge(icon: chip.$1, label: chip.$2),
                          )
                          .toList(),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebAdminSidebar extends StatelessWidget {
  final bool stacked;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_WebAdminSection> sections;

  const _WebAdminSidebar({
    required this.stacked,
    required this.selectedIndex,
    required this.onSelected,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSection = sections[selectedIndex];

    return Container(
      padding: EdgeInsets.all(stacked ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101C37), Color(0xFF162B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8A1F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartLaba',
                      style: GoogleFonts.unbounded(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner Workspace Web',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Navigasi Owner',
                  style: GoogleFonts.unbounded(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Menu di web sekarang diringkas menjadi dropdown supaya tetap rapi, tetapi isinya tetap sama seperti aplikasi mobile owner.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.65,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih modul aktif',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedIndex,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF162B5A),
                  iconEnabledColor: Colors.white,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFB86B),
                        width: 1.4,
                      ),
                    ),
                  ),
                  items: [
                    for (var index = 0; index < sections.length; index++)
                      DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          sections[index].label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSelected(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFF8A1F,
                          ).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          selectedSection.icon,
                          color: const Color(0xFFFFD6A6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedSection.label,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedSection.subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                height: 1.55,
                                color: Colors.white.withValues(alpha: 0.76),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SidebarSyncPanel(sections: sections),
          if (!stacked) const Spacer(),
          const SizedBox(height: 16),
          const _SidebarProfile(),
        ],
      ),
    );
  }
}

class _SidebarSyncPanel extends StatelessWidget {
  final List<_WebAdminSection> sections;

  const _SidebarSyncPanel({required this.sections});

  @override
  Widget build(BuildContext context) {
    final syncItems = [
      (
        Icons.dashboard_customize_outlined,
        'Dashboard & ringkasan',
        'Pantau performa harian owner seperti di mobile.',
      ),
      (
        Icons.inventory_2_outlined,
        'Produk & stok',
        'Kelola katalog, harga, dan stok toko aktif.',
      ),
      (
        Icons.point_of_sale_rounded,
        'Penjualan realtime',
        'Transaksi dan kasir tetap membaca data yang sama.',
      ),
      (
        Icons.insights_outlined,
        'AI, laporan, user',
        'Analisis, export, dan manajemen tim tetap lengkap.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selaras dengan mobile',
            style: GoogleFonts.unbounded(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${sections.length} modul owner tetap tersedia, hanya tampilan navigasinya dibuat lebih bersih untuk web.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.65,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 14),
          ...syncItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SidebarSyncRow(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSyncRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SidebarSyncRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFFFD6A6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.8,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.72),
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

class _SidebarProfile extends StatelessWidget {
  const _SidebarProfile();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: UserService().streamUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akun aktif',
                style: GoogleFonts.unbounded(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AkunPage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Text(
                        UserService().getInitials(profile?.nama ?? 'Owner'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF162B5A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.nama ?? 'Owner',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?.email ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AkunPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.person_outline_rounded, size: 18),
                      label: Text(
                        'Profil',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE5E1),
                        foregroundColor: const Color(0xFFB42318),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'Keluar',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
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

class WebAdminOverview extends StatelessWidget {
  const WebAdminOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<FirestoreScope?>(
      future: resolveCurrentFirestoreScope(),
      builder: (context, scopeSnapshot) {
        if (scopeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final scope = scopeSnapshot.data;
        if (scope == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            final now = DateTime.now();

            var transaksiHariIni = 0;
            num omzetHariIni = 0;
            final recentSales = <_AdminRecentSale>[];

            for (final doc in docs) {
              final data = doc.data();
              final recordOwnerUid = _overviewReadString(data, const [
                'ownerUid',
              ], fallback: '');
              final recordStoreId = _overviewReadString(data, const [
                'storeId',
              ], fallback: '');
              final matchesOwner = matchesOwnerScopedRecord(
                recordOwnerUid: recordOwnerUid,
                ownerUid: scope.ownerUid,
              );
              final matchesActiveStoreFallback =
                  recordOwnerUid.isEmpty &&
                  scope.activeStoreId.isNotEmpty &&
                  recordStoreId == scope.activeStoreId;
              if (!matchesOwner && !matchesActiveStoreFallback) {
                continue;
              }

              final createdAt = _overviewReadDate(data);
              final total = _overviewReadNumber(data);

              if (createdAt != null &&
                  createdAt.year == now.year &&
                  createdAt.month == now.month &&
                  createdAt.day == now.day) {
                transaksiHariIni += 1;
                omzetHariIni += total;
              }

              recentSales.add(
                _AdminRecentSale(
                  id: doc.id,
                  total: total,
                  createdAt: createdAt,
                  paymentMethod: _overviewReadString(data, const [
                    'paymentMethod',
                    'metodePembayaran',
                    'metode',
                    'payment',
                  ], fallback: 'Tunai'),
                ),
              );
            }

            recentSales.sort(
              (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                  ),
            );

            final statCards = [
              _OverviewStatCard(
                label: 'Omzet Hari Ini',
                value: _overviewFormatCurrency(omzetHariIni),
                icon: Icons.payments_outlined,
                accentColor: const Color(0xFF162B5A),
              ),
              _OverviewStatCard(
                label: 'Transaksi Hari Ini',
                value: transaksiHariIni.toString(),
                icon: Icons.receipt_long_outlined,
                accentColor: const Color(0xFFFF8A1F),
              ),
              _StreamCountCard(
                label: 'Total Produk',
                icon: Icons.inventory_2_outlined,
                accentColor: const Color(0xFF0F766E),
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(scope.dataOwnerUid)
                    .collection('produk')
                    .snapshots(),
              ),
              _StreamCountCard(
                label: 'Total Kasir',
                icon: Icons.people_outline_rounded,
                accentColor: const Color(0xFF7C3AED),
                stream: FirebaseFirestore.instance
                    .collection('kasir')
                    .where('ownerUid', isEqualTo: scope.ownerUid)
                    .snapshots(),
                countBuilder: (snapshot) => snapshot.docs
                    .where((doc) => doc.data()['isDeleted'] != true)
                    .length,
              ),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 1120;
                final centeredMaxWidth = constraints.maxWidth >= 1480
                    ? 1240.0
                    : constraints.maxWidth;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: centeredMaxWidth),
                    child: ListView(
                      padding: const EdgeInsets.all(28),
                      children: [
                        _OverviewWorkspaceBanner(
                          scope: scope,
                          transaksiHariIni: transaksiHariIni,
                          omzetHariIni: omzetHariIni,
                        ),
                        const SizedBox(height: 22),
                        _OverviewStatsGrid(cards: statCards),
                        const SizedBox(height: 22),
                        if (wideLayout)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 8,
                                child: _RecentSalesPanel(
                                  recentSales: recentSales,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _WorkspaceInfoPanel(scope: scope),
                                    const SizedBox(height: 18),
                                    const _WorkspaceActionPanel(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _RecentSalesPanel(recentSales: recentSales),
                          const SizedBox(height: 18),
                          _WorkspaceInfoPanel(scope: scope),
                          const SizedBox(height: 18),
                          const _WorkspaceActionPanel(),
                        ],
                      ],
                    ),
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

class _OverviewWorkspaceBanner extends StatelessWidget {
  final FirestoreScope scope;
  final int transaksiHariIni;
  final num omzetHariIni;

  const _OverviewWorkspaceBanner({
    required this.scope,
    required this.transaksiHariIni,
    required this.omzetHariIni,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final summaryCard = Container(
          constraints: BoxConstraints(
            minHeight: compact ? 0 : 164,
            maxWidth: compact ? double.infinity : 300,
          ),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ringkasan hari ini',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _overviewFormatCurrency(omzetHariIni),
                style: GoogleFonts.unbounded(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$transaksiHariIni transaksi tercatat pada workspace aktif.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.84),
                ),
              ),
            ],
          ),
        );

        final infoColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Workspace Web + Mobile Sync',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Semua data toko tetap sinkron di web dan aplikasi.',
              style: GoogleFonts.unbounded(
                fontSize: compact ? 19 : 23,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Store aktif: ${scope.activeStoreName.isNotEmpty ? scope.activeStoreName : 'Belum dipilih'}. Perubahan produk, kasir, penjualan, dan laporan langsung memakai database Firebase yang sama.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.65,
                color: Colors.white.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoPill(
                  icon: Icons.storefront_outlined,
                  label: scope.activeStoreName.isNotEmpty
                      ? scope.activeStoreName
                      : 'Workspace owner',
                ),
                _InfoPill(
                  icon: Icons.person_outline_rounded,
                  label: scope.role,
                ),
                const _InfoPill(
                  icon: Icons.sync_alt_rounded,
                  label: 'Realtime sinkron',
                ),
              ],
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16305F), Color(0xFF3B67C6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoColumn,
                    const SizedBox(height: 18),
                    summaryCard,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: infoColumn),
                    const SizedBox(width: 18),
                    summaryCard,
                  ],
                ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatsGrid extends StatelessWidget {
  final List<Widget> cards;

  const _OverviewStatsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 4
            : width >= 700
            ? 2
            : 1;
        final childAspectRatio = width >= 1100
            ? 1.48
            : width >= 700
            ? 1.78
            : 2.7;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: childAspectRatio,
          children: cards,
        );
      },
    );
  }
}

class _RecentSalesPanel extends StatelessWidget {
  final List<_AdminRecentSale> recentSales;

  const _RecentSalesPanel({required this.recentSales});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penjualan Terbaru',
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat transaksi terbaru dari store aktif ditampilkan di sini.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          if (recentSales.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Belum ada transaksi terbaru di toko aktif.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            )
          else
            ...recentSales
                .take(6)
                .map(
                  (sale) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentSaleRow(sale: sale),
                  ),
                ),
        ],
      ),
    );
  }
}

class _WorkspaceInfoPanel extends StatelessWidget {
  final FirestoreScope scope;

  const _WorkspaceInfoPanel({required this.scope});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Info Workspace',
            style: GoogleFonts.unbounded(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF162B5A),
            ),
          ),
          const SizedBox(height: 16),
          _WorkspaceMetaRow(
            label: 'Role aktif',
            value: scope.role,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _WorkspaceMetaRow(
            label: 'Store aktif',
            value: scope.activeStoreName.isNotEmpty
                ? scope.activeStoreName
                : 'Belum dipilih',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 12),
          _WorkspaceMetaRow(
            label: 'Mode data',
            value: scope.ownerHasMultipleStores ? 'Multi toko' : 'Single toko',
            icon: Icons.layers_outlined,
          ),
          const SizedBox(height: 12),
          const _WorkspaceMetaRow(
            label: 'Sinkronisasi',
            value: 'Firebase realtime',
            icon: Icons.sync_alt_rounded,
          ),
        ],
      ),
    );
  }
}

class _WorkspaceMetaRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WorkspaceMetaRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF162B5A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkspaceActionPanel extends StatelessWidget {
  const _WorkspaceActionPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kontrol Workspace',
            style: GoogleFonts.unbounded(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF162B5A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Semua modul di workspace web memakai alur yang sama dengan aplikasi mobile.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.55,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _WorkspaceFeatureChip(
                icon: Icons.inventory_2_outlined,
                label: 'Kelola Produk',
              ),
              _WorkspaceFeatureChip(
                icon: Icons.point_of_sale_rounded,
                label: 'Penjualan Realtime',
              ),
              _WorkspaceFeatureChip(
                icon: Icons.auto_awesome_rounded,
                label: 'Insight AI',
              ),
              _WorkspaceFeatureChip(
                icon: Icons.file_download_outlined,
                label: 'Laporan & Export',
              ),
              _WorkspaceFeatureChip(
                icon: Icons.people_outline_rounded,
                label: 'User Toko',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WorkspaceFeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF162B5A)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF162B5A),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _OverviewStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.unbounded(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamCountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final int Function(QuerySnapshot<Map<String, dynamic>> snapshot)?
  countBuilder;

  const _StreamCountCard({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.stream,
    this.countBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData
            ? (countBuilder?.call(snapshot.data!) ?? snapshot.data!.docs.length)
            : 0;

        return _OverviewStatCard(
          label: label,
          value: count.toString(),
          icon: icon,
          accentColor: accentColor,
        );
      },
    );
  }
}

class _RecentSaleRow extends StatelessWidget {
  final _AdminRecentSale sale;

  const _RecentSaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sale.createdAt == null
                      ? 'Waktu tidak tersedia'
                      : _overviewDateLabel(sale.createdAt!),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _overviewFormatCurrency(sale.total),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              sale.paymentMethod.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF8A1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebAdminSection {
  final String label;
  final String title;
  final String subtitle;
  final IconData icon;

  const _WebAdminSection({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _AdminRecentSale {
  final String id;
  final num total;
  final DateTime? createdAt;
  final String paymentMethod;

  const _AdminRecentSale({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.paymentMethod,
  });

  String get label {
    final shortId = id.length > 6 ? id.substring(0, 6).toUpperCase() : id;
    return 'Struk $shortId';
  }
}

num _overviewReadNumber(Map<String, dynamic> data) {
  for (final key in const ['total', 'grandTotal', 'amount']) {
    final value = data[key];
    if (value is num) {
      return value;
    }
  }
  return 0;
}

DateTime? _overviewReadDate(Map<String, dynamic> data) {
  for (final key in const [
    'createdAt',
    'timestamp',
    'tanggal',
    'transactionDate',
    'date',
  ]) {
    final value = data[key];
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
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

String _overviewReadString(
  Map<String, dynamic> data,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

String _overviewFormatCurrency(num value) {
  final raw = value.round().toString();
  final formatted = raw.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $formatted';
}

String _overviewDateLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}
