import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _googleInitialized = false;

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findKasirByUsername(
    String username,
  ) async {
    final normalizedUsername = _normalizeUsername(username);

    final normalizedQuery = await _firestore
        .collection('kasir')
        .where('usernameKey', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    if (normalizedQuery.docs.isNotEmpty) {
      return normalizedQuery.docs.first;
    }

    final legacyQuery = await _firestore
        .collection('kasir')
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();

    if (legacyQuery.docs.isNotEmpty) {
      return legacyQuery.docs.first;
    }

    if (normalizedUsername != username.trim()) {
      final lowercaseLegacyQuery = await _firestore
          .collection('kasir')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      if (lowercaseLegacyQuery.docs.isNotEmpty) {
        return lowercaseLegacyQuery.docs.first;
      }
    }

    return null;
  }

  bool _isKasirLoginDisabled(Map<String, dynamic>? kasirData) {
    if (kasirData == null) {
      return false;
    }

    return kasirData['isDeleted'] == true ||
        kasirData['isLoginEnabled'] == false;
  }

  Future<void> _updateKasirPresence(String uid, bool isActive) async {
    final presenceData = {
      'isActive': isActive,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('kasir')
        .doc(uid)
        .set(presenceData, SetOptions(merge: true));
    await _firestore
        .collection('users')
        .doc(uid)
        .set(presenceData, SetOptions(merge: true));
  }

  Future<void> _ensureGoogleInitialized() async {
    if (kIsWeb || _googleInitialized) {
      return;
    }

    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  /// Get current logged-in user
  User? get currentUser => _auth.currentUser;

  /// Validate registration fields. Returns error message or null if valid.
  String? validateRegistration({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required bool agree,
  }) {
    if (name.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (email.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!_isValidEmail(email.trim())) {
      return 'Format email tidak valid';
    }
    if (password.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    if (password != confirmPassword) {
      return 'Konfirmasi kata sandi tidak cocok';
    }
    if (!agree) {
      return 'Anda harus menyetujui Syarat & Ketentuan';
    }
    return null;
  }

  /// Register user in Firebase Auth, set display name, send verification email.
  /// Returns null on success, or error message on failure.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Set display name
      await credential.user?.updateDisplayName(name.trim());

      // Create user profile in Firestore
      if (credential.user != null) {
        final profile = UserProfile(
          uid: credential.user!.uid,
          nama: name.trim(),
          email: email.trim(),
          nomorHP: '',
          role: 'Owner',
        );
        await UserService().saveUserProfile(profile);
      }

      // Send email verification
      await credential.user?.sendEmailVerification();

      return null; // success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email sudah terdaftar';
        case 'weak-password':
          return 'Kata sandi terlalu lemah';
        case 'invalid-email':
          return 'Format email tidak valid';
        default:
          return 'Gagal mendaftar: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  /// Resend verification email to current user
  Future<String?> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'User tidak ditemukan';
      await user.sendEmailVerification();
      return null;
    } catch (e) {
      return 'Gagal mengirim ulang email: $e';
    }
  }

  /// Check if current user's email is verified
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Sign out current user (used after registration so user logs in manually)
  Future<void> signOut() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final kasirDoc = await _firestore
            .collection('kasir')
            .doc(currentUser.uid)
            .get();
        if (kasirDoc.exists) {
          await _updateKasirPresence(currentUser.uid, false);
        }
      } catch (_) {
        // Do not block sign out when updating presence fails.
      }
    }

    if (!kIsWeb) {
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Ignore Google session cleanup errors.
      }
    }

    await _auth.signOut();
  }

  /// Login with Firebase Auth. Supports both email and username (for kasir).
  /// Returns null on success, or error message on failure.
  Future<String?> login(String emailOrUsername, String password) async {
    if (emailOrUsername.trim().isEmpty) {
      return 'Email/Username tidak boleh kosong';
    }
    if (password.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }

    try {
      String loginEmail = emailOrUsername.trim();
      DocumentSnapshot<Map<String, dynamic>>? kasirLookupDoc;
      Map<String, dynamic>? kasirLookupData;

      // Check if input is a username (no @ symbol) → convert to kasir email
      if (!loginEmail.contains('@')) {
        // Look up username in kasir collection
        kasirLookupDoc = await _findKasirByUsername(loginEmail);

        if (kasirLookupDoc != null && kasirLookupDoc.exists) {
          kasirLookupData = kasirLookupDoc.data();
          if (_isKasirLoginDisabled(kasirLookupData)) {
            return 'Akun kasir sudah dinonaktifkan';
          }

          loginEmail =
              kasirLookupData?['email'] ??
              '${_normalizeUsername(loginEmail)}@smartlaba.kasir';
        } else {
          return 'Username tidak ditemukan';
        }
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      // Ensure user profile exists in Firestore
      if (credential.user != null) {
        final user = credential.user!;
        final kasirDoc = await _firestore
            .collection('kasir')
            .doc(user.uid)
            .get();
        final kasirData = kasirDoc.data();

        if (_isKasirLoginDisabled(kasirData)) {
          await _auth.signOut();
          return 'Akun kasir sudah dinonaktifkan';
        }

        final userService = UserService();
        final profile = await userService.getUserProfile();

        // If profile doesn't exist, create it based on role
        if (profile == null) {
          final role = kasirDoc.exists ? 'Kasir' : 'Owner';

          final newProfile = UserProfile(
            uid: user.uid,
            nama:
                kasirData?['nama'] ??
                user.displayName ??
                kasirLookupData?['nama'] ??
                '',
            email:
                user.email ??
                kasirData?['email'] ??
                kasirLookupData?['email'] ??
                '',
            nomorHP: '',
            role: role,
          );
          await userService.saveUserProfile(newProfile);
        }

        if (kasirDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'role': 'Kasir',
            'ownerUid': kasirData?['ownerUid'],
            'ownerName': kasirData?['ownerName'],
            'ownerEmail': kasirData?['ownerEmail'],
            'storeId': kasirData?['storeId'],
            'storeName': kasirData?['storeName'],
            'username': kasirData?['username'],
            'usernameKey': kasirData?['usernameKey'],
            'isDeleted': kasirData?['isDeleted'] ?? false,
            'isLoginEnabled': kasirData?['isLoginEnabled'] ?? true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        if (kasirDoc.exists) {
          await _updateKasirPresence(user.uid, true);
        }
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Email/Username belum terdaftar';
        case 'wrong-password':
          return 'Kata sandi salah';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'user-disabled':
          return 'Akun telah dinonaktifkan';
        case 'invalid-credential':
          return 'Email/Username atau kata sandi salah';
        default:
          return 'Gagal masuk: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<String?> sendPasswordReset(String emailOrUsername) async {
    final rawValue = emailOrUsername.trim();
    if (rawValue.isEmpty) {
      return 'Masukkan email akun Anda terlebih dahulu';
    }

    if (!rawValue.contains('@')) {
      final kasirDoc = await _findKasirByUsername(rawValue);
      if (kasirDoc != null && kasirDoc.exists) {
        return 'Reset kata sandi akun kasir dilakukan melalui owner toko.';
      }

      return 'Masukkan email akun owner yang valid';
    }

    if (rawValue.toLowerCase().endsWith('@smartlaba.kasir')) {
      return 'Reset kata sandi akun kasir dilakukan melalui owner toko.';
    }

    try {
      await _auth.sendPasswordResetEmail(email: rawValue);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'user-not-found':
          return 'Email belum terdaftar';
        default:
          return 'Gagal mengirim reset kata sandi: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  Future<String?> loginWithGoogle() async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        credential = await _auth.signInWithPopup(provider);
      } else {
        await _ensureGoogleInitialized();
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final googleCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(googleCredential);
      }

      final user = credential.user;
      if (user == null) {
        return 'Gagal mengambil data akun Google';
      }

      final kasirDoc = await _firestore.collection('kasir').doc(user.uid).get();
      final existingUserDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final existingUserData = existingUserDoc.data();
      final sanitizedPhotoUrl = UserService().sanitizePhotoUrl(
        existingUserData?['fotoURL'] as String?,
        authPhotoUrl: user.photoURL,
      );
      final resolvedRole =
          (existingUserData?['role'] as String?) ??
          (kasirDoc.exists ? 'Kasir' : 'Owner');

      final profile = UserProfile(
        uid: user.uid,
        nama:
            user.displayName ??
            (existingUserData?['nama'] as String?) ??
            user.email?.split('@').first ??
            'User',
        email: user.email ?? (existingUserData?['email'] as String?) ?? '',
        nomorHP: existingUserData?['nomorHP'] as String? ?? '',
        fotoURL: sanitizedPhotoUrl,
        role: resolvedRole,
      );
      await UserService().saveUserProfile(profile);

      if (kasirDoc.exists) {
        await _updateKasirPresence(user.uid, true);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'Email ini sudah terhubung dengan metode login lain';
        case 'popup-closed-by-user':
          return 'Masuk dengan Google dibatalkan';
        default:
          return 'Gagal masuk dengan Google: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  /// Get user display name
  String? getUserName() {
    return _auth.currentUser?.displayName;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
