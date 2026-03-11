import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'firestore_scope.dart';

class ProductFormPage extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? initialData;

  const ProductFormPage({super.key, this.productId, this.initialData});

  bool get isEditMode => productId != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  static const _primaryColor = Color(0xFF162B5A);
  static const _borderColor = Color(0xFFD6D6D6);

  final _formKey = GlobalKey<FormState>();
  final _namaProdukController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kodeController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _stokAwalController = TextEditingController();

  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;
  String? _selectedKategori;
  List<String> _kategoriList = [];
  bool _removeExistingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _applyInitialData();
    _loadKategori();
  }

  void _applyInitialData() {
    final data = widget.initialData;
    if (data == null) {
      return;
    }

    _namaProdukController.text = (data['namaProduk'] ?? '').toString();
    _deskripsiController.text = (data['deskripsi'] ?? '').toString();
    _kodeController.text = (data['kode'] ?? '').toString();
    _hargaBeliController.text = _formatThousands(
      _readNumber(data['hargaBeli']),
    );
    _hargaJualController.text = _formatThousands(
      _readNumber(data['hargaJual']),
    );
    _stokAwalController.text = _readNumber(data['stok']).round().toString();

    final kategori = (data['kategori'] ?? '').toString().trim();
    if (kategori.isNotEmpty) {
      _selectedKategori = kategori;
    }

    final gambarUrl = (data['gambarURL'] ?? '').toString().trim();
    if (gambarUrl.isNotEmpty) {
      _existingImageUrl = gambarUrl;
    }
  }

  @override
  void dispose() {
    _namaProdukController.dispose();
    _deskripsiController.dispose();
    _kodeController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokAwalController.dispose();
    super.dispose();
  }

  Future<FirestoreScope?> _resolveScope() async {
    final scope = await resolveCurrentFirestoreScope();
    if (scope == null || scope.dataOwnerUid.isEmpty) {
      if (mounted) {
        _showError('Scope data owner tidak ditemukan');
      }
      return null;
    }
    return scope;
  }

  Future<void> _loadKategori() async {
    try {
      final scope = await _resolveScope();
      if (scope == null) {
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(scope.dataOwnerUid)
          .collection('kategori')
          .orderBy('nama')
          .get();

      final items = snapshot.docs
          .where(
            (doc) =>
                matchesScopedSubcollectionData(data: doc.data(), scope: scope),
          )
          .map((doc) => (doc.data()['nama'] ?? '').toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      if (_selectedKategori != null && !items.contains(_selectedKategori)) {
        items.add(_selectedKategori!);
      }

      items.sort();

      if (!mounted) {
        return;
      }

      setState(() => _kategoriList = items);
    } catch (e) {
      _showError('Gagal memuat kategori: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      FocusScope.of(context).unfocus();
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _pickedImageBytes = bytes;
        _removeExistingImage = false;
      });
    } catch (e) {
      _showError('Gagal memilih gambar: $e');
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tambah Kategori',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildLabel('Nama Kategori', isRequired: true),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: _inputDecoration('Contoh : Minuman'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 132,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isNotEmpty) {
                          Navigator.of(dialogContext).pop(value);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Tambah',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();

    final newCategory = result?.trim();
    if (newCategory == null || newCategory.isEmpty) {
      return;
    }

    if (_kategoriList.any(
      (item) => item.toLowerCase() == newCategory.toLowerCase(),
    )) {
      _showError('Kategori "$newCategory" sudah ada.');
      return;
    }

    try {
      final scope = await _resolveScope();
      if (scope == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(scope.dataOwnerUid)
          .collection('kategori')
          .add({
            'nama': newCategory,
            ...buildScopedWriteData(scope),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) {
        return;
      }

      setState(() {
        _kategoriList = [..._kategoriList, newCategory]..sort();
        _selectedKategori = newCategory;
      });
    } catch (e) {
      _showError('Gagal menambahkan kategori: $e');
    }
  }

  Future<void> _submitProduk() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final scope = await _resolveScope();
      if (scope == null) {
        return;
      }

      final kodeProduk = _kodeController.text.trim().toUpperCase();
      final kodeNormalized = kodeProduk.toLowerCase();
      final duplicateSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(scope.dataOwnerUid)
          .collection('produk')
          .where('kodeNormalized', isEqualTo: kodeNormalized)
          .get();

      final hasDuplicate = duplicateSnapshot.docs.any(
        (doc) => doc.id != widget.productId,
      );
      if (hasDuplicate) {
        _showError('Kode produk sudah dipakai. Gunakan kode lain.');
        return;
      }

      String? imageUrl = _removeExistingImage ? null : _existingImageUrl;
      if (_pickedImageBytes != null) {
        final fileName = 'produk_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(scope.dataOwnerUid)
            .child('produk')
            .child(fileName);
        await ref.putData(
          _pickedImageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await ref.getDownloadURL();
      }

      final stokValue = _parseNumber(_stokAwalController.text);
      final data = {
        'namaProduk': _namaProdukController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'kode': kodeProduk,
        'kodeNormalized': kodeNormalized,
        'kategori': _selectedKategori ?? '',
        'hargaBeli': _parseNumber(_hargaBeliController.text),
        'hargaJual': _parseNumber(_hargaJualController.text),
        'stokAwal': stokValue,
        'stok': stokValue,
        'gambarURL': imageUrl,
        ...buildScopedWriteData(scope),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final produkRef = FirebaseFirestore.instance
          .collection('users')
          .doc(scope.dataOwnerUid)
          .collection('produk');

      if (widget.isEditMode) {
        await produkRef
            .doc(widget.productId)
            .set(data, SetOptions(merge: true));
      } else {
        await produkRef.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF162B5A),
          content: Text(
            widget.isEditMode
                ? 'Produk berhasil diperbarui'
                : 'Produk berhasil ditambahkan',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Gagal menyimpan produk: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade400,
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }

  int _parseNumber(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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

  String _formatThousands(num value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  String? _validateRequiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName harus diisi';
    }
    return null;
  }

  String? _validatePrice(String? value, String fieldName) {
    final amount = _parseNumber(value ?? '');
    if (amount <= 0) {
      return '$fieldName harus lebih dari 0';
    }
    return null;
  }

  String? _validateStock(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Stok awal harus diisi';
    }
    final number = int.tryParse(trimmed);
    if (number == null || number < 0) {
      return 'Stok awal tidak valid';
    }
    return null;
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF909090),
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 10.5),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
        children: isRequired
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: validator != null),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF222222),
          ),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: Colors.black,
        ),
        titleSpacing: 0,
        title: Text(
          widget.isEditMode ? 'Ubah Produk' : 'Tambah Produk',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(height: 0.6, color: Colors.black),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF9B9B9B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF303030),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProduk,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit',
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
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 22, 20, viewInsetsBottom + 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderColor),
                            color: Colors.white,
                          ),
                          child: _pickedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    _pickedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _existingImageUrl != null &&
                                    _existingImageUrl!.isNotEmpty &&
                                    !_removeExistingImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _buildUploadPlaceholder(),
                                  ),
                                )
                              : _buildUploadPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTextField(
                      controller: _namaProdukController,
                      label: 'Nama Produk',
                      hint: 'Contoh : Minuman',
                      validator: (value) =>
                          _validateRequiredText(value, 'Nama produk'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _deskripsiController,
                      label: 'Deskripsi',
                      hint: 'Masukan Deskripsi',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _kodeController,
                      label: 'Kode',
                      hint: 'Contoh : ABC-123',
                      validator: (value) =>
                          _validateRequiredText(value, 'Kode'),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9\-\s]'),
                        ),
                        UpperCaseTextFormatter(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Kategori', isRequired: true),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _kategoriList.contains(_selectedKategori)
                                ? _selectedKategori
                                : null,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFFB0B0B0),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF222222),
                            ),
                            decoration: _inputDecoration(
                              _kategoriList.isEmpty ? 'Pilih' : 'Pilih',
                            ),
                            items: _kategoriList
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedKategori = value);
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Pilih kategori'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _showAddCategoryDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF767676),
                              ),
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _hargaBeliController,
                            label: 'Harga Beli (Rp)',
                            hint: '10.000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _ThousandsSeparatorInputFormatter(),
                            ],
                            validator: (value) =>
                                _validatePrice(value, 'Harga beli'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _hargaJualController,
                            label: 'Harga Jual (Rp)',
                            hint: '10.000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _ThousandsSeparatorInputFormatter(),
                            ],
                            validator: (value) =>
                                _validatePrice(value, 'Harga jual'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _stokAwalController,
                      label: 'Stok Awal',
                      hint: '100',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateStock,
                    ),
                    const SizedBox(height: 20),
                    if (_existingImageUrl != null || _pickedImageBytes != null)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _pickedImageBytes = null;
                              _existingImageUrl = null;
                              _removeExistingImage = true;
                            });
                          },
                          child: Text(
                            'Hapus gambar',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.upload_outlined, size: 14, color: Color(0xFF7E7E7E)),
        const SizedBox(height: 4),
        Text(
          'Unggah Gambar',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF7E7E7E),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}
