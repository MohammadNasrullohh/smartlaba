import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_service.dart';
import 'login_page.dart';
import 'platform_content.dart';
import 'user_service.dart';

class DeveloperAdminGatePage extends StatelessWidget {
  const DeveloperAdminGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _DeveloperLoadingPage();
        }

        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return const LoginPage();
        }

        return StreamBuilder<UserProfile?>(
          stream: UserService().streamUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                !profileSnapshot.hasData) {
              return const _DeveloperLoadingPage();
            }

            if (profileSnapshot.data?.role == 'Developer') {
              return const DeveloperAdminPage();
            }

            return const _DeveloperAccessDeniedPage();
          },
        );
      },
    );
  }
}

class DeveloperAdminPage extends StatefulWidget {
  const DeveloperAdminPage({super.key});

  @override
  State<DeveloperAdminPage> createState() => _DeveloperAdminPageState();
}

class _DeveloperAdminPageState extends State<DeveloperAdminPage> {
  int _selectedIndex = 0;

  static const _sections = [
    _DeveloperSection(
      label: 'Overview',
      title: 'App Control Center',
      subtitle:
          'Monitor performa aplikasi, website publik, dan konfigurasi platform.',
      icon: Icons.space_dashboard_rounded,
    ),
    _DeveloperSection(
      label: 'Website',
      title: 'Public Website',
      subtitle: 'Edit konten home page, about, dan informasi publik.',
      icon: Icons.language_rounded,
    ),
    _DeveloperSection(
      label: 'Platform',
      title: 'Platform Config',
      subtitle:
          'Atur notice aplikasi, versi, maintenance, dan link distribusi.',
      icon: Icons.settings_suggest_rounded,
    ),
    _DeveloperSection(
      label: 'Broadcast',
      title: 'App Broadcast',
      subtitle:
          'Kirim pengumuman realtime ke aplikasi dan atur target role-nya.',
      icon: Icons.campaign_rounded,
    ),
    _DeveloperSection(
      label: 'Akses',
      title: 'Account Access',
      subtitle: 'Kelola role tim internal dan kontrol login kasir.',
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 286,
              margin: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF162B5A),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartLaba',
                          style: GoogleFonts.unbounded(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ops Center',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _sections.length,
                      itemBuilder: (context, index) {
                        final selected = _selectedIndex == index;
                        final item = _sections[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: selected
                                ? const Color(0xFFFFD269)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.icon,
                                      color: selected
                                          ? const Color(0xFF162B5A)
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? const Color(0xFF162B5A)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: StreamBuilder<UserProfile?>(
                      stream: UserService().streamUserProfile(),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      UserService().getInitials(
                                        profile?.nama ?? 'DV',
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF162B5A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      profile?.email ??
                                          'developer@smartlaba.id',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await AuthService().signOut();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFFFD269),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Keluar',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeveloperHeader(section: section),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          color: Colors.white,
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: const [
                              _DeveloperOverviewSection(),
                              _WebsiteContentSection(),
                              _PlatformConfigSection(),
                              _BroadcastManagerSection(),
                              _AccessManagerSection(),
                            ],
                          ),
                        ),
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

class _DeveloperSection {
  final String label;
  final String title;
  final String subtitle;
  final IconData icon;

  const _DeveloperSection({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _DeveloperLoadingPage extends StatelessWidget {
  const _DeveloperLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF3F1EB),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF162B5A))),
    );
  }
}

class _DeveloperAccessDeniedPage extends StatelessWidget {
  const _DeveloperAccessDeniedPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFD6D0C5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Akses tim internal belum tersedia untuk akun ini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.unbounded(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF162B5A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Atur field role menjadi Developer pada dokumen users agar akun ini bisa membuka pusat kontrol ini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.7,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/'),
                      child: const Text('Kembali ke Home'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeveloperHeader extends StatelessWidget {
  final _DeveloperSection section;

  const _DeveloperHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2D5A), Color(0xFF3057A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.26)),
                ),
                child: const Text('Public Web'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/app'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.26)),
                ),
                child: const Text('Owner Panel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeveloperOverviewSection extends StatelessWidget {
  const _DeveloperOverviewSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('stores').snapshots(),
          builder: (context, storeSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .snapshots(),
              builder: (context, transactionSnapshot) {
                final users = userSnapshot.data?.docs ?? const [];
                final stores = storeSnapshot.data?.docs ?? const [];
                final transactions = transactionSnapshot.data?.docs ?? const [];

                final ownerCount = users
                    .where((doc) => (doc.data()['role'] ?? 'Owner') == 'Owner')
                    .length;
                final developerCount = users
                    .where(
                      (doc) => (doc.data()['role'] ?? 'Owner') == 'Developer',
                    )
                    .length;
                final kasirCount = users
                    .where((doc) => (doc.data()['role'] ?? '') == 'Kasir')
                    .length;

                final latestUsers = [...users]
                  ..sort(
                    (a, b) => _readTimestampMillis(
                      b.data()['updatedAt'],
                    ).compareTo(_readTimestampMillis(a.data()['updatedAt'])),
                  );

                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _MetricCard(
                          label: 'Owner',
                          value: '$ownerCount',
                          color: const Color(0xFF162B5A),
                          icon: Icons.storefront_rounded,
                        ),
                        _MetricCard(
                          label: 'Tim Internal',
                          value: '$developerCount',
                          color: const Color(0xFFF58A2A),
                          icon: Icons.developer_mode_rounded,
                        ),
                        _MetricCard(
                          label: 'Kasir',
                          value: '$kasirCount',
                          color: const Color(0xFF20A029),
                          icon: Icons.people_outline_rounded,
                        ),
                        _MetricCard(
                          label: 'Toko / Transaksi',
                          value: '${stores.length} / ${transactions.length}',
                          color: const Color(0xFF7C3AED),
                          icon: Icons.analytics_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _InternalStatusPanel(),
                    const SizedBox(height: 18),
                    _PanelCard(
                      title: 'Akun Terbaru / Update Terakhir',
                      description:
                          'Membantu tim internal memantau perubahan akun langsung dari Firebase.',
                      child: latestUsers.isEmpty
                          ? Text(
                              'Belum ada akun yang tersimpan.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF777777),
                              ),
                            )
                          : Column(
                              children: latestUsers
                                  .take(8)
                                  .map(
                                    (doc) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _UserInfoTile(data: doc.data()),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9D3C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.unbounded(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _InternalStatusPanel extends StatelessWidget {
  const _InternalStatusPanel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: platformSettingsRef(FirebaseFirestore.instance).snapshots(),
      builder: (context, platformSnapshot) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: appBroadcastRef(FirebaseFirestore.instance).snapshots(),
          builder: (context, broadcastSnapshot) {
            final settings = PlatformSettings.fromMap(
              platformSnapshot.data?.data(),
            );
            final broadcast = AppBroadcastMessage.fromMap(
              broadcastSnapshot.data?.data(),
            );

            return _PanelCard(
              title: 'Status Aplikasi & Website',
              description:
                  'Dipakai tim internal untuk memantau distribusi versi, maintenance, broadcast aplikasi, dan status website publik.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatusBadge(
                    label: 'Versi terbaru',
                    value: settings.latestVersion,
                    color: const Color(0xFF162B5A),
                  ),
                  _StatusBadge(
                    label: 'Minimal versi',
                    value: settings.minimumSupportedVersion,
                    color: const Color(0xFFF58A2A),
                  ),
                  _StatusBadge(
                    label: 'Maintenance',
                    value: settings.maintenanceMode ? 'Aktif' : 'Normal',
                    color: settings.maintenanceMode
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF20A029),
                  ),
                  _StatusBadge(
                    label: 'Website publik',
                    value: settings.webEnabled ? 'Aktif' : 'Nonaktif',
                    color: settings.webEnabled
                        ? const Color(0xFF20A029)
                        : const Color(0xFF6B7280),
                  ),
                  _StatusBadge(
                    label: 'Wajib update',
                    value: settings.forceUpdate ? 'Aktif' : 'Nonaktif',
                    color: settings.forceUpdate
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF6B7280),
                  ),
                  _StatusBadge(
                    label: 'Broadcast app',
                    value: broadcast.isActive ? 'Aktif' : 'Draft',
                    color: broadcast.isActive
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E3E3)),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfoTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _UserInfoTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE7EEF9),
            child: Text(
              UserService().getInitials((data['nama'] ?? 'User').toString()),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF162B5A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['nama'] ?? 'User').toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                Text(
                  (data['email'] ?? '').toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          Text(
            (data['role'] ?? 'Owner').toString(),
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF58A2A),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteContentSection extends StatefulWidget {
  const _WebsiteContentSection();

  @override
  State<_WebsiteContentSection> createState() => _WebsiteContentSectionState();
}

class _WebsiteContentSectionState extends State<_WebsiteContentSection> {
  final _heroTitleController = TextEditingController();
  final _heroSubtitleController = TextEditingController();
  final _aboutTitleController = TextEditingController();
  final _aboutBodyController = TextEditingController();
  final _infoTitleController = TextEditingController();
  final _infoBodyController = TextEditingController();
  final _supportEmailController = TextEditingController();
  bool _hydrated = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _aboutTitleController.dispose();
    _aboutBodyController.dispose();
    _infoTitleController.dispose();
    _infoBodyController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  void _hydrate(PublicSiteContent content) {
    if (_hydrated) {
      return;
    }
    _heroTitleController.text = content.heroTitle;
    _heroSubtitleController.text = content.heroSubtitle;
    _aboutTitleController.text = content.aboutTitle;
    _aboutBodyController.text = content.aboutBody;
    _infoTitleController.text = content.infoTitle;
    _infoBodyController.text = content.infoBody;
    _supportEmailController.text = content.supportEmail;
    _hydrated = true;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      await publicSiteContentRef(FirebaseFirestore.instance).set({
        ...PublicSiteContent(
          heroTitle: _heroTitleController.text.trim(),
          heroSubtitle: _heroSubtitleController.text.trim(),
          aboutTitle: _aboutTitleController.text.trim(),
          aboutBody: _aboutBodyController.text.trim(),
          infoTitle: _infoTitleController.text.trim(),
          infoBody: _infoBodyController.text.trim(),
          supportEmail: _supportEmailController.text.trim(),
          primaryCtaLabel: 'Masuk',
        ).toMap(),
        'secondaryCtaLabel': FieldValue.delete(),
        'updatedByUid': currentUser?.uid,
        'updatedByEmail': currentUser?.email,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Konten website berhasil diperbarui.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade500,
            content: Text(
              'Gagal menyimpan konten website: $error',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: publicSiteContentRef(FirebaseFirestore.instance).snapshots(),
      builder: (context, snapshot) {
        final content = PublicSiteContent.fromMap(snapshot.data?.data());
        _hydrate(content);

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _PanelCard(
              title: 'Hero & Intro Website',
              description:
                  'Konten ini tampil di landing page publik dan bisa diperbarui tanpa rebuild web.',
              child: Column(
                children: [
                  _EditorField(
                    controller: _heroTitleController,
                    label: 'Hero Title',
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _heroSubtitleController,
                    label: 'Hero Subtitle',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PanelCard(
              title: 'Tentang & Info',
              description:
                  'Atur narasi tentang SmartLaba, dukungan, dan info publik.',
              child: Column(
                children: [
                  _EditorField(
                    controller: _aboutTitleController,
                    label: 'About Title',
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _aboutBodyController,
                    label: 'About Body',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _infoTitleController,
                    label: 'Info Title',
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _infoBodyController,
                    label: 'Info Body',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _supportEmailController,
                    label: 'Support Email',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF162B5A),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Simpan Konten Website',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlatformConfigSection extends StatefulWidget {
  const _PlatformConfigSection();

  @override
  State<_PlatformConfigSection> createState() => _PlatformConfigSectionState();
}

class _PlatformConfigSectionState extends State<_PlatformConfigSection> {
  final _appNoticeController = TextEditingController();
  final _latestVersionController = TextEditingController();
  final _minimumVersionController = TextEditingController();
  final _updateMessageController = TextEditingController();
  final _apkDownloadController = TextEditingController();
  final _supportEmailController = TextEditingController();
  bool _maintenanceMode = false;
  bool _forceUpdate = false;
  bool _webEnabled = true;
  bool _hydrated = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _appNoticeController.dispose();
    _latestVersionController.dispose();
    _minimumVersionController.dispose();
    _updateMessageController.dispose();
    _apkDownloadController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  void _hydrate(PlatformSettings settings) {
    if (_hydrated) {
      return;
    }
    _appNoticeController.text = settings.appNotice;
    _latestVersionController.text = settings.latestVersion;
    _minimumVersionController.text = settings.minimumSupportedVersion;
    _updateMessageController.text = settings.updateMessage;
    _apkDownloadController.text = settings.apkDownloadUrl;
    _supportEmailController.text = settings.supportEmail;
    _maintenanceMode = settings.maintenanceMode;
    _forceUpdate = settings.forceUpdate;
    _webEnabled = settings.webEnabled;
    _hydrated = true;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      await platformSettingsRef(FirebaseFirestore.instance).set({
        ...PlatformSettings(
          appNotice: _appNoticeController.text.trim(),
          latestVersion: _latestVersionController.text.trim(),
          minimumSupportedVersion: _minimumVersionController.text.trim(),
          updateMessage: _updateMessageController.text.trim(),
          maintenanceMode: _maintenanceMode,
          forceUpdate: _forceUpdate,
          webEnabled: _webEnabled,
          apkDownloadUrl: _apkDownloadController.text.trim(),
          supportEmail: _supportEmailController.text.trim(),
        ).toMap(),
        'updatedByUid': currentUser?.uid,
        'updatedByEmail': currentUser?.email,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Konfigurasi platform berhasil diperbarui.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade500,
            content: Text(
              'Gagal menyimpan konfigurasi platform: $error',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: platformSettingsRef(FirebaseFirestore.instance).snapshots(),
      builder: (context, snapshot) {
        final settings = PlatformSettings.fromMap(snapshot.data?.data());
        _hydrate(settings);

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _PanelCard(
              title: 'Konfigurasi Platform',
              description:
                  'Dipakai untuk notice aplikasi, mode maintenance, dan status website publik.',
              child: Column(
                children: [
                  _EditorField(
                    controller: _appNoticeController,
                    label: 'App Notice',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _latestVersionController,
                    label: 'Latest Version',
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _minimumVersionController,
                    label: 'Minimum Supported Version',
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _updateMessageController,
                    label: 'Force Update Message',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _apkDownloadController,
                    label: 'APK Download URL',
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _supportEmailController,
                    label: 'Support Email',
                  ),
                  SwitchListTile(
                    value: _maintenanceMode,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() => _maintenanceMode = value);
                    },
                    title: Text(
                      'Maintenance Mode',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SwitchListTile(
                    value: _forceUpdate,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() => _forceUpdate = value);
                    },
                    title: Text(
                      'Force Update Mobile App',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SwitchListTile(
                    value: _webEnabled,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() => _webEnabled = value);
                    },
                    title: Text(
                      'Public Website Enabled',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF162B5A),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Simpan Konfigurasi',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BroadcastManagerSection extends StatefulWidget {
  const _BroadcastManagerSection();

  @override
  State<_BroadcastManagerSection> createState() =>
      _BroadcastManagerSectionState();
}

class _BroadcastManagerSectionState extends State<_BroadcastManagerSection> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _ctaLabelController = TextEditingController();
  final _ctaUrlController = TextEditingController();
  String _targetRole = 'All';
  bool _isActive = false;
  bool _hydrated = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _ctaLabelController.dispose();
    _ctaUrlController.dispose();
    super.dispose();
  }

  void _hydrate(AppBroadcastMessage broadcast) {
    if (_hydrated) {
      return;
    }
    _titleController.text = broadcast.title;
    _bodyController.text = broadcast.body;
    _ctaLabelController.text = broadcast.ctaLabel;
    _ctaUrlController.text = broadcast.ctaUrl;
    _targetRole = _normalizeTargetRole(broadcast.targetRole);
    _isActive = broadcast.isActive;
    _hydrated = true;
  }

  String _normalizeTargetRole(String value) {
    switch (value.trim().toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'kasir':
        return 'Kasir';
      case 'developer':
        return 'Developer';
      default:
        return 'All';
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      await appBroadcastRef(FirebaseFirestore.instance).set({
        ...AppBroadcastMessage(
          isActive: _isActive,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          targetRole: _targetRole,
          ctaLabel: _ctaLabelController.text.trim(),
          ctaUrl: _ctaUrlController.text.trim(),
          updatedAtMillis: 0,
        ).toMap(),
        'updatedByUid': currentUser?.uid,
        'updatedByEmail': currentUser?.email,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Broadcast aplikasi berhasil diperbarui.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade500,
            content: Text(
              'Gagal menyimpan broadcast: $error',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: appBroadcastRef(FirebaseFirestore.instance).snapshots(),
      builder: (context, snapshot) {
        final broadcast = AppBroadcastMessage.fromMap(snapshot.data?.data());
        _hydrate(broadcast);

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _PanelCard(
              title: 'Broadcast Ke Aplikasi',
              description:
                  'Broadcast tampil realtime di aplikasi mobile dan bisa ditargetkan ke semua user, owner, kasir, atau developer.',
              child: Column(
                children: [
                  _EditorField(
                    controller: _titleController,
                    label: 'Judul Broadcast',
                  ),
                  const SizedBox(height: 12),
                  _EditorField(
                    controller: _bodyController,
                    label: 'Isi Broadcast',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Role',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF162B5A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _targetRole,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD6D6D6),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD6D6D6),
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'All',
                                  child: Text('Semua User'),
                                ),
                                DropdownMenuItem(
                                  value: 'Owner',
                                  child: Text('Owner'),
                                ),
                                DropdownMenuItem(
                                  value: 'Kasir',
                                  child: Text('Kasir'),
                                ),
                                DropdownMenuItem(
                                  value: 'Developer',
                                  child: Text('Developer'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _targetRole = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EditorField(
                          controller: _ctaLabelController,
                          label: 'Label Tombol',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EditorField(controller: _ctaUrlController, label: 'CTA URL'),
                  SwitchListTile(
                    value: _isActive,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                    title: Text(
                      'Aktifkan Broadcast',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PanelCard(
              title: 'Preview Broadcast',
              description:
                  'Status aktif akan langsung tampil di banner aplikasi mobile saat dokumen ini diperbarui.',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF162B5A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.trim().isEmpty
                          ? 'Pembaruan SmartLaba'
                          : _titleController.text.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bodyController.text.trim().isEmpty
                          ? 'Isi broadcast akan muncul di sini.'
                          : _bodyController.text.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Target: $_targetRole',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isActive
                                ? const Color(0xFFFFD269)
                                : Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _isActive ? 'Status: Aktif' : 'Status: Draft',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _isActive
                                  ? const Color(0xFF162B5A)
                                  : Colors.white,
                            ),
                          ),
                        ),
                        if (broadcast.updatedAtMillis > 0)
                          Text(
                            'Update: ${DateTime.fromMillisecondsSinceEpoch(broadcast.updatedAtMillis).toLocal()}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.74),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF162B5A),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Kirim Broadcast',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccessManagerSection extends StatelessWidget {
  const _AccessManagerSection();

  Future<void> _updateRole(
    BuildContext context,
    String uid,
    String role,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role berhasil diperbarui ke $role.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade500,
            content: Text(
              'Gagal mengubah role: $error',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleKasirLogin(
    BuildContext context,
    String uid,
    bool enable,
  ) async {
    try {
      final updateData = {
        'isLoginEnabled': enable,
        'isDeleted': !enable,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(uid),
        updateData,
        SetOptions(merge: true),
      );
      batch.set(
        FirebaseFirestore.instance.collection('kasir').doc(uid),
        updateData,
        SetOptions(merge: true),
      );
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable ? 'Login kasir diaktifkan.' : 'Login kasir dinonaktifkan.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade500,
            content: Text(
              'Gagal mengubah akses login kasir: $error',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final users = [...?snapshot.data?.docs]
          ..sort(
            (a, b) => (a.data()['nama'] ?? '').toString().compareTo(
              (b.data()['nama'] ?? '').toString(),
            ),
          );

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              'Promosikan owner menjadi developer atau kontrol login kasir langsung dari website.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            ...users.map((doc) {
              final data = doc.data();
              final role = (data['role'] ?? 'Owner').toString();
              final loginEnabled = data['isLoginEnabled'] != false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE1E1E1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['nama'] ?? 'User').toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (data['email'] ?? '').toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF777777),
                            ),
                          ),
                          if ((data['storeName'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Toko: ${(data['storeName'] ?? '').toString()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: const Color(0xFF777777),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (role == 'Kasir')
                      ElevatedButton(
                        onPressed: () =>
                            _toggleKasirLogin(context, doc.id, !loginEnabled),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: loginEnabled
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          foregroundColor: loginEnabled
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                        child: Text(
                          loginEnabled ? 'Nonaktifkan' : 'Aktifkan',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      DropdownButton<String>(
                        value: role == 'Developer' ? 'Developer' : 'Owner',
                        borderRadius: BorderRadius.circular(16),
                        items: const [
                          DropdownMenuItem(
                            value: 'Owner',
                            child: Text('Owner'),
                          ),
                          DropdownMenuItem(
                            value: 'Developer',
                            child: Text('Developer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null || value == role) {
                            return;
                          }
                          _updateRole(context, doc.id, value);
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.6,
              color: const Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _EditorField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF162B5A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: maxLines,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD6D6D6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD6D6D6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF162B5A)),
            ),
          ),
        ),
      ],
    );
  }
}

int _readTimestampMillis(dynamic value) {
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }
  return 0;
}
