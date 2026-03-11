import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_service.dart';
import 'legal_content.dart';
import 'legal_document_page.dart';
import 'otp_dialog.dart';
import 'platform_content.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  final TextEditingController _loginIdentifierController =
      TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerConfirmPasswordController =
      TextEditingController();

  bool _isLoginMode = true;
  bool _agreeToLegal = false;
  bool _isLoginSubmitting = false;
  bool _isRegisterSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;
  String? _successBannerText;

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        backgroundColor: Colors.red.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showSuccessBanner(String message) {
    if (!mounted) {
      return;
    }

    setState(() => _successBannerText = message);
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted || _successBannerText != message) {
        return;
      }
      setState(() => _successBannerText = null);
    });
  }

  Future<void> _handleLogin() async {
    if (_isLoginSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoginSubmitting = true);

    final error = await _authService.login(
      _loginIdentifierController.text,
      _loginPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoginSubmitting = false);

    if (error != null) {
      _showErrorSnack(error);
      return;
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (kIsWeb || currentRoute == '/login') {
      Navigator.of(context).pushReplacementNamed('/app');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSubmitting = true);

    final error = await _authService.loginWithGoogle();

    if (!mounted) {
      return;
    }

    setState(() => _isGoogleSubmitting = false);

    if (error != null) {
      _showErrorSnack(error);
      return;
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (kIsWeb || currentRoute == '/login') {
      Navigator.of(context).pushReplacementNamed('/app');
    }
  }

  Future<void> _handleRegister() async {
    if (_isRegisterSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final validationError = _authService.validateRegistration(
      name: _registerNameController.text,
      email: _registerEmailController.text,
      password: _registerPasswordController.text,
      confirmPassword: _registerConfirmPasswordController.text,
      agree: _agreeToLegal,
    );

    if (validationError != null) {
      _showErrorSnack(validationError);
      return;
    }

    setState(() => _isRegisterSubmitting = true);

    final email = _registerEmailController.text.trim();
    final registerError = await _authService.register(
      name: _registerNameController.text,
      email: email,
      password: _registerPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isRegisterSubmitting = false);

    if (registerError != null) {
      _showErrorSnack(registerError);
      return;
    }

    final result = await showVerificationDialog(context, email);
    if (!mounted) {
      return;
    }

    if (result == true) {
      setState(() {
        _isLoginMode = true;
        _agreeToLegal = false;
        _loginIdentifierController.text = email;
        _loginPasswordController.clear();
      });
      _registerNameController.clear();
      _registerEmailController.clear();
      _registerPasswordController.clear();
      _registerConfirmPasswordController.clear();
      _showSuccessBanner('Aktivasi akun berhasil. Silahkan login');
    }
  }

  Future<void> _showForgotPasswordSheet() async {
    final controller = TextEditingController(
      text: _loginIdentifierController.text.trim(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var isSending = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lupa Kata Sandi',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF162B5A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Masukkan email akun owner untuk menerima link reset. Untuk akun kasir, reset dilakukan melalui owner toko.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.55,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildInputField(
                      controller: controller,
                      hint: 'Contoh : caca@gmail.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSending
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              side: const BorderSide(color: Color(0xFFD8DCE5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5F6673),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    setSheetState(() => isSending = true);
                                    final result = await _authService
                                        .sendPasswordReset(controller.text);

                                    if (!sheetContext.mounted) {
                                      return;
                                    }

                                    Navigator.of(sheetContext).pop();

                                    if (result == null) {
                                      _showSuccessBanner(
                                        'Link reset kata sandi sudah dikirim',
                                      );
                                    } else {
                                      _showErrorSnack(result);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: const Color(0xFF162B5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Kirim',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  void _openTermsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentPage(
          title: termsDocumentTitle,
          subtitle: termsDocumentSubtitle,
          sections: termsDocumentSections,
        ),
      ),
    );
  }

  void _openPrivacyPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentPage(
          title: privacyDocumentTitle,
          subtitle: privacyDocumentSubtitle,
          sections: privacyDocumentSections,
        ),
      ),
    );
  }

  Widget _buildPlatformNoticeBanner() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: platformSettingsRef(FirebaseFirestore.instance).snapshots(),
      builder: (context, snapshot) {
        final settings = PlatformSettings.fromMap(snapshot.data?.data());
        final message = settings.maintenanceMode
            ? 'Mode maintenance aktif. Beberapa fitur mungkin dibatasi sementara.'
            : settings.appNotice;
        if (message.trim().isEmpty) {
          return const SizedBox(height: 12);
        }

        final backgroundColor = settings.maintenanceMode
            ? const Color(0xFFFFE1B8)
            : const Color(0xFFD9E7FF);
        final textColor = settings.maintenanceMode
            ? const Color(0xFF6A3B00)
            : const Color(0xFF14305F);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        );
      },
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: const Color(0xFF8E8E8E),
      ),
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF7A7A7A)),
      prefixIconConstraints: const BoxConstraints(minWidth: 38),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 38),
      filled: true,
      fillColor: Colors.transparent,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF162B5A)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF162B5A),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    bool autocorrect = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      enableSuggestions: !obscureText,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        color: const Color(0xFF222222),
      ),
      decoration: _buildInputDecoration(
        hint: hint,
        icon: icon,
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                onPressed: onToggleObscure,
                splashRadius: 16,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: const Color(0xFF7A7A7A),
                ),
              ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
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
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: _isGoogleSubmitting ? null : _handleGoogleSignIn,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF222222),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isGoogleSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF162B5A),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.google,
                    size: 16,
                    color: Color(0xFFDB4437),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Google',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF222222),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Email *'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _loginIdentifierController,
          hint: 'Contoh : caca@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Kata sandi *'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _loginPasswordController,
          hint: 'Masukkan Kata sandi',
          icon: Icons.lock_outline,
          obscureText: _obscureLoginPassword,
          onToggleObscure: () {
            setState(() => _obscureLoginPassword = !_obscureLoginPassword);
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordSheet,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Lupa kata sandi?',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF243864),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildPrimaryButton(
          label: 'Masuk',
          loading: _isLoginSubmitting,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFD9D9D9))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Atau',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF7C7C7C),
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFD9D9D9))),
          ],
        ),
        const SizedBox(height: 12),
        Center(child: _buildGoogleButton()),
      ],
    );
  }

  Widget _buildAgreementRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _agreeToLegal,
              onChanged: (value) {
                setState(() => _agreeToLegal = value ?? false);
              },
              visualDensity: VisualDensity.compact,
              activeColor: const Color(0xFF183A6D),
              side: const BorderSide(color: Color(0xFF183A6D)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              children: [
                Text(
                  'Menyetujui ',
                  style: GoogleFonts.poppins(
                    fontSize: 10.8,
                    color: const Color(0xFF5D6673),
                  ),
                ),
                GestureDetector(
                  onTap: _openTermsPage,
                  child: Text(
                    'Syarat & Ketentuan',
                    style: GoogleFonts.poppins(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF243864),
                    ),
                  ),
                ),
                Text(
                  ' serta ',
                  style: GoogleFonts.poppins(
                    fontSize: 10.8,
                    color: const Color(0xFF5D6673),
                  ),
                ),
                GestureDetector(
                  onTap: _openPrivacyPage,
                  child: Text(
                    'Kebijakan Privasi',
                    style: GoogleFonts.poppins(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF243864),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Nama *'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _registerNameController,
          hint: 'contoh : caca',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Email *'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _registerEmailController,
          hint: 'Masukkan email anda',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Kata sandi *'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _registerPasswordController,
          hint: 'Masukkan kata sandi',
          icon: Icons.lock_outline,
          obscureText: _obscureRegisterPassword,
          onToggleObscure: () {
            setState(
              () => _obscureRegisterPassword = !_obscureRegisterPassword,
            );
          },
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Konfirmasi kata sandi *'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _registerConfirmPasswordController,
          hint: 'Masukkan konfirmasi kata sandi',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          onToggleObscure: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        const SizedBox(height: 12),
        _buildAgreementRow(),
        const SizedBox(height: 18),
        _buildPrimaryButton(
          label: 'Daftar',
          loading: _isRegisterSubmitting,
          onPressed: _handleRegister,
        ),
      ],
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _isLoginMode
                      ? const Color(0xFFE9EEF1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Masuk',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF303030),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: !_isLoginMode
                      ? const Color(0xFFE9EEF1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Daftar',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF303030),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _successBannerText == null
          ? const SizedBox(height: 46)
          : Container(
              key: ValueKey(_successBannerText),
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFC9F5BF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _successBannerText!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF234127),
                ),
              ),
            ),
    );
  }

  Widget _buildAuthHeader({
    TextAlign textAlign = TextAlign.center,
    double titleSize = 30,
    EdgeInsetsGeometry descriptionPadding = const EdgeInsets.symmetric(
      horizontal: 10,
    ),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome to',
          textAlign: textAlign,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SmartLaba',
          textAlign: textAlign,
          style: GoogleFonts.unbounded(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF162B5A),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: descriptionPadding,
          child: Text(
            'Mulailah pengalaman Anda dengan SmartLaba dengan masuk atau daftar',
            textAlign: textAlign,
            style: GoogleFonts.poppins(
              fontSize: 11.2,
              height: 1.45,
              color: const Color(0xFF7A7A7A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthFormShell({
    required EdgeInsetsGeometry outerPadding,
    required EdgeInsetsGeometry tabPadding,
    required double formMaxWidth,
    bool showPlatformBanner = true,
  }) {
    return Container(
      width: double.infinity,
      padding: outerPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFD8D6CF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPlatformBanner) _buildPlatformNoticeBanner(),
          _buildSuccessBanner(),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: formMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAuthHeader(),
                const SizedBox(height: 28),
                Padding(padding: tabPadding, child: _buildTabSwitch()),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _isLoginMode
                      ? _buildLoginForm()
                      : _buildRegisterForm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebShowcase() {
    return Container(
      height: 640,
      padding: const EdgeInsets.fromLTRB(34, 34, 34, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF132750), Color(0xFF20428A), Color(0xFF3E6BC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              'Kembali ke situs',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'SmartLaba Web Access',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Kelola toko, pantau data, dan masuk ke panel kerja dari browser.',
            style: GoogleFonts.unbounded(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tampilan web sekarang difokuskan untuk pengalaman publik yang rapi, sementara akses panel internal tetap dijaga lewat role akun yang valid.',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.8,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _WebMetricChip(
                label: 'Public website modern',
                icon: Icons.public_rounded,
              ),
              _WebMetricChip(
                label: 'Owner panel sinkron',
                icon: Icons.storefront_rounded,
              ),
              _WebMetricChip(
                label: 'AI & laporan realtime',
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Website publik',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFD269),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pengunjung umum cukup melihat informasi produk, fitur, dan brand. Login hanya dipakai saat akun owner atau internal memang ingin masuk ke sistem.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.7,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebAuthLayout(
    BoxConstraints constraints,
    double viewInsetsBottom,
  ) {
    final wide = constraints.maxWidth >= 1080;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(24, 24, 24, viewInsetsBottom + 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 1180 : 520),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: _buildWebShowcase()),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 430,
                        child: _buildAuthFormShell(
                          outerPadding: const EdgeInsets.fromLTRB(
                            28,
                            26,
                            28,
                            28,
                          ),
                          tabPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          formMaxWidth: 360,
                        ),
                      ),
                    ],
                  )
                : _buildAuthFormShell(
                    outerPadding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                    tabPadding: EdgeInsets.zero,
                    formMaxWidth: 400,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAuthLayout(
    BoxConstraints constraints,
    double viewInsetsBottom,
    bool hasKeyboard,
  ) {
    final topSpacing = hasKeyboard
        ? 20.0
        : (constraints.maxHeight * 0.14).clamp(68.0, 108.0);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(24, 14, 24, viewInsetsBottom + 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPlatformNoticeBanner(),
            _buildSuccessBanner(),
            SizedBox(height: _successBannerText == null ? topSpacing : 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 282),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAuthHeader(),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTabSwitch(),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _isLoginMode
                        ? _buildLoginForm()
                        : _buildRegisterForm(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = viewInsetsBottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE7E7E7),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (kIsWeb) {
                return _buildWebAuthLayout(constraints, viewInsetsBottom);
              }
              return _buildMobileAuthLayout(
                constraints,
                viewInsetsBottom,
                hasKeyboard,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WebMetricChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _WebMetricChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFD269)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
