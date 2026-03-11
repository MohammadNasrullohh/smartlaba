import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'platform_content.dart';

class PublicWebHomePage extends StatefulWidget {
  const PublicWebHomePage({super.key});

  @override
  State<PublicWebHomePage> createState() => _PublicWebHomePageState();
}

class _PublicWebHomePageState extends State<PublicWebHomePage> {
  final _homeKey = GlobalKey();
  final _productKey = GlobalKey();
  final _featureKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _infoKey = GlobalKey();

  String _resolveDownloadUrl(PlatformSettings settings) {
    final apkUrl = settings.apkDownloadUrl.trim();
    if (apkUrl.isNotEmpty) {
      return apkUrl;
    }

    final supportEmail = settings.supportEmail.trim();
    if (supportEmail.isNotEmpty) {
      return 'mailto:$supportEmail';
    }

    return '';
  }

  Future<void> _openDownload(
    BuildContext context,
    PlatformSettings settings,
  ) async {
    final rawUrl = _resolveDownloadUrl(settings);
    if (rawUrl.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Link download aplikasi belum tersedia.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Link download aplikasi tidak valid.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      );
      return;
    }

    final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Gagal membuka link download aplikasi.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: publicSiteContentRef(FirebaseFirestore.instance).snapshots(),
      builder: (context, publicSnapshot) {
        final content = PublicSiteContent.fromMap(publicSnapshot.data?.data());

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: platformSettingsRef(FirebaseFirestore.instance).snapshots(),
          builder: (context, platformSnapshot) {
            final settings = PlatformSettings.fromMap(
              platformSnapshot.data?.data(),
            );

            return Scaffold(
              backgroundColor: const Color(0xFFF7F4ED),
              body: SafeArea(
                child: settings.webEnabled
                    ? _PublicWebBody(
                        content: content,
                        settings: settings,
                        downloadUrl: _resolveDownloadUrl(settings),
                        homeKey: _homeKey,
                        productKey: _productKey,
                        featureKey: _featureKey,
                        aboutKey: _aboutKey,
                        infoKey: _infoKey,
                        onHomeTap: () => _scrollTo(_homeKey),
                        onProductTap: () => _scrollTo(_productKey),
                        onFeatureTap: () => _scrollTo(_featureKey),
                        onAboutTap: () => _scrollTo(_aboutKey),
                        onInfoTap: () => _scrollTo(_infoKey),
                        onDownloadTap: () => _openDownload(context, settings),
                      )
                    : _WebDisabledState(settings: settings),
              ),
            );
          },
        );
      },
    );
  }
}

class _PublicWebBody extends StatelessWidget {
  final PublicSiteContent content;
  final PlatformSettings settings;
  final String downloadUrl;
  final GlobalKey homeKey;
  final GlobalKey productKey;
  final GlobalKey featureKey;
  final GlobalKey aboutKey;
  final GlobalKey infoKey;
  final VoidCallback onHomeTap;
  final VoidCallback onProductTap;
  final VoidCallback onFeatureTap;
  final VoidCallback onAboutTap;
  final VoidCallback onInfoTap;
  final VoidCallback onDownloadTap;

  const _PublicWebBody({
    required this.content,
    required this.settings,
    required this.downloadUrl,
    required this.homeKey,
    required this.productKey,
    required this.featureKey,
    required this.aboutKey,
    required this.infoKey,
    required this.onHomeTap,
    required this.onProductTap,
    required this.onFeatureTap,
    required this.onAboutTap,
    required this.onInfoTap,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: _HomeBackdrop())),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  children: [
                    _WebTopBar(
                      downloadUrl: downloadUrl,
                      onHomeTap: onHomeTap,
                      onProductTap: onProductTap,
                      onFeatureTap: onFeatureTap,
                      onAboutTap: onAboutTap,
                      onInfoTap: onInfoTap,
                      onDownloadTap: onDownloadTap,
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          KeyedSubtree(
                            key: homeKey,
                            child: _HeroSection(
                              content: content,
                              settings: settings,
                              downloadUrl: downloadUrl,
                              onExploreTap: onProductTap,
                              onDownloadTap: onDownloadTap,
                            ),
                          ),
                          const SizedBox(height: 30),
                          KeyedSubtree(
                            key: productKey,
                            child: const _ProductSuiteSection(),
                          ),
                          const SizedBox(height: 30),
                          KeyedSubtree(
                            key: featureKey,
                            child: const _FeatureSection(),
                          ),
                          const SizedBox(height: 30),
                          const _WorkflowSection(),
                          const SizedBox(height: 30),
                          KeyedSubtree(
                            key: aboutKey,
                            child: _AboutInfoSection(
                              content: content,
                              settings: settings,
                            ),
                          ),
                          const SizedBox(height: 30),
                          KeyedSubtree(
                            key: infoKey,
                            child: const _AudienceSection(),
                          ),
                          const SizedBox(height: 30),
                          _PublicCtaSection(
                            settings: settings,
                            downloadUrl: downloadUrl,
                            onDownloadTap: onDownloadTap,
                          ),
                          const SizedBox(height: 30),
                          _FooterSection(content: content, settings: settings),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFE3B0).withValues(alpha: 0.55),
                  const Color(0xFFFFE3B0).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 180,
          right: -110,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8FB5FF).withValues(alpha: 0.28),
                  const Color(0xFF8FB5FF).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: 120,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1F4A95).withValues(alpha: 0.12),
                  const Color(0xFF1F4A95).withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WebTopBar extends StatelessWidget {
  final String downloadUrl;
  final VoidCallback onHomeTap;
  final VoidCallback onProductTap;
  final VoidCallback onFeatureTap;
  final VoidCallback onAboutTap;
  final VoidCallback onInfoTap;
  final VoidCallback onDownloadTap;

  const _WebTopBar({
    required this.downloadUrl,
    required this.onHomeTap,
    required this.onProductTap,
    required this.onFeatureTap,
    required this.onAboutTap,
    required this.onInfoTap,
    required this.onDownloadTap,
  });

  void _handleMenu(BuildContext context, String value) {
    switch (value) {
      case 'home':
        onHomeTap();
        break;
      case 'product':
        onProductTap();
        break;
      case 'feature':
        onFeatureTap();
        break;
      case 'about':
        onAboutTap();
        break;
      case 'info':
        onInfoTap();
        break;
      case 'download':
        onDownloadTap();
        break;
      case 'login':
        Navigator.of(context).pushNamed('/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDownload = downloadUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD9D2C6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;

          final brand = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF162B5A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SmartLaba',
                    style: GoogleFonts.unbounded(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF162B5A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Solusi bisnis modern untuk toko dan usaha',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5F6672),
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: brand),
                PopupMenuButton<String>(
                  tooltip: 'Menu navigasi',
                  onSelected: (value) => _handleMenu(context, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'home', child: Text('Home')),
                    const PopupMenuItem(
                      value: 'product',
                      child: Text('Produk'),
                    ),
                    const PopupMenuItem(value: 'feature', child: Text('Fitur')),
                    const PopupMenuItem(value: 'about', child: Text('Tentang')),
                    const PopupMenuItem(value: 'info', child: Text('Info')),
                    if (hasDownload) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'download',
                        child: Text('Download App'),
                      ),
                    ],
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'login', child: Text('Masuk')),
                  ],
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EFE5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF162B5A),
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: brand),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _NavTextButton(label: 'Home', onTap: onHomeTap),
                        _NavTextButton(label: 'Produk', onTap: onProductTap),
                        _NavTextButton(label: 'Fitur', onTap: onFeatureTap),
                        _NavTextButton(label: 'Tentang', onTap: onAboutTap),
                        _NavTextButton(label: 'Info', onTap: onInfoTap),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (hasDownload)
                          _TopBarButton(
                            label: 'Download App',
                            filled: false,
                            icon: Icons.download_rounded,
                            onTap: onDownloadTap,
                          ),
                        _TopBarButton(
                          label: 'Masuk',
                          filled: true,
                          icon: Icons.login_rounded,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFF162B5A), Color(0xFF23458E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: filled ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled ? Colors.transparent : const Color(0xFFD6D1C7),
          ),
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: Color(0x22162B5A),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled ? Colors.white : const Color(0xFF162B5A),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : const Color(0xFF162B5A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavTextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6DFD3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF485262),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final PublicSiteContent content;
  final PlatformSettings settings;
  final String downloadUrl;
  final VoidCallback onExploreTap;
  final VoidCallback onDownloadTap;

  const _HeroSection({
    required this.content,
    required this.settings,
    required this.downloadUrl,
    required this.onExploreTap,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 950;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 24 : 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10224A), Color(0xFF1F4A95), Color(0xFF5A88D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26162B5A),
                blurRadius: 34,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -40,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCopy(
                      content: content,
                      settings: settings,
                      downloadUrl: downloadUrl,
                      onExploreTap: onExploreTap,
                      onDownloadTap: onDownloadTap,
                    ),
                    const SizedBox(height: 24),
                    const _HeroVisual(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _HeroCopy(
                        content: content,
                        settings: settings,
                        downloadUrl: downloadUrl,
                        onExploreTap: onExploreTap,
                        onDownloadTap: onDownloadTap,
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Expanded(child: _HeroVisual()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final PublicSiteContent content;
  final PlatformSettings settings;
  final String downloadUrl;
  final VoidCallback onExploreTap;
  final VoidCallback onDownloadTap;

  const _HeroCopy({
    required this.content,
    required this.settings,
    required this.downloadUrl,
    required this.onExploreTap,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDownload = downloadUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroStatChip(
              icon: Icons.language_rounded,
              label: 'Public web siap rilis',
            ),
            _HeroStatChip(
              icon: Icons.sync_alt_rounded,
              label: 'Siap untuk bisnis modern',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'SmartLaba',
          style: GoogleFonts.unbounded(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          content.heroTitle,
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFE2AE),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          content.heroSubtitle,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            height: 1.75,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _HeroStatChip(
              icon: Icons.storefront_rounded,
              label: 'Dashboard bisnis yang ringkas',
            ),
            _HeroStatChip(
              icon: Icons.point_of_sale_rounded,
              label: 'Operasional toko dibuat lebih praktis',
            ),
          ],
        ),
        if (settings.appNotice.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              settings.appNotice,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _HeroActionButton(
              label: 'Masuk',
              filled: true,
              onTap: () => Navigator.of(context).pushNamed('/login'),
            ),
            if (hasDownload)
              _HeroActionButton(
                label: 'Download App',
                filled: false,
                onTap: onDownloadTap,
              ),
            _HeroActionButton(
              label: 'Lihat Modul',
              filled: false,
              onTap: onExploreTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFE2AE)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: filled ? const Color(0xFFFFD269) : Colors.white,
        foregroundColor: const Color(0xFF162B5A),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        side: filled
            ? BorderSide.none
            : BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Workspace web ready',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.rocket_launch_rounded,
                color: const Color(0xFFFFE2AE),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7EEF9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_graph_rounded,
                            color: Color(0xFF21408A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Operasional toko, website publik, dan insight AI tetap berada di satu alur kerja.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1E1E),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        children: const [
                          Expanded(
                            child: _PreviewCard(
                              title: 'Business Panel',
                              subtitle: 'Dashboard, produk, laporan, AI',
                              accent: Color(0xFF244287),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _PreviewCard(
                              title: 'Public Website',
                              subtitle: 'Brand, info produk, CTA login',
                              accent: Color(0xFFF58A2A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _PreviewMetricStrip(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;

  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.6,
              color: const Color(0xFF5F6672),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMetricStrip extends StatelessWidget {
  const _PreviewMetricStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Bisnis', 'Produk, tim, insight'),
      ('Kasir', 'Transaksi cepat'),
      ('Public', 'Landing siap rilis'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${item.$1}  ${item.$2}',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF244287),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    const features = [
      (
        Icons.storefront_rounded,
        'Multi toko & manajemen bisnis',
        'Kelola banyak toko, tim, dan operasional harian dalam satu platform.',
      ),
      (
        Icons.analytics_rounded,
        'Insight AI untuk bisnis',
        'Dapatkan ringkasan performa bisnis dan rekomendasi untuk membantu pengambilan keputusan.',
      ),
      (
        Icons.point_of_sale_rounded,
        'Penjualan & kasir cepat',
        'Proses transaksi dibuat ringkas agar tim bisa bekerja lebih cepat sepanjang hari.',
      ),
      (
        Icons.inventory_2_rounded,
        'Produk, kategori, dan stok',
        'Tambah produk, edit harga beli/jual, kategori, dan stok awal dengan alur kerja yang mudah dipakai di berbagai perangkat.',
      ),
      (
        Icons.file_download_rounded,
        'Laporan bisnis',
        'Pantau ringkasan penjualan dan siapkan laporan untuk kebutuhan bisnis harian.',
      ),
      (
        Icons.language_rounded,
        'Public web & aplikasi',
        'Website publik dan pembaruan aplikasi dapat dikelola lebih rapi dalam satu tempat.',
      ),
    ];

    return Column(
      children: [
        const _SectionHeading(
          eyebrow: 'Fitur Lengkap',
          title:
              'Satu produk untuk operasional, analitik, dan distribusi aplikasi.',
          body:
              'SmartLaba bukan hanya aplikasi kasir. Operasional, insight AI, website publik, dan pengelolaan layanan dirancang dalam pengalaman yang lebih rapi.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: features
              .map(
                (feature) => SizedBox(
                  width: 360,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFD8D1C3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7EEF9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            feature.$1,
                            color: const Color(0xFF21408A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          feature.$2,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature.$3,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.6,
                            color: const Color(0xFF686868),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD9D2C6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2DE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              eyebrow.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: const Color(0xFFF58A2A),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.unbounded(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.7,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSuiteSection extends StatelessWidget {
  const _ProductSuiteSection();

  @override
  Widget build(BuildContext context) {
    const modules = [
      (
        'Dashboard Bisnis',
        'Pantau omzet, transaksi, margin, AI insight, dan kondisi bisnis harian.',
        Icons.space_dashboard_rounded,
        Color(0xFF162B5A),
      ),
      (
        'Manajemen Produk',
        'Tambah, edit, dan kategorikan produk dengan alur kerja yang ringkas.',
        Icons.inventory_2_rounded,
        Color(0xFF3057A5),
      ),
      (
        'Manajemen User',
        'Atur tim, hak akses login, dan pengelolaan toko dari satu dashboard.',
        Icons.group_rounded,
        Color(0xFFF58A2A),
      ),
      (
        'Insight AI',
        'Ringkasan performa bisnis dan rekomendasi untuk mendukung keputusan harian.',
        Icons.auto_awesome_rounded,
        Color(0xFF20A029),
      ),
      (
        'Laporan Bisnis',
        'Ringkas data penjualan untuk kebutuhan operasional dan evaluasi.',
        Icons.file_download_rounded,
        Color(0xFF7C3AED),
      ),
      (
        'Website & Aplikasi',
        'Kelola website publik dan pembaruan aplikasi dari satu tempat.',
        Icons.admin_panel_settings_rounded,
        Color(0xFF111B37),
      ),
    ];

    return Column(
      children: [
        const _SectionHeading(
          eyebrow: 'Produk Suite',
          title:
              'Modul SmartLaba untuk operasional bisnis, tim, dan pengunjung publik.',
          body:
              'Website, aplikasi, dan pengelolaan operasional dirancang dalam satu alur kerja yang rapi.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: modules
              .map(
                (module) => SizedBox(
                  width: 360,
                  child: _ProductModuleCard(
                    title: module.$1,
                    body: module.$2,
                    icon: module.$3,
                    color: module.$4,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ProductModuleCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _ProductModuleCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Unggulan',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.7,
              color: const Color(0xFF686868),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Dirancang untuk alur kerja yang praktis dan rapi.',
              style: GoogleFonts.poppins(
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5F6672),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        '1. Mulai dengan mudah',
        'Buat akun, aktifkan layanan, lalu siapkan toko pertama dari mobile atau web.',
      ),
      (
        '2. Aktifkan operasional',
        'Produk, kategori, kasir, dan transaksi mulai berjalan dengan alur yang rapi.',
      ),
      (
        '3. Analisis & scaling',
        'Dashboard AI, laporan, dan public website memberi insight untuk keputusan harga, stok, dan ekspansi.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF111B37),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alur Implementasi',
            style: GoogleFonts.unbounded(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Struktur ini memudahkan onboarding bisnis baru tanpa memisahkan aplikasi, website, dan data operasional.',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: steps
                .map(
                  (step) => SizedBox(
                    width: 340,
                    child: _WorkflowStepCard(title: step.$1, body: step.$2),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  final String title;
  final String body;

  const _WorkflowStepCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicCtaSection extends StatelessWidget {
  final PlatformSettings settings;
  final String downloadUrl;
  final VoidCallback onDownloadTap;

  const _PublicCtaSection({
    required this.settings,
    required this.downloadUrl,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDownload = downloadUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF4FF), Color(0xFFFFF8EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD8D1C3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SIAP RILIS',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: const Color(0xFF162B5A),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Siap tampil di web, siap dipakai bisnis setiap hari.',
                style: GoogleFonts.unbounded(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF162B5A),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Homepage publik kini lebih rapi untuk presentasi brand, informasi produk, dan ajakan download atau masuk aplikasi.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.7,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasDownload)
                _HeroActionButton(
                  label: 'Download App',
                  filled: false,
                  onTap: onDownloadTap,
                ),
              _HeroActionButton(
                label: 'Masuk',
                filled: true,
                onTap: () => Navigator.of(context).pushNamed('/login'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  hasDownload
                      ? 'Versi ${settings.latestVersion} siap diunduh dari web.'
                      : 'UI web lebih ringkas dan siap untuk publik.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF162B5A),
                  ),
                ),
              ),
            ],
          );

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 18), actions],
                )
              : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 18),
                    Flexible(child: actions),
                  ],
                );
        },
      ),
    );
  }
}

class _AboutInfoSection extends StatelessWidget {
  final PublicSiteContent content;
  final PlatformSettings settings;

  const _AboutInfoSection({required this.content, required this.settings});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        final leftCard = _InfoBlock(
          eyebrow: 'Tentang',
          title: content.aboutTitle,
          body: content.aboutBody,
          accentColor: const Color(0xFF162B5A),
        );
        final rightCard = _InfoBlock(
          eyebrow: 'Info',
          title: content.infoTitle,
          body:
              '${content.infoBody}\n\nEmail dukungan: ${settings.supportEmail.isNotEmpty ? settings.supportEmail : content.supportEmail}\nVersi aplikasi: ${settings.latestVersion}',
          accentColor: const Color(0xFFF58A2A),
        );

        return compact
            ? Column(
                children: [leftCard, const SizedBox(height: 18), rightCard],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftCard),
                  const SizedBox(width: 18),
                  Expanded(child: rightCard),
                ],
              );
      },
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final Color accentColor;

  const _InfoBlock({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD9D2C6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.unbounded(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.75,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceSection extends StatelessWidget {
  const _AudienceSection();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (
        'Pemilik usaha',
        'Akses dashboard, laporan, dan pengelolaan bisnis dengan lebih mudah.',
      ),
      (
        'Tim operasional',
        'Gunakan aplikasi untuk mendukung aktivitas toko dan layanan harian.',
      ),
      (
        'Pengunjung publik',
        'Lihat info SmartLaba tanpa harus download APK dulu.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111B37),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: items
            .map(
              (item) => SizedBox(
                width: 320,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  final PublicSiteContent content;
  final PlatformSettings settings;

  const _FooterSection({required this.content, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD8D1C3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final brandBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartLaba',
                style: GoogleFonts.unbounded(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF162B5A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Public web SmartLaba dirancang untuk memperkenalkan brand, produk, dan akses aplikasi dalam tampilan yang lebih profesional.',
                style: GoogleFonts.poppins(
                  fontSize: 12.8,
                  height: 1.7,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          );
          final actions = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  settings.supportEmail.isNotEmpty
                      ? settings.supportEmail
                      : content.supportEmail,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF162B5A),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  _FooterLink(
                    label: 'Masuk',
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                  ),
                  _FooterLink(
                    label: 'Syarat',
                    onTap: () => Navigator.of(context).pushNamed('/terms'),
                  ),
                  _FooterLink(
                    label: 'Privasi',
                    onTap: () => Navigator.of(context).pushNamed('/privacy'),
                  ),
                ],
              ),
            ],
          );

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [brandBlock, const SizedBox(height: 18), actions],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: brandBlock),
                    const SizedBox(width: 18),
                    actions,
                  ],
                );
        },
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF162B5A),
        ),
      ),
    );
  }
}

class _WebDisabledState extends StatelessWidget {
  final PlatformSettings settings;

  const _WebDisabledState({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD8D1C3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Website SmartLaba sedang dinonaktifkan sementara.',
                textAlign: TextAlign.center,
                style: GoogleFonts.unbounded(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF162B5A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                settings.appNotice.trim().isEmpty
                    ? 'Silakan hubungi administrator untuk informasi lebih lanjut.'
                    : settings.appNotice,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.7,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF162B5A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Kembali ke Home',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
