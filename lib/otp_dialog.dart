import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_service.dart';

Future<bool?> showVerificationDialog(BuildContext context, String email) async {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Aktivasi Akun',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => VerificationDialogContent(email: email),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.96,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

class VerificationDialogContent extends StatefulWidget {
  final String email;

  const VerificationDialogContent({super.key, required this.email});

  @override
  State<VerificationDialogContent> createState() =>
      _VerificationDialogContentState();
}

class _VerificationDialogContentState extends State<VerificationDialogContent> {
  final AuthService _authService = AuthService();

  String? _statusText;
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _statusText = null;
    });

    final verified = await _authService.checkEmailVerified();

    if (!mounted) {
      return;
    }

    if (verified) {
      await _authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isChecking = false;
      _statusText = 'Akun belum aktif. Periksa email lalu coba lagi.';
    });
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _statusText = null;
    });

    final error = await _authService.resendVerificationEmail();

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
      _statusText = error ?? 'Email aktivasi sudah dikirim ulang.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 252,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 42,
                    color: Color(0xFF3454E4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aktivasi akun anda',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    color: const Color(0xFF1A2750),
                  ),
                ),
                const SizedBox(height: 18),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      height: 1.55,
                      color: const Color(0xFF7A7A7A),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Silahkan periksa kotak masuk akun\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A4A4A),
                        ),
                      ),
                      const TextSpan(
                        text:
                            '\nuntuk menerima email aktivasi lalu tekan tombol di bawah.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 38,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        height: 1.2,
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                  ),
                ),
                if (_statusText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      height: 1.5,
                      color: _statusText!.contains('dikirim ulang')
                          ? const Color(0xFF162B5A)
                          : Colors.red.shade400,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: 104,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF162B5A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Aktivasi',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isResending ? null : _resendEmail,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Kirim ulang email',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF162B5A),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
