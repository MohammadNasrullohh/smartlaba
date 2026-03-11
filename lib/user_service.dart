import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String? _sanitizePhotoUrl(String? photoURL, {String? authPhotoUrl}) {
  final trimmed = photoURL?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final normalizedAuthPhoto = authPhotoUrl?.trim();
  if (normalizedAuthPhoto != null &&
      normalizedAuthPhoto.isNotEmpty &&
      trimmed == normalizedAuthPhoto) {
    return null;
  }

  final host = Uri.tryParse(trimmed)?.host.toLowerCase() ?? '';
  if (host.contains('googleusercontent.com') || host.contains('ggpht.com')) {
    return null;
  }

  return trimmed;
}

class UserProfile {
  final String uid;
  final String nama;
  final String email;
  final String nomorHP;
  final String? fotoURL;
  final String role;

  UserProfile({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nomorHP,
    this.fotoURL,
    this.role = 'Owner',
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      nomorHP: data['nomorHP'] ?? '',
      fotoURL: _sanitizePhotoUrl(data['fotoURL'] as String?),
      role: data['role'] ?? 'Owner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'nomorHP': nomorHP,
      'fotoURL': _sanitizePhotoUrl(fotoURL),
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class UserService {
  // Singleton
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? sanitizePhotoUrl(String? photoURL, {String? authPhotoUrl}) {
    return _sanitizePhotoUrl(photoURL, authPhotoUrl: authPhotoUrl);
  }

  String _pickFirstNonEmpty(Iterable<String?> values, {String fallback = ''}) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  Future<String> _resolveRole(String uid) async {
    final kasirDoc = await _firestore.collection('kasir').doc(uid).get();
    return kasirDoc.exists ? 'Kasir' : 'Owner';
  }

  Future<UserProfile> _buildFallbackProfile({
    required String uid,
    required User currentUser,
  }) async {
    final kasirDoc = await _firestore.collection('kasir').doc(uid).get();
    final kasirData = kasirDoc.data();

    return UserProfile(
      uid: uid,
      nama: _pickFirstNonEmpty([
        kasirData?['nama'] as String?,
        currentUser.displayName,
        currentUser.email?.split('@').first,
      ], fallback: 'User'),
      email: currentUser.email ?? (kasirData?['email'] as String? ?? ''),
      nomorHP: kasirData?['nomorHP'] as String? ?? '',
      fotoURL: sanitizePhotoUrl(
        kasirData?['fotoURL'] as String?,
        authPhotoUrl: currentUser.photoURL,
      ),
      role: kasirDoc.exists ? 'Kasir' : 'Owner',
    );
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create or update user profile in Firestore
  Future<String?> saveUserProfile(UserProfile profile) async {
    try {
      final uid = currentUserId;
      if (uid == null) return 'User tidak ditemukan';

      final currentUser = _auth.currentUser;
      if (currentUser == null) return 'Sesi tidak valid';
      final userRef = _firestore.collection('users').doc(uid);
      final existingDoc = await userRef.get();

      // Ensure email always comes from Firebase Auth current user
      final updatedProfile = UserProfile(
        uid: profile.uid,
        nama: profile.nama,
        email:
            currentUser.email ??
            profile.email, // Always use current Firebase email
        nomorHP: profile.nomorHP,
        fotoURL: sanitizePhotoUrl(
          profile.fotoURL,
          authPhotoUrl: currentUser.photoURL,
        ),
        role: profile.role,
      );

      final payload = <String, dynamic>{'uid': uid, ...updatedProfile.toMap()};
      if (!existingDoc.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await userRef.set(payload, SetOptions(merge: true));

      // Update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(updatedProfile.nama);

      return null; // success
    } catch (e) {
      return 'Gagal menyimpan data: $e';
    }
  }

  /// Get user profile from Firestore
  Future<UserProfile?> getUserProfile() async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      final currentUser = _auth.currentUser;

      if (doc.exists && doc.data() != null && currentUser != null) {
        // Create profile from Firestore but ensure Firebase Auth data takes priority
        final firestoreData = doc.data()!;
        return UserProfile(
          uid: uid,
          nama: _pickFirstNonEmpty([
            firestoreData['nama'] as String?,
            currentUser.displayName,
            currentUser.email?.split('@').first,
          ]),
          email:
              currentUser.email ??
              firestoreData['email'] ??
              '', // Always use current Firebase email
          nomorHP: firestoreData['nomorHP'] ?? '',
          fotoURL: sanitizePhotoUrl(
            firestoreData['fotoURL'] as String?,
            authPhotoUrl: currentUser.photoURL,
          ),
          role: firestoreData['role'] ?? await _resolveRole(uid),
        );
      } else {
        // Create default profile if doesn't exist
        if (currentUser != null) {
          final defaultProfile = await _buildFallbackProfile(
            uid: uid,
            currentUser: currentUser,
          );
          await saveUserProfile(defaultProfile);
          return defaultProfile;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream user profile (for real-time updates)
  Stream<UserProfile?> streamUserProfile() {
    // Listen to auth state changes for real-time sync
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);

      final uid = user.uid;
      return _firestore.collection('users').doc(uid).snapshots().asyncMap((
        doc,
      ) async {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return null;

        if (doc.exists && doc.data() != null) {
          // Create profile from Firestore but ensure Firebase Auth data takes priority
          final firestoreData = doc.data()!;
          return UserProfile(
            uid: uid,
            nama: _pickFirstNonEmpty([
              firestoreData['nama'] as String?,
              currentUser.displayName,
              currentUser.email?.split('@').first,
            ], fallback: 'User'),
            email:
                currentUser.email ??
                firestoreData['email'] ??
                '', // Always use current Firebase email
            nomorHP: firestoreData['nomorHP'] ?? '',
            fotoURL: sanitizePhotoUrl(
              firestoreData['fotoURL'] as String?,
              authPhotoUrl: currentUser.photoURL,
            ),
            role: firestoreData['role'] ?? await _resolveRole(uid),
          );
        } else {
          // Create default profile if doesn't exist
          final defaultProfile = await _buildFallbackProfile(
            uid: uid,
            currentUser: currentUser,
          );
          await saveUserProfile(defaultProfile);
          return defaultProfile;
        }
      });
    });
  }

  /// Update profile photo URL
  Future<String?> updatePhotoURL(String? photoURL) async {
    try {
      final uid = currentUserId;
      if (uid == null) return 'User tidak ditemukan';
      final sanitizedPhotoURL = sanitizePhotoUrl(
        photoURL,
        authPhotoUrl: _auth.currentUser?.photoURL,
      );

      await _firestore.collection('users').doc(uid).update({
        'fotoURL': sanitizedPhotoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auth.currentUser?.updatePhotoURL(sanitizedPhotoURL);

      return null; // success
    } catch (e) {
      return 'Gagal update foto: $e';
    }
  }

  /// Get user initials from name
  String getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
