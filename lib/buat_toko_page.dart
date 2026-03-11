import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuatTokoPage extends StatefulWidget {
  const BuatTokoPage({super.key});

  @override
  State<BuatTokoPage> createState() => _BuatTokoPageState();
}

class _BuatTokoPageState extends State<BuatTokoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _namaController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _simpanToko() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final ownerUser = FirebaseAuth.instance.currentUser;
      if (ownerUser == null) {
        throw Exception('Sesi owner tidak ditemukan');
      }

      final stores = FirebaseFirestore.instance.collection('stores');
      final storeDoc = stores.doc();
      final batch = FirebaseFirestore.instance.batch();
      final storeName = _namaController.text.trim();

      batch.set(storeDoc, {
        'name': storeName,
        'desc': _descController.text.trim(),
        'ownerUid': ownerUser.uid,
        'ownerEmail': ownerUser.email ?? '',
        'published_at': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(ownerUser.uid),
        {
          'uid': ownerUser.uid,
          'role': 'Owner',
          'storeId': storeDoc.id,
          'storeName': storeName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400,
          content: Text(
            'Gagal membuat toko: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
      return;
    }
  }

  InputDecoration _inputDecoration({required String hint, int maxLines = 1}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF8C8C8C),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: maxLines > 1 ? 16 : 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6D6D6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF162B5A)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF162B5A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF1F1F1F),
                      ),
                      splashRadius: 18,
                    ),
                    Text(
                      'Buat Toko',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.6, color: Colors.black),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    10,
                    32,
                    10,
                    viewInsetsBottom + 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD0D0D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detail Toko',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A3A),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _buildLabel('Nama Toko *'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _namaController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nama toko wajib diisi';
                                  }
                                  return null;
                                },
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF202020),
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Contoh : Mie Ayam Bejo',
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildLabel('Deskripsi'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descController,
                                minLines: 4,
                                maxLines: 4,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF202020),
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Opsional',
                                  maxLines: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _simpanToko,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF162B5A),
                              disabledBackgroundColor: const Color(
                                0xFF162B5A,
                              ).withValues(alpha: 0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Simpan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
