import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'platform_content.dart';
import 'user_service.dart';

class PlatformRuntimeGate extends StatefulWidget {
  final Widget child;

  const PlatformRuntimeGate({super.key, required this.child});

  @override
  State<PlatformRuntimeGate> createState() => _PlatformRuntimeGateState();
}

class _PlatformRuntimeGateState extends State<PlatformRuntimeGate> {
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _platformSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _broadcastSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  PlatformSettings _settings = PlatformSettings.fromMap(null);
  AppBroadcastMessage _broadcast = AppBroadcastMessage.fromMap(null);
  UserProfile? _profile;
  String _currentVersion = '0.0.0';
  bool _versionLoaded = false;
  String? _dismissedBroadcastSignature;

  @override
  void initState() {
    super.initState();
    _platformSub = platformSettingsRef(_firestore).snapshots().listen((doc) {
      if (!mounted) {
        return;
      }
      setState(() => _settings = PlatformSettings.fromMap(doc.data()));
    });
    _broadcastSub = appBroadcastRef(_firestore).snapshots().listen((doc) {
      final nextBroadcast = AppBroadcastMessage.fromMap(doc.data());
      if (!mounted) {
        return;
      }
      setState(() {
        if (nextBroadcast.signature != _broadcast.signature) {
          _dismissedBroadcastSignature = null;
        }
        _broadcast = nextBroadcast;
      });
    });
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _profileSub?.cancel();
      if (user == null) {
        if (!mounted) {
          return;
        }
        setState(() => _profile = null);
        return;
      }
      _profileSub = UserService().streamUserProfile().listen((profile) {
        if (!mounted) {
          return;
        }
        setState(() => _profile = profile);
      });
    });
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentVersion = info.version.trim().isEmpty ? '0.0.0' : info.version;
        _versionLoaded = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _versionLoaded = true);
    }
  }

  Future<void> _launchExternal(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showSnack(context, 'Link pembaruan tidak valid.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showSnack(context, 'Gagal membuka link pembaruan.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins())),
    );
  }

  int _compareVersions(String left, String right) {
    final leftParts = _normalizeVersion(left);
    final rightParts = _normalizeVersion(right);
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;
    for (var index = 0; index < maxLength; index++) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }
    return 0;
  }

  List<int> _normalizeVersion(String value) {
    return value
        .split('+')
        .first
        .split('.')
        .map(
          (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        )
        .toList();
  }

  @override
  void dispose() {
    _platformSub?.cancel();
    _broadcastSub?.cancel();
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = FirebaseAuth.instance.currentUser == null
        ? 'Guest'
        : (_profile?.role ?? 'Owner');
    final shouldShowBroadcast =
        !kIsWeb &&
        _broadcast.isActive &&
        _broadcast.matchesRole(activeRole) &&
        _dismissedBroadcastSignature != _broadcast.signature;
    final minimumVersion = _settings.minimumSupportedVersion.trim().isEmpty
        ? _settings.latestVersion
        : _settings.minimumSupportedVersion;
    final requiresForceUpdate =
        !kIsWeb &&
        _versionLoaded &&
        _settings.forceUpdate &&
        _compareVersions(_currentVersion, minimumVersion) < 0;
    final updateUrl = _settings.apkDownloadUrl.trim().isNotEmpty
        ? _settings.apkDownloadUrl.trim()
        : (_settings.supportEmail.trim().isNotEmpty
              ? 'mailto:${_settings.supportEmail.trim()}'
              : '');

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (shouldShowBroadcast)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _BroadcastBanner(
                  broadcast: _broadcast,
                  onClose: () {
                    setState(() {
                      _dismissedBroadcastSignature = _broadcast.signature;
                    });
                  },
                  onOpen: _broadcast.ctaUrl.trim().isEmpty
                      ? null
                      : () => _launchExternal(context, _broadcast.ctaUrl),
                ),
              ),
            ),
          ),
        if (requiresForceUpdate)
          Positioned.fill(
            child: _ForceUpdateOverlay(
              settings: _settings,
              currentVersion: _currentVersion,
              minimumVersion: minimumVersion,
              onUpdate: updateUrl.isEmpty
                  ? null
                  : () => _launchExternal(context, updateUrl),
            ),
          ),
      ],
    );
  }
}

class _BroadcastBanner extends StatelessWidget {
  final AppBroadcastMessage broadcast;
  final VoidCallback onClose;
  final VoidCallback? onOpen;

  const _BroadcastBanner({
    required this.broadcast,
    required this.onClose,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF162B5A),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    broadcast.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    broadcast.body,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (onOpen != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onOpen,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        backgroundColor: const Color(0xFFFFD269),
                        foregroundColor: const Color(0xFF162B5A),
                      ),
                      child: Text(
                        broadcast.ctaLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForceUpdateOverlay extends StatelessWidget {
  final PlatformSettings settings;
  final String currentVersion;
  final String minimumVersion;
  final VoidCallback? onUpdate;

  const _ForceUpdateOverlay({
    required this.settings,
    required this.currentVersion,
    required this.minimumVersion,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.58),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    size: 36,
                    color: Color(0xFF162B5A),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pembaruan Wajib Tersedia',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.unbounded(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF162B5A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  settings.updateMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.7,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE3F2)),
                  ),
                  child: Column(
                    children: [
                      _VersionRow(
                        label: 'Versi saat ini',
                        value: currentVersion,
                      ),
                      const SizedBox(height: 8),
                      _VersionRow(
                        label: 'Minimal versi',
                        value: minimumVersion,
                      ),
                      const SizedBox(height: 8),
                      _VersionRow(
                        label: 'Versi terbaru',
                        value: settings.latestVersion,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onUpdate,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF162B5A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      onUpdate == null ? 'Hubungi Admin' : 'Perbarui Sekarang',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
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

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;

  const _VersionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF162B5A),
          ),
        ),
      ],
    );
  }
}
