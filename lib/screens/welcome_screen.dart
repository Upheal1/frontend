import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../navigation/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Top gradient hero ──────────────────────────────────
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Radial purple gradient background
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.6),
                      radius: 1.2,
                      colors: [
                        Color(0xFF9D78D8),
                        Color(0xFFB89FE0),
                        Color(0xFFD4BBEE),
                        Color(0xFFF0E8FA),
                        Colors.white,
                      ],
                      stops: [0.0, 0.25, 0.50, 0.75, 1.0],
                    ),
                  ),
                ),
                // Sunray lines painted on top
                CustomPaint(painter: _SunrayPainter()),
              ],
            ),
          ),

          // ── Bottom white content ──────────────────────────────
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  // Logo
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: Color(0xFF7C3AED), size: 22),
                      const SizedBox(width: 7),
                      Text(
                        'UpHeal',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "Let's get started",
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "When it's hard to start — begin here.\nWe will help you avoid burnout.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      height: 1.55,
                    ),
                  ),
                  const Spacer(),
                  // Create account button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/onboarding-flow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Create account',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Log in link
                  Center(
                    child: GestureDetector(
                      onTap: () => const LoginRoute().push<void>(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Log in',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sunray background painter ─────────────────────────────────────
class _SunrayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    const cy = -60.0;
    const rayCount = 16;
    const angleStep = (math.pi * 2) / rayCount;
    const halfAngle = 0.06;
    const rayLength = 1400.0;

    for (int i = 0; i < rayCount; i++) {
      final angle = i * angleStep;
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(
          cx + math.cos(angle - halfAngle) * rayLength,
          cy + math.sin(angle - halfAngle) * rayLength,
        )
        ..lineTo(
          cx + math.cos(angle + halfAngle) * rayLength,
          cy + math.sin(angle + halfAngle) * rayLength,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── DEAD CODE KEPT FOR ROUTER COMPAT — old welcome body below ─────
class _OldWelcomeBody extends StatelessWidget {
  const _OldWelcomeBody();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ── Dummy class to satisfy old references if any ──────────────────
// ignore: unused_element
class _LegacyWelcome {
  static Widget signInButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => const LoginRoute().push<void>(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        'Sign In',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
