import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      drawer: Drawer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SmartLaba',
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                    color: Color(0xFF162B5A),
                  ),
                ),
              ),
            ),
            Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  drawerItem(Icons.dashboard, 'Dashboard'),
                  drawerItem(Icons.inventory_2, 'Manajemen Produk'),
                  drawerItem(Icons.shopping_cart, 'Penjualan'),
                  drawerItem(Icons.analytics, 'Analisis Laba & Keuangan'),
                  drawerItem(Icons.timeline, 'Prediksi & Perencanaan'),
                  drawerItem(Icons.favorite, 'Business Health Score'),
                  drawerItem(Icons.insert_chart_outlined, 'Laporan & Export'),
                  drawerItem(Icons.people, 'Manajemen User'),
                ],
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(
                      'assets/profile.jpg',
                    ), // Replace with actual asset
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caca',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'caca@gmail.com',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Owner',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFFF0000), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Keluar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFFFF0000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 350;
            final logoFontSize = isSmallScreen ? 16.0 : 20.0;
            final underlineWidth = isSmallScreen ? 50.0 : 80.0;
            final dashboardFontSize = isSmallScreen ? 14.0 : 18.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartLaba',
                  style: GoogleFonts.getFont(
                    'Unbounded',
                    fontWeight: FontWeight.w500,
                    fontSize: logoFontSize,
                    color: Color(0xFF162B5A),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),
                Container(
                  height: 1,
                  width: underlineWidth,
                  color: Color(0xFF162B5A),
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 1 : 2),
                ),
                Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: dashboardFontSize,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 360;
          final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
          final cardSpacing = isSmallScreen ? 8.0 : 12.0;
          final sectionSpacing = isSmallScreen ? 12.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ...existing code...
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.attach_money,
                        iconColor: Colors.indigo,
                        title: 'Pendapatan Hari Ini',
                        value: 'Rp 240.000',
                        growth: '+12.5%',
                        growthColor: Colors.green,
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.shopping_bag,
                        iconColor: Colors.orange,
                        title: 'Transaksi',
                        value: '89',
                        growth: '-5%',
                        growthColor: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: cardSpacing),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.green,
                        title: 'Laba Bersih',
                        value: 'Rp 100.000',
                        growth: '+12.5%',
                        growthColor: Colors.green,
                      ),
                    ),
                    SizedBox(width: cardSpacing),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.percent,
                        iconColor: Colors.amber,
                        title: 'Margin Rata rata',
                        value: '20%',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sectionSpacing),
                _TrendChartCard(),
                SizedBox(height: sectionSpacing),
                _BusinessHealthScoreCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget drawerItem(IconData icon, String title) {
  return ListTile(
    leading: Icon(icon, color: Color(0xFF4D4D4F)),
    title: Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Color(0xFF4D4D4F),
      ),
    ),
    onTap: () {},
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? growth;
  final Color? growthColor;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.growth,
    this.growthColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 160;
        final padding = isSmallScreen ? 12.0 : 16.0;
        final iconSize = isSmallScreen ? 22.0 : 28.0;
        final arrowSize = isSmallScreen ? 14.0 : 16.0;
        final growthFontSize = isSmallScreen ? 10.0 : 12.0;
        final valueFontSize = isSmallScreen ? 16.0 : 20.0;
        final titleFontSize = isSmallScreen ? 11.0 : 13.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: iconSize),
                  const SizedBox(width: 6),
                  if (growth != null)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            Icon(
                              growthColor == Colors.green
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: growthColor,
                              size: arrowSize,
                            ),
                            Text(
                              growth!,
                              style: TextStyle(
                                color: growthColor,
                                fontWeight: FontWeight.bold,
                                fontSize: growthFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: valueFontSize,
                  ),
                ),
              ),
              SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: titleFontSize,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 350;
        final padding = isSmallScreen ? 12.0 : 16.0;
        final titleFontSize = isSmallScreen ? 13.0 : 15.0;
        final spacing = isSmallScreen ? 8.0 : 12.0;
        final chartHeight = isSmallScreen ? 100.0 : 120.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tren 7 hari',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: titleFontSize,
                ),
              ),
              SizedBox(height: spacing),
              Container(
                height: chartHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      'Chart Placeholder',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusinessHealthScoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 350;
        final padding = isSmallScreen ? 16.0 : 20.0;
        final circleSize = isSmallScreen ? 56.0 : 70.0;
        final strokeWidth = isSmallScreen ? 6.0 : 8.0;
        final circleSpacing = isSmallScreen ? 12.0 : 18.0;
        final titleFontSize = isSmallScreen ? 13.0 : 15.0;
        final descFontSize = isSmallScreen ? 10.0 : 12.0;
        final scoreFontSize = isSmallScreen ? 18.0 : 22.0;
        final statusFontSize = isSmallScreen ? 11.0 : 13.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CircularProgressIndicator(
                      value: 0.8,
                      strokeWidth: strokeWidth,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    ),
                  ),
                  Text(
                    '80',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: scoreFontSize,
                    ),
                  ),
                ],
              ),
              SizedBox(width: circleSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Business Health Score',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: titleFontSize,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Text(
                      'Bisnis Anda dalam kondisi baik.\nPertimbangkan diversifikasi menu minuman.',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: descFontSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      'Sehat',
                      style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: statusFontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
