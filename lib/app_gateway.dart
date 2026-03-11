import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_loading_screen.dart';
import 'auth_service.dart';
import 'dashboard.dart';
import 'developer_admin_page.dart';
import 'login_page.dart';
import 'store_hub_page.dart';
import 'user_service.dart';
import 'web_admin_page.dart';

class AppGateway extends StatelessWidget {
  const AppGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _GatewayLoadingPage(message: 'Menyiapkan SmartLaba...');
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
              return const _GatewayLoadingPage(message: 'Memuat akses akun...');
            }

            final role = profileSnapshot.data?.role ?? 'Owner';

            if (kIsWeb) {
              if (role == 'Developer') {
                return const DeveloperAdminPage();
              }
              if (role == 'Owner') {
                return const WebAdminPage();
              }

              return const _WebCashierNoticePage();
            }

            if (role == 'Owner') {
              return const StoreHubPage();
            }

            return const DashboardPage();
          },
        );
      },
    );
  }
}

class _GatewayLoadingPage extends StatelessWidget {
  final String message;

  const _GatewayLoadingPage({required this.message});

  @override
  Widget build(BuildContext context) {
    return AppLoadingScreen(message: message);
  }
}

class _WebCashierNoticePage extends StatelessWidget {
  const _WebCashierNoticePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phonelink_lock_rounded,
                    size: 36,
                    color: Color(0xFFFF8A1F),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Akses workspace web penuh saat ini tersedia untuk akun Owner.',
                  style: GoogleFonts.unbounded(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF162B5A),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Akun Kasir tetap memakai Firebase yang sama, tetapi operasional kasir diarahkan lewat aplikasi mobile agar alur transaksi tetap fokus dan aman.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF162B5A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Keluar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
