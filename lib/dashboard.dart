import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'app_transitions.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'akun_page.dart';
import 'business_ai_pages.dart';
import 'business_ai_service.dart';
import 'laporan_export_page.dart';
import 'user_service.dart';
import 'manajemen_user_page.dart';
import 'manajemen_produk_page.dart';
import 'penjualan_page.dart';
import 'store_hub_page.dart';

// --- Modern Summary Card Widget ---
class _ModernSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String trend;
  final Color trendColor;
  final IconData? trendIcon;

  const _ModernSummaryCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.trend,
    required this.trendColor,
    this.trendIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2D2D2)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const Spacer(),
              if (trend.isNotEmpty && trendIcon != null)
                Row(
                  children: [
                    Icon(trendIcon, color: trendColor, size: 15),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
            ],
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

class _DashboardSectionCard extends StatelessWidget {
  final Widget child;

  const _DashboardSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2D2D2)),
      ),
      child: child,
    );
  }
}

// --- Drawer menu item helper widget ---
class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const DrawerMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? const Color(0xFF162B5A)
        : const Color(0xFF5B5B5B);
    final backgroundColor = selected
        ? const Color(0xFFE7EEF9)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: selected ? 1.04 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(icon, color: foregroundColor, size: 18),
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

// --- Custom Drawer for SmartLaba ---
class _SmartLabaDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: math.min(MediaQuery.sizeOf(context).width * 0.84, 292),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: StreamBuilder<UserProfile?>(
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
                        : currentUser.email?.split('@').first ?? 'User');

              profile = UserProfile(
                uid: currentUser.uid,
                nama: nama,
                email: currentUser.email ?? profile?.email ?? '',
                nomorHP: profile?.nomorHP ?? '',
                fotoURL: profile?.fotoURL,
                role: profile?.role ?? 'Owner',
              );
            }

            final isOwner = profile?.role == 'Owner';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
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
                Container(
                  width: double.infinity,
                  height: 0.6,
                  color: const Color(0xFF4D4D4F),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                    children: [
                      DrawerMenuItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        selected: true,
                        onTap: () => Navigator.pop(context),
                      ),
                      if (isOwner)
                        DrawerMenuItem(
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
                      DrawerMenuItem(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Penjualan',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            buildSmoothRoute(const PenjualanPage()),
                          );
                        },
                      ),
                      DrawerMenuItem(
                        icon: Icons.autorenew_rounded,
                        label: 'Analisis Laba & Keuangan',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            buildSmoothRoute(const AiFinancePage()),
                          );
                        },
                      ),
                      DrawerMenuItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'Prediksi & Perencanaan',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            buildSmoothRoute(const AiPredictionPage()),
                          );
                        },
                      ),
                      DrawerMenuItem(
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
                      DrawerMenuItem(
                        icon: Icons.file_present_outlined,
                        label: 'Laporan & Export',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            buildSmoothRoute(const LaporanExportPage()),
                          );
                        },
                      ),
                      if (isOwner)
                        DrawerMenuItem(
                          icon: Icons.manage_accounts_outlined,
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
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 0.6,
                  color: Colors.black26,
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(context, buildSmoothRoute(const AkunPage()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE8E8E8),
                          backgroundImage: profile?.fotoURL != null
                              ? NetworkImage(profile!.fotoURL!)
                              : null,
                          child: profile?.fotoURL == null
                              ? Text(
                                  userService.getInitials(profile?.nama ?? 'U'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2A2A2A),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.nama ?? 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: const Color(0xFF2A2A2A),
                                ),
                              ),
                              Text(
                                profile?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          profile?.role ?? 'Owner',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFFF8A1F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
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
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFFF3B30),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Keluar',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Placeholder for DashboardStatisPage
class DashboardStatisPage extends StatelessWidget {
  const DashboardStatisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Statis')),
      body: const Center(child: Text('Dashboard Statis Page')),
    );
  }
}

// Helper to detect FontAwesome icon
bool isFontAwesome(IconData icon) {
  return icon.fontFamily?.startsWith('FontAwesome') ?? false;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int transaksi = 0;
  int pendapatan = 0;
  int labaBersih = 0;
  double margin = 0;
  BusinessAnalyticsBundle? aiBundle;
  bool loading = true;
  String? errorMsg;

  Future<void> _goToStoreList() async {
    final popped = await Navigator.of(context).maybePop();
    if (!mounted || popped) {
      return;
    }

    await Navigator.of(
      context,
    ).pushReplacement(buildSmoothRoute(const StoreHubPage()));
  }

  @override
  void initState() {
    super.initState();
    _ensureUserProfile();
    fetchDashboardData();
  }

  Future<void> _ensureUserProfile() async {
    try {
      final userService = UserService();
      final currentUser = AuthService().currentUser;

      if (currentUser == null) {
        return;
      }

      final profileFromFirestore = await userService.getUserProfile();

      if (profileFromFirestore == null) {
        final newProfile = UserProfile(
          uid: currentUser.uid,
          nama:
              currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'User',
          email: currentUser.email ?? '',
          nomorHP: '',
          role: 'Owner',
        );
        await userService.saveUserProfile(newProfile);
      }
    } catch (_) {
      // Keep dashboard usable even if profile sync fails.
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      final bundle = await BusinessAiService().loadBundle();
      if (!mounted) {
        return;
      }

      setState(() {
        aiBundle = bundle;
        transaksi = bundle.transactionsToday;
        pendapatan = bundle.revenueToday.round();
        labaBersih = bundle.profitToday.round();
        margin = bundle.marginPercent;
        loading = false;
        errorMsg = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        loading = false;
        errorMsg = e.toString();
      });
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

  String _formatTrend(double value) {
    if (value == 0) {
      return '0%';
    }

    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  Color _trendColor(double value) {
    if (value > 0) {
      return const Color(0xFF5BE45B);
    }
    if (value < 0) {
      return const Color(0xFFFF4B4B);
    }
    return const Color(0xFF8A8A8A);
  }

  IconData _trendIcon(double value) {
    if (value < 0) {
      return Icons.trending_down_rounded;
    }
    return Icons.trending_up_rounded;
  }

  String _healthSummaryLabel(double score) {
    if (score >= 75) {
      return 'Sehat';
    }
    if (score >= 55) {
      return 'Perlu Penguatan';
    }
    return 'Butuh Tindakan';
  }

  String _healthSummaryMessage(BusinessAnalyticsBundle bundle) {
    if (bundle.healthInsights.isNotEmpty) {
      return bundle.healthInsights.first.message;
    }

    if (bundle.healthScore >= 75) {
      return 'Bisnis Anda dalam kondisi baik dan stabil.';
    }

    if (bundle.healthScore >= 55) {
      return 'Bisnis cukup stabil, tetapi masih ada area yang perlu diperkuat.';
    }

    return 'Bisnis memerlukan perhatian pada margin, stok, dan konsistensi penjualan.';
  }

  List<BusinessAiInsight> _headlineInsights(BusinessAnalyticsBundle bundle) {
    return [
      ...bundle.financeInsights,
      ...bundle.predictionInsights,
      ...bundle.healthInsights,
    ].take(3).toList();
  }

  IconData _insightIcon(String severity) {
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

  Color _insightColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFE45353);
      case 'medium':
        return const Color(0xFFFFC043);
      case 'good':
        return const Color(0xFF28B46E);
      default:
        return const Color(0xFF4F75F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = const Color(0xFFE7E7E7);
    final bundle = aiBundle;
    final healthScore = bundle?.healthScore ?? 0;
    final hasTrendData =
        bundle != null &&
        bundle.last7Days.any((item) => item.revenue > 0 || item.profit > 0);
    final headlineInsights = bundle == null
        ? <BusinessAiInsight>[]
        : _headlineInsights(bundle);
    return Scaffold(
      backgroundColor: bgColor,
      drawer: _SmartLabaDrawer(),
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
          'Dashboard',
          style: GoogleFonts.unbounded(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF162B5A),
          ),
        ),
        actions: [
          StreamBuilder<UserProfile?>(
            stream: UserService().streamUserProfile(),
            builder: (context, snapshot) {
              final isOwner = (snapshot.data?.role ?? 'Owner') == 'Owner';
              if (!isOwner) {
                return const SizedBox(width: 12);
              }

              return IconButton(
                tooltip: 'Daftar Toko',
                onPressed: _goToStoreList,
                icon: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Color(0xFF4D4D4F),
                  size: 22,
                ),
              );
            },
          ),
        ],
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Firestore error:\n$errorMsg',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.08,
                    children: [
                      _ModernSummaryCard(
                        icon: Icons.attach_money_rounded,
                        iconBg: const Color(0xFF1B2C5D),
                        iconColor: Colors.white,
                        value: transaksi == 0
                            ? '-'
                            : _formatCurrency(pendapatan),
                        label: 'Pendapatan Hari Ini',
                        trend: bundle == null
                            ? ''
                            : _formatTrend(bundle.growthPercent),
                        trendColor: bundle == null
                            ? Colors.transparent
                            : _trendColor(bundle.growthPercent),
                        trendIcon: bundle == null
                            ? null
                            : _trendIcon(bundle.growthPercent),
                      ),
                      _ModernSummaryCard(
                        icon: Icons.shopping_bag_outlined,
                        iconBg: const Color(0xFFFFF4EA),
                        iconColor: const Color(0xFFFF8A1F),
                        value: transaksi == 0 ? '-' : transaksi.toString(),
                        label: 'Transaksi Hari Ini',
                        trend: bundle == null || bundle.transactions30d == 0
                            ? ''
                            : '${bundle.transactions30d} /30h',
                        trendColor: const Color(0xFF8A8A8A),
                        trendIcon: bundle == null || bundle.transactions30d == 0
                            ? null
                            : Icons.receipt_long_outlined,
                      ),
                      _ModernSummaryCard(
                        icon: Icons.account_balance_wallet_rounded,
                        iconBg: const Color(0xFFE8F7EF),
                        iconColor: const Color(0xFF27AE60),
                        value: transaksi == 0
                            ? '-'
                            : _formatCurrency(labaBersih),
                        label: 'Laba Bersih',
                        trend: bundle == null
                            ? ''
                            : _formatTrend(bundle.growthPercent),
                        trendColor: bundle == null
                            ? Colors.transparent
                            : _trendColor(bundle.growthPercent),
                        trendIcon: bundle == null
                            ? null
                            : _trendIcon(bundle.growthPercent),
                      ),
                      _ModernSummaryCard(
                        icon: Icons.shopping_cart_checkout_rounded,
                        iconBg: const Color(0xFFFFF3E8),
                        iconColor: const Color(0xFFF59E42),
                        value: transaksi == 0
                            ? '-'
                            : '${margin.toStringAsFixed(0)}%',
                        label: 'Margin Rata rata',
                        trend: '',
                        trendColor: Colors.transparent,
                        trendIcon: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DashboardSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tren 7 hari',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xFF4B4B4B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 160,
                          child: !hasTrendData
                              ? Center(
                                  child: Text(
                                    'Belum ada data transaksi.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF8A8A8A),
                                    ),
                                  ),
                                )
                              : DashboardTrendChart(metrics: bundle.last7Days),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF19326D), Color(0xFF2D57C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Health Score',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  width: 92,
                                  height: 92,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 92,
                                        height: 92,
                                        child: CircularProgressIndicator(
                                          value: healthScore / 100,
                                          strokeWidth: 10,
                                          backgroundColor: Colors.white24,
                                          valueColor: AlwaysStoppedAnimation(
                                            healthScore >= 75
                                                ? const Color(0xFF72F34F)
                                                : healthScore >= 55
                                                ? const Color(0xFFFFD04B)
                                                : const Color(0xFFFF7B7B),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            healthScore.toStringAsFixed(0),
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: healthScore >= 75
                                                  ? const Color(0xFF72F34F)
                                                  : healthScore >= 55
                                                  ? const Color(0xFFFFD04B)
                                                  : const Color(0xFFFF7B7B),
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
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      size: 14,
                                      color: healthScore == 0
                                          ? Colors.white54
                                          : healthScore >= 75
                                          ? const Color(0xFF72F34F)
                                          : healthScore >= 55
                                          ? const Color(0xFFFFD04B)
                                          : const Color(0xFFFF7B7B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      healthScore == 0
                                          ? '-'
                                          : _healthSummaryLabel(healthScore),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: healthScore == 0
                                            ? Colors.white54
                                            : healthScore >= 75
                                            ? const Color(0xFF72F34F)
                                            : healthScore >= 55
                                            ? const Color(0xFFFFD04B)
                                            : const Color(0xFFFF7B7B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                bundle == null || bundle.transactions30d == 0
                                    ? 'Belum ada data untuk menilai kondisi bisnis Anda.'
                                    : _healthSummaryMessage(bundle),
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
                  const SizedBox(height: 12),
                  _DashboardSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFFF9B49),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI Insight',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFFFF9B49),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        headlineInsights.isEmpty
                            ? Text(
                                'Belum ada insight karena belum ada transaksi.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF8A8A8A),
                                ),
                              )
                            : Column(
                                children: headlineInsights
                                    .map(
                                      (item) => _AiInsightItem(
                                        icon: _insightIcon(item.severity),
                                        iconColor: _insightColor(item.severity),
                                        title: item.title,
                                        description: item.message,
                                      ),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DashboardSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Produk Terlaris',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: const Color(0xFF2F5BBE),
                          ),
                        ),
                        const SizedBox(height: 12),
                        bundle == null || bundle.topProducts.isEmpty
                            ? Text(
                                'Belum ada data produk terlaris.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF8A8A8A),
                                ),
                              )
                            : _ProdukTerlarisBarChart(
                                data: bundle.topProducts
                                    .map(
                                      (item) => _ProdukBarData(
                                        item.name,
                                        item.quantity,
                                      ),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class DashboardTrendChart extends StatelessWidget {
  final List<BusinessDailyMetric> metrics;

  const DashboardTrendChart({required this.metrics, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: CustomPaint(
        painter: TrendChartPainter(metrics: metrics),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2, left: 28, right: 6),
          child: Column(
            children: [
              const Expanded(child: SizedBox()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: metrics
                    .map(
                      (item) => Text(
                        _shortDayLabel(item.date),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey,
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

class TrendChartPainter extends CustomPainter {
  final List<BusinessDailyMetric> metrics;

  const TrendChartPainter({required this.metrics});

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPad = 24;
    final double bottomPad = 18;
    final double topPad = 8;
    final double rightPad = 6;
    final double chartWidth = size.width - leftPad - rightPad;
    final double chartHeight = size.height - topPad - bottomPad;

    if (metrics.isEmpty) {
      return;
    }

    final omzet = metrics.map((item) => item.revenue.toDouble()).toList();
    final laba = metrics.map((item) => item.profit.toDouble()).toList();
    final maxY = math.max(
      1,
      math.max(
        omzet.fold<double>(0, (max, item) => item > max ? item : max),
        laba.fold<double>(0, (max, item) => item > max ? item : max),
      ),
    );

    double pointX(int index) {
      if (metrics.length == 1) {
        return leftPad + (chartWidth / 2);
      }
      return leftPad + index * chartWidth / (metrics.length - 1);
    }

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      double y = topPad + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        gridPaint,
      );
    }

    final omzetPath = Path();
    for (int i = 0; i < omzet.length; i++) {
      final x = pointX(i);
      final y = topPad + chartHeight * (1 - omzet[i] / maxY);
      if (i == 0) {
        omzetPath.moveTo(x, y);
      } else {
        omzetPath.lineTo(x, y);
      }
    }
    omzetPath.lineTo(leftPad + chartWidth, topPad + chartHeight);
    omzetPath.lineTo(leftPad, topPad + chartHeight);
    omzetPath.close();

    final omzetPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFF97316).withValues(alpha: 0.15),
          const Color(0xFFF97316).withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(omzetPath, omzetPaint);

    final labaPath = Path();
    for (int i = 0; i < laba.length; i++) {
      final x = pointX(i);
      final y = topPad + chartHeight * (1 - laba[i] / maxY);
      if (i == 0) {
        labaPath.moveTo(x, y);
      } else {
        labaPath.lineTo(x, y);
      }
    }
    labaPath.lineTo(leftPad + chartWidth, topPad + chartHeight);
    labaPath.lineTo(leftPad, topPad + chartHeight);
    labaPath.close();

    final labaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.15),
          const Color(0xFF3B82F6).withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;
    canvas.drawPath(labaPath, labaPaint);

    final omzetLine = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final omzetLinePath = Path();
    for (int i = 0; i < omzet.length; i++) {
      final x = pointX(i);
      final y = topPad + chartHeight * (1 - omzet[i] / maxY);
      if (i == 0) {
        omzetLinePath.moveTo(x, y);
      } else {
        omzetLinePath.lineTo(x, y);
      }
    }
    canvas.drawPath(omzetLinePath, omzetLine);

    final labaLine = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final labaLinePath = Path();
    for (int i = 0; i < laba.length; i++) {
      final x = pointX(i);
      final y = topPad + chartHeight * (1 - laba[i] / maxY);
      if (i == 0) {
        labaLinePath.moveTo(x, y);
      } else {
        labaLinePath.lineTo(x, y);
      }
    }
    canvas.drawPath(labaLinePath, labaLine);

    // Draw points
    final pointPaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < omzet.length; i++) {
      final x = pointX(i);
      final y = topPad + chartHeight * (1 - omzet[i] / maxY);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(
        Offset(x, y),
        4,
        strokePaint..color = const Color(0xFFF97316),
      );
    }

    strokePaint.color = const Color(0xFF3B82F6);
    for (int i = 0; i < laba.length; i++) {
      final x = pointX(i);
      final y = topPad + chartHeight * (1 - laba[i] / maxY);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 4, strokePaint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i <= 5; i++) {
      double value = (maxY / 5) * i;
      double y = topPad + chartHeight * (1 - value / maxY);

      textPainter.text = TextSpan(
        text: _compactChartValue(value),
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPad - textPainter.width - 4, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter oldDelegate) {
    return oldDelegate.metrics != metrics;
  }
}

// --- AI Insight Item Widget ---
class _AiInsightItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _AiInsightItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFEFEFEF),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.north_east_rounded,
                      color: const Color(0xFFBDBDBD),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: const Color(0xFF666666),
                    height: 1.35,
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

// --- Produk Terlaris Bar Chart Widget ---
class _ProdukTerlarisBarChart extends StatelessWidget {
  final List<_ProdukBarData> data;

  const _ProdukTerlarisBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      1,
      (max, item) => item.value > max ? item.value : max,
    );
    return SizedBox(
      height: 175,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 92,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth - 6;
                final axisLabels = [
                  0,
                  (maxValue * 0.25).round(),
                  (maxValue * 0.5).round(),
                  (maxValue * 0.75).round(),
                  maxValue,
                ];

                return Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              5,
                              (_) => Container(
                                height: 1,
                                color: const Color(0xFFE5E5E5),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: data.map((item) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 18,
                                  width: (item.value / maxValue) * chartWidth,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF58A2A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: axisLabels
                          .map(
                            (item) => Text(
                              '$item',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: const Color(0xFF9B9B9B),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProdukBarData {
  final String label;
  final int value;
  const _ProdukBarData(this.label, this.value);
}

String _shortDayLabel(DateTime date) {
  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  return days[date.weekday - 1];
}

String _compactChartValue(num value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}jt';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}k';
  }
  return value.round().toString();
}
