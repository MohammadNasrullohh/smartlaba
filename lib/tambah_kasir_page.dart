import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class TambahKasirPage extends StatefulWidget {
  const TambahKasirPage({super.key});

  @override
  State<TambahKasirPage> createState() => _TambahKasirPageState();
}

class _TambahKasirPageState extends State<TambahKasirPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Uint8List? _profileImageBytes;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      final imageBytes = await image.readAsBytes();
      setState(() {
        _profileImageBytes = imageBytes;
      });
    }
  }

  String _normalizeUsername(String value) {
    return value.trim().toLowerCase();
  }

  String? _readTrimmedString(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, String?>> _loadOwnerContext(
    String ownerUid,
    User ownerUser,
  ) async {
    final ownerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .get();
    final ownerData = ownerDoc.data();

    String? storeId = _readTrimmedString(ownerData, 'storeId');
    String? storeName = _readTrimmedString(ownerData, 'storeName');

    if (storeId == null || storeName == null) {
      final storeSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('ownerUid', isEqualTo: ownerUid)
          .limit(1)
          .get();

      if (storeSnapshot.docs.isNotEmpty) {
        final storeDoc = storeSnapshot.docs.first;
        storeId ??= storeDoc.id;
        storeName ??= _readTrimmedString(storeDoc.data(), 'name');
      }
    }

    return {
      'ownerName':
          _readTrimmedString(ownerData, 'nama') ?? ownerUser.displayName,
      'ownerEmail': _readTrimmedString(ownerData, 'email') ?? ownerUser.email,
      'storeId': storeId,
      'storeName': storeName,
    };
  }

  Future<void> _simpanKasir() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    FirebaseApp? secondaryApp;
    User? createdKasirUser;
    bool firestoreSaved = false;

    try {
      final ownerUser = FirebaseAuth.instance.currentUser;
      if (ownerUser == null) {
        _showError('Sesi owner tidak ditemukan');
        return;
      }

      final ownerUid = ownerUser.uid;
      final username = _normalizeUsername(_usernameController.text);
      final password = _passwordController.text.trim();
      final nama = _namaController.text.trim();
      final ownerContext = await _loadOwnerContext(ownerUid, ownerUser);

      // Create email from username for Firebase Auth
      final kasirEmail = '$username@smartlaba.kasir';

      // Check if username already exists in Firestore
      final existingKasir = await FirebaseFirestore.instance
          .collection('kasir')
          .where('usernameKey', isEqualTo: username)
          .get();

      if (existingKasir.docs.isNotEmpty) {
        _showError('Username sudah digunakan');
        return;
      }

      final existingLegacyKasir = await FirebaseFirestore.instance
          .collection('kasir')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingLegacyKasir.docs.isNotEmpty) {
        _showError('Username sudah digunakan');
        return;
      }

      // Use secondary Firebase app to create kasir account
      // This prevents signing out the current owner
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential kasirCredential;
      try {
        kasirCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: kasirEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _showError('Username sudah terdaftar');
        } else {
          _showError('Gagal membuat akun: ${e.message}');
        }
        return;
      }

      createdKasirUser = kasirCredential.user;
      if (createdKasirUser == null) {
        _showError('Gagal membuat akun kasir');
        return;
      }

      final kasirUid = createdKasirUser.uid;

      // Set display name
      await createdKasirUser.updateDisplayName(nama);

      final kasirData = <String, dynamic>{
        'uid': kasirUid,
        'nama': nama,
        'username': username,
        'usernameKey': username,
        'email': kasirEmail,
        'ownerUid': ownerUid,
        'ownerName': ownerContext['ownerName'] ?? '',
        'ownerEmail': ownerContext['ownerEmail'] ?? '',
        'role': 'Kasir',
        'isActive': false,
        'isDeleted': false,
        'isLoginEnabled': true,
        'fotoURL': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (ownerContext['storeId'] != null) {
        kasirData['storeId'] = ownerContext['storeId'];
      }
      if (ownerContext['storeName'] != null) {
        kasirData['storeName'] = ownerContext['storeName'];
      }

      final userData = <String, dynamic>{
        'uid': kasirUid,
        'nama': nama,
        'email': kasirEmail,
        'nomorHP': '',
        'role': 'Kasir',
        'ownerUid': ownerUid,
        'ownerName': ownerContext['ownerName'] ?? '',
        'ownerEmail': ownerContext['ownerEmail'] ?? '',
        'username': username,
        'usernameKey': username,
        'isActive': false,
        'isDeleted': false,
        'isLoginEnabled': true,
        'fotoURL': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (ownerContext['storeId'] != null) {
        userData['storeId'] = ownerContext['storeId'];
      }
      if (ownerContext['storeName'] != null) {
        userData['storeName'] = ownerContext['storeName'];
      }

      // Save kasir data to Firestore
      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance.collection('kasir').doc(kasirUid),
        kasirData,
      );
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(kasirUid),
        userData,
        SetOptions(merge: true),
      );
      await batch.commit();
      firestoreSaved = true;

      // Sign out from secondary auth (not the owner's session)
      await secondaryAuth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kasir "$nama" berhasil ditambahkan. Login dengan username "$username".',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!firestoreSaved && createdKasirUser != null) {
        try {
          await createdKasirUser.delete();
        } catch (_) {}
      }
      _showError('Gagal menambahkan kasir: $e');
    } finally {
      // Clean up secondary app
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Tambah Kasir',
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Profile Photo
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE8E8E8),
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                    child: _profileImageBytes == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _pickImage,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Upload',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF162B5A),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nama
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('Nama', required: true),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 40,
                          child: TextFormField(
                            controller: _namaController,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF000103),
                            ),
                            decoration: _inputDecoration(
                              'Contoh : caca',
                              Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Username
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('Username', required: true),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 40,
                          child: TextFormField(
                            controller: _usernameController,
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.none,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF000103),
                            ),
                            decoration: _inputDecoration(
                              'Contoh : caca_kasir',
                              Icons.alternate_email,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username harus diisi';
                              }
                              if (value.contains(' ')) {
                                return 'Username tidak boleh mengandung spasi';
                              }
                              if (value.length < 3) {
                                return 'Username minimal 3 karakter';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9._]+$',
                              ).hasMatch(value)) {
                                return 'Username hanya boleh huruf, angka, titik, dan underscore';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Kata Sandi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('Kata Sandi', required: true),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 40,
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF000103),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukan Kata Sandi',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.black38,
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF000103),
                                size: 16,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 0,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF000103),
                                  size: 16,
                                ),
                              ),
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 0,
                              ),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0x33000000),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Color(0xFF162B5A),
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi harus diisi';
                              }
                              if (value.length < 6) {
                                return 'Kata sandi minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Simpan Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 285),
                    child: SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _simpanKasir,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF162B5A),
                          disabledBackgroundColor: const Color(
                            0xFF162B5A,
                          ).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFFFDFA),
                                ),
                              )
                            : Text(
                                'Simpan',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFFFFDFA),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF000103), size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0x33000000), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF162B5A), width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
