import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'user_service.dart';

class AkunPage extends StatefulWidget {
  const AkunPage({super.key});

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorHPController = TextEditingController();
  final _userService = UserService();

  Uint8List? _profileImageBytes;
  UserProfile? _currentProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    final profile = await _userService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _currentProfile = profile;
        _namaController.text = profile.nama;
        _emailController.text = profile.email;
        _nomorHPController.text = profile.nomorHP;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _nomorHPController.dispose();
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
      // TODO: Upload to Firebase Storage and update photoURL
      // For now, we'll just show the local image
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profile = UserProfile(
        uid: _userService.currentUserId ?? '',
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        nomorHP: _nomorHPController.text.trim(),
        fotoURL: _currentProfile?.fotoURL,
        role: _currentProfile?.role ?? 'Owner',
      );

      final error = await _userService.saveUserProfile(profile);

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profil berhasil disimpan',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error, style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 40,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Akun',
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
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7B1A)),
        ),
      );
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
            'Akun',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 360;
          final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
          final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                keyboardInset + 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Profile Photo Section
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFE8E8E8),
                              backgroundImage: _profileImageBytes != null
                                  ? MemoryImage(_profileImageBytes!)
                                  : (_currentProfile?.fotoURL != null
                                            ? NetworkImage(
                                                _currentProfile!.fotoURL!,
                                              )
                                            : null)
                                        as ImageProvider?,
                              child:
                                  _profileImageBytes == null &&
                                      _currentProfile?.fotoURL == null
                                  ? Text(
                                      _userService.getInitials(
                                        _currentProfile?.nama,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Upload, Ubah and Hapus Buttons
                        if (_profileImageBytes == null &&
                            _currentProfile?.fotoURL == null)
                          // Show only Upload button when no photo
                          TextButton(
                            onPressed: _pickImage,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'Upload',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF162B5A),
                              ),
                            ),
                          )
                        else
                          // Show Ubah and Hapus buttons when photo exists
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              TextButton(
                                onPressed: _pickImage,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  'Ubah',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF162B5A),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _profileImageBytes = null;
                                  });
                                  // TODO: Also delete from Firebase Storage if needed
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  'Hapus',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFFF0000),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        // Nama Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 330),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Nama',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' *',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SizedBox(
                                  height: 44,
                                  child: TextFormField(
                                    controller: _namaController,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF000103),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukan Nama',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.black38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF000103),
                                        size: 16,
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 0,
                                          ),
                                      isDense: true,
                                      filled: false,
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
                                          color: Color(0x33000000),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
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
                        // Email Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 330),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Email',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' *',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SizedBox(
                                  height: 44,
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF000103),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukan Email',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.black38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                        color: Color(0xFF000103),
                                        size: 16,
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 0,
                                          ),
                                      isDense: true,
                                      filled: false,
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
                                          color: Color(0x33000000),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email harus diisi';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Email tidak valid';
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
                        // Nomor HP Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 330),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Nomor HP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' *',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SizedBox(
                                  height: 44,
                                  child: TextFormField(
                                    controller: _nomorHPController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF000103),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukan Nomor HP',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.black38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                        color: Color(0xFF000103),
                                        size: 16,
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 0,
                                          ),
                                      isDense: true,
                                      filled: false,
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
                                          color: Color(0x33000000),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nomor HP harus diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Save Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 285),
                            child: SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
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
                                child: _isSaving
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
            ),
          );
        },
      ),
    );
  }
}
