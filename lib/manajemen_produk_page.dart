import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'akun_page.dart';
import 'app_transitions.dart';
import 'auth_service.dart';
import 'business_ai_pages.dart';
import 'dashboard.dart';
import 'firestore_scope.dart';
import 'laporan_export_page.dart';
import 'login_page.dart';
import 'manajemen_user_page.dart';
import 'penjualan_page.dart';
import 'product_form_page.dart';
import 'tambah_produk_page.dart';
import 'user_service.dart';

class ManajemenProdukPage extends StatefulWidget {
  final bool embedded;

  const ManajemenProdukPage({super.key, this.embedded = false});

  @override
  State<ManajemenProdukPage> createState() => _ManajemenProdukPageState();
}

class _ManajemenProdukPageState extends State<ManajemenProdukPage> {
  final TextEditingController _searchController = TextEditingController();
  late final Future<FirestoreScope?> _scopeFuture;
  String _searchQuery = '';
  String? _selectedKategori;

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

  Future<void> _openCreatePage() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TambahProdukPage()));

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openEditPage(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductFormPage(productId: productId, initialData: data),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (widget.embedded) _buildEmbeddedHeader() else _buildMobileHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: _buildProductList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _openCreatePage,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF162B5A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Tambah Produk',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(color: Colors.white, child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      drawer: const _ManajemenProdukDrawer(),
      body: SafeArea(child: content),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        SizedBox(
          height: 58,
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 22,
                    color: Color(0xFF162B5A),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Manajemen Produk',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Container(height: 0.6, width: double.infinity, color: Colors.black),
      ],
    );
  }

  Widget _buildEmbeddedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen Produk',
            style: GoogleFonts.unbounded(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF162B5A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Katalog di web dan aplikasi mobile memakai sumber data Firebase yang sama.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(VoidCallback onFilterTap) {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim().toLowerCase());
                    },
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Cari Produk',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFFC3C3C3),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9B9B9B),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.tune_rounded, size: 20, color: Color(0xFF3E3E3E)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterLabel(List<String> categories, VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: categories.isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(top: 4, right: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedKategori ?? 'Pilih',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF9B9B9B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(List<String> categories) {
    final button = context.findRenderObject();
    if (button is! RenderBox) {
      return;
    }

    final position = RelativeRect.fromLTRB(button.size.width - 140, 120, 16, 0);

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text('Pilih', style: GoogleFonts.poppins(fontSize: 13)),
        ),
        ...categories.map(
          (category) => PopupMenuItem<String>(
            value: category,
            child: Text(category, style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) {
        return;
      }
      setState(() => _selectedKategori = value == '__all__' ? null : value);
    });
  }

  Widget _buildProductList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildMessageState('User tidak ditemukan.');
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
        if (scope == null || scope.dataOwnerUid.isEmpty) {
          return _buildMessageState('Scope toko tidak ditemukan.');
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(scope.dataOwnerUid)
              .collection('produk')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF162B5A)),
              );
            }

            if (snapshot.hasError) {
              return _buildMessageState('Gagal memuat produk.');
            }

            final docs = (snapshot.data?.docs ?? [])
                .where(
                  (doc) => matchesScopedSubcollectionData(
                    data: doc.data(),
                    scope: scope,
                  ),
                )
                .toList();
            final categories =
                docs
                    .map(
                      (doc) => (doc.data()['kategori'] ?? '').toString().trim(),
                    )
                    .where((item) => item.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

            final filteredDocs = docs.where((doc) {
              final data = doc.data();
              final query = _searchQuery;
              final searchableText =
                  '${data['namaProduk'] ?? ''} ${data['kategori'] ?? ''} ${data['kode'] ?? ''} ${data['deskripsi'] ?? ''}'
                      .toLowerCase();
              final matchesSearch = query.isEmpty
                  ? true
                  : searchableText.contains(query);
              final matchesCategory = _selectedKategori == null
                  ? true
                  : (data['kategori'] ?? '').toString() == _selectedKategori;
              return matchesSearch && matchesCategory;
            }).toList();

            return Column(
              children: [
                _buildSearchBar(() => _showFilterMenu(categories)),
                _buildFilterLabel(
                  categories,
                  () => _showFilterMenu(categories),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredDocs.isEmpty
                      ? docs.isEmpty
                            ? _buildEmptyState()
                            : _buildMessageState('Produk tidak ditemukan.')
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            return _buildProductCard(doc.id, doc.data());
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(String productId, Map<String, dynamic> data) {
    final hargaBeli = _readNumber(data['hargaBeli']);
    final hargaJual = _readNumber(data['hargaJual']);
    final stok = _readNumber(data['stok']).round();
    final margin = hargaJual > 0
        ? (((hargaJual - hargaBeli) / hargaJual) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5D5D5)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 54,
                  height: 54,
                  color: const Color(0xFFE7E7E7),
                  child: (data['gambarURL'] ?? '').toString().trim().isNotEmpty
                      ? Image.network(
                          (data['gambarURL'] ?? '').toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFF7B7B7B),
                          ),
                        )
                      : const Icon(
                          Icons.fastfood_rounded,
                          size: 28,
                          color: Color(0xFF7B7B7B),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (data['namaProduk'] ?? 'Produk').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A2A2A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (data['deskripsi'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (data['kategori'] ?? '-').toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stok $stok',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF444444),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openEditPage(productId, data),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 0.6,
            width: double.infinity,
            color: const Color(0xFF9C9C9C),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetricColumn('Beli', _formatCurrency(hargaBeli)),
              _buildMetricColumn('Jual', _formatCurrency(hargaJual)),
              _buildMetricColumn(
                'Margin',
                '$margin %',
                valueColor: const Color(0xFF58E24B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(
    String label,
    String value, {
    Color valueColor = const Color(0xFF2A2A2A),
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF787878),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 148,
            height: 148,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -0.16,
                  child: Container(
                    width: 74,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE987B9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: 0.14,
                  child: Container(
                    width: 92,
                    height: 108,
                    decoration: BoxDecoration(
                      color: const Color(0xFF73D7A4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3D8D72)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 4; i++) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Color(0xFF2F8E6A),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 34,
                                height: 2,
                                color: const Color(0xFF2F8E6A),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 24,
                  left: 20,
                  child: Container(
                    width: 34,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7DE0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Positioned(
                  right: 10,
                  bottom: 18,
                  child: Icon(
                    Icons.ads_click_rounded,
                    size: 34,
                    color: Color(0xFF9AA4C4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Anda Belum Menambahkan Produk',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A2A2A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState(String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: const Color(0xFF666666),
        ),
      ),
    );
  }

  num _readNumber(dynamic value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _formatCurrency(num value) {
    final raw = value.round().toString();
    final formatted = raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $formatted';
  }
}

class _ProductDrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ProductDrawerMenuItem({
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
                  Icon(icon, color: foregroundColor, size: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: foregroundColor,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
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

class _ManajemenProdukDrawer extends StatelessWidget {
  const _ManajemenProdukDrawer();

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
                  _ProductDrawerMenuItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        buildSmoothRoute(const DashboardPage()),
                      );
                    },
                  ),
                  _ProductDrawerMenuItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Manajemen Produk',
                    selected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _ProductDrawerMenuItem(
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
                  _ProductDrawerMenuItem(
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
                  _ProductDrawerMenuItem(
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
                  _ProductDrawerMenuItem(
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
                  _ProductDrawerMenuItem(
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
                  _ProductDrawerMenuItem(
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
