import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tambah_kasir_page.dart';

class ManajemenUserPage extends StatefulWidget {
  final bool embedded;

  const ManajemenUserPage({super.key, this.embedded = false});

  @override
  State<ManajemenUserPage> createState() => _ManajemenUserPageState();
}

class _ManajemenUserPageState extends State<ManajemenUserPage> {
  int _selectedTab = 0; // 0 = Owner, 1 = Kasir

  String get _ownerUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded) _buildEmbeddedHeader(),
        if (!widget.embedded) const SizedBox(height: 20),
        // Tab Kelola Akun
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Kelola Akun',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Tab Buttons with live count
        _buildTabButtons(),
        const SizedBox(height: 20),
        // Daftar Pengguna
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Daftar Pengguna',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // User List from Firestore
        Expanded(
          child: _selectedTab == 0 ? _buildOwnerList() : _buildKasirList(),
        ),
        // Tambah Kasir Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TambahKasirPage(),
                  ),
                );
                if (result == true) {
                  setState(() {}); // Refresh
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF162B5A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                'Tambah Kasir',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFFFFDFA),
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
      backgroundColor: Colors.white,
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
            'Manajemen User',
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
      body: content,
    );
  }

  Widget _buildEmbeddedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen User',
            style: GoogleFonts.unbounded(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF162B5A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambah dan kelola akun owner maupun kasir langsung dari panel admin web.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kasir')
          .where('ownerUid', isEqualTo: _ownerUid)
          .snapshots(),
      builder: (context, kasirSnapshot) {
        final visibleKasirCount = (kasirSnapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isDeleted'] != true;
        }).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SizedBox(
              width: 258,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAccountTab(
                    count: '1',
                    label: 'Owner',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 4),
                  _buildAccountTab(
                    count: '$visibleKasirCount',
                    label: 'Kasir',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountTab({
    required String count,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 127,
        height: 61,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000103),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 3),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerList() {
    final uid = _ownerUid;
    if (uid.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0),
        children: [
          _buildUserCard(
            name: 'Owner',
            role: 'Owner',
            detail: FirebaseAuth.instance.currentUser?.email ?? '',
            isActive: true,
            canDelete: false,
            onEdit: null,
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final ownerName = data?['nama'] ?? currentUser?.displayName ?? 'Owner';

        return ListView(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0),
          children: [
            _buildUserCard(
              name: ownerName,
              role: 'Owner',
              detail: data?['email'] ?? currentUser?.email ?? '',
              isActive: true,
              canDelete: false,
              onEdit: () => _showEditDialog(
                userId: uid,
                initialName: ownerName,
                initialUsername: null,
                role: 'Owner',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKasirList() {
    if (_ownerUid.isEmpty) {
      return Center(
        child: Text(
          'Owner tidak ditemukan',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kasir')
          .where('ownerUid', isEqualTo: _ownerUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat data kasir',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        final docs =
            (snapshot.data?.docs ?? []).where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isDeleted'] != true;
            }).toList()..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              return _readTimestampMillis(
                aData['createdAt'],
              ).compareTo(_readTimestampMillis(bData['createdAt']));
            });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Belum ada kasir',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Tambahkan kasir dengan tombol di bawah',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 8.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final kasirData = docs[index].data() as Map<String, dynamic>;
            return _buildUserCard(
              name: kasirData['nama'] ?? 'Kasir',
              role: 'Kasir',
              detail: kasirData['username'] != null
                  ? '@${kasirData['username']}'
                  : (kasirData['email'] ?? ''),
              isActive: kasirData['isActive'] ?? false,
              canDelete: true,
              onEdit: () => _showEditDialog(
                userId: docs[index].id,
                initialName: kasirData['nama'] ?? 'Kasir',
                initialUsername: (kasirData['username'] ?? '').toString(),
                role: 'Kasir',
              ),
              onDelete: () => _showDeleteDialog(
                kasirData['nama'] ?? 'Kasir',
                docs[index].id,
              ),
            );
          },
        );
      },
    );
  }

  int _readTimestampMillis(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    if (value is int) {
      return value;
    }
    return 0;
  }

  Widget _buildUserCard({
    required String name,
    required String role,
    required String detail,
    required bool isActive,
    required bool canDelete,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: role == 'Owner'
                        ? const Color(0xFFF9822D)
                        : const Color(0xFF666666),
                  ),
                ),
                if (detail.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF74FF5C)
                  : const Color(0xFF808080),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'Aktif' : 'Offline',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.black : const Color(0xFFFFFFFF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Edit Button
          GestureDetector(
            onTap: onEdit,
            child: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Color(0xFF666666),
            ),
          ),
          // Delete Button (only for Kasir)
          if (canDelete) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Color(0xFFFF0000),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFeedback(String message, Color backgroundColor) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _showEditDialog({
    required String userId,
    required String initialName,
    required String? initialUsername,
    required String role,
  }) async {
    final result = await showDialog<_EditUserDialogResult>(
      context: context,
      builder: (_) => _EditUserDialog(
        userId: userId,
        initialName: initialName,
        initialUsername: initialUsername,
        role: role,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    _showFeedback(result.message, result.success ? Colors.green : Colors.red);
  }

  void _showDeleteDialog(String userName, String kasirDocId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hapus User',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Kasir yang dihapus akan dinonaktifkan dan tidak bisa login lagi. Lanjut hapus $userName?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: const Color(0xFF666666)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final batch = FirebaseFirestore.instance.batch();
                  final deleteData = {
                    'isDeleted': true,
                    'isLoginEnabled': false,
                    'isActive': false,
                    'deletedAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  batch.set(
                    FirebaseFirestore.instance
                        .collection('kasir')
                        .doc(kasirDocId),
                    deleteData,
                    SetOptions(merge: true),
                  );
                  batch.set(
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(kasirDocId),
                    deleteData,
                    SetOptions(merge: true),
                  );

                  await batch.commit();

                  _showFeedback('$userName berhasil dihapus', Colors.green);
                } catch (e) {
                  _showFeedback('Gagal menghapus: $e', Colors.red);
                }
              },
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFF0000),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EditUserDialogResult {
  final bool success;
  final String message;

  const _EditUserDialogResult({required this.success, required this.message});
}

class _EditUserDialog extends StatefulWidget {
  final String userId;
  final String initialName;
  final String? initialUsername;
  final String role;

  const _EditUserDialog({
    required this.userId,
    required this.initialName,
    required this.initialUsername,
    required this.role,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  bool _isSaving = false;
  String? _errorText;

  bool get _isKasir => widget.role == 'Kasir';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _usernameController = TextEditingController(
      text: widget.initialUsername ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String _normalizeUsername(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final newName = _nameController.text.trim();
    final newUsername = _normalizeUsername(_usernameController.text);
    final firestore = FirebaseFirestore.instance;

    try {
      if (_isKasir) {
        if (newUsername.isEmpty) {
          throw Exception('Username tidak boleh kosong');
        }

        final previousUsername = _normalizeUsername(
          widget.initialUsername ?? '',
        );
        if (newUsername != previousUsername) {
          final existingUsername = await firestore
              .collection('kasir')
              .where('usernameKey', isEqualTo: newUsername)
              .limit(2)
              .get();

          final usernameUsed = existingUsername.docs.any(
            (doc) => doc.id != widget.userId && doc.data()['isDeleted'] != true,
          );

          if (usernameUsed) {
            throw Exception('Username sudah digunakan');
          }
        }
      }

      final updateData = <String, dynamic>{
        'nama': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isKasir) {
        updateData['username'] = newUsername;
        updateData['usernameKey'] = newUsername;
      }

      if (widget.role == 'Owner') {
        final batch = firestore.batch();
        batch.set(
          firestore.collection('users').doc(widget.userId),
          updateData,
          SetOptions(merge: true),
        );

        final kasirSnapshot = await firestore
            .collection('kasir')
            .where('ownerUid', isEqualTo: widget.userId)
            .get();
        for (final kasirDoc in kasirSnapshot.docs) {
          final ownerPatch = {
            'ownerName': newName,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          batch.set(
            firestore.collection('kasir').doc(kasirDoc.id),
            ownerPatch,
            SetOptions(merge: true),
          );
          batch.set(
            firestore.collection('users').doc(kasirDoc.id),
            ownerPatch,
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        if (FirebaseAuth.instance.currentUser?.uid == widget.userId) {
          await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
        }
      } else {
        final batch = firestore.batch();
        batch.set(
          firestore.collection('kasir').doc(widget.userId),
          updateData,
          SetOptions(merge: true),
        );
        batch.set(
          firestore.collection('users').doc(widget.userId),
          updateData,
          SetOptions(merge: true),
        );
        await batch.commit();

        if (FirebaseAuth.instance.currentUser?.uid == widget.userId) {
          await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        _EditUserDialogResult(
          success: true,
          message: '${widget.role} berhasil diperbarui',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Edit ${widget.role}',
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nama',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            if (_isKasir) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorText!,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Batal',
            style: GoogleFonts.poppins(color: const Color(0xFF666666)),
          ),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Simpan',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF162B5A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
