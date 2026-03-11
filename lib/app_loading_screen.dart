import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLoadingScreen extends StatefulWidget {
  final String message;

  const AppLoadingScreen({super.key, required this.message});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7F8FC),
              Color(0xFFEFF2FB),
              Color(0xFFE4EBF8),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -20,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.92 + (_pulse.value * 0.12),
                    child: child,
                  );
                },
                child: _ambientCircle(
                  size: 220,
                  color: const Color(0xFF4F75F2).withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -30,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 - (_pulse.value * 0.08),
                    child: child,
                  );
                },
                child: _ambientCircle(
                  size: 180,
                  color: const Color(0xFFFFC96B).withValues(alpha: 0.14),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -6 + (_pulse.value * 12)),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF203B7C), Color(0xFF3F67D7)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF203B7C,
                              ).withValues(alpha: 0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_graph_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SmartLaba',
                      style: GoogleFonts.unbounded(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF162B5A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5F6B85),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        width: math.min(
                          MediaQuery.sizeOf(context).width * 0.42,
                          190,
                        ),
                        height: 8,
                        child: const LinearProgressIndicator(
                          backgroundColor: Color(0xFFDCE3F4),
                          color: Color(0xFF162B5A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
