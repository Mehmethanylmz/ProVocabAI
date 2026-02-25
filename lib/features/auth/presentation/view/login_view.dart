import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── Dekoratif gradient arka plan ─────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GlowPainter()),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // ── Logo + Başlık ────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF48CFE8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: -4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_stories_rounded,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ProVocab AI',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kelime öğrenmenin en akıllı yolu',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                  const Spacer(flex: 2),

                  // ── Hata mesajı ──────────────────────────────────────────
                  if (vm.errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.colors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: context.colors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: context.colors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vm.errorMessage,
                              style: GoogleFonts.poppins(
                                color: context.colors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Giriş Butonları ─────────────────────────────────────
                  _AuthButton(
                    label: 'Google ile Devam Et',
                    icon: _GoogleIcon(),
                    onTap: vm.isLoading
                        ? null
                        : () => _handleSignIn(context, vm, vm.signInWithGoogle),
                    bgColor: Colors.white,
                    textColor: const Color(0xFF1F1F1F),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  _AuthButton(
                    label: 'Facebook ile Devam Et',
                    icon: const Icon(Icons.facebook_rounded,
                        color: Colors.white, size: 22),
                    onTap: vm.isLoading
                        ? null
                        : () =>
                            _handleSignIn(context, vm, vm.signInWithFacebook),
                    bgColor: const Color(0xFF1877F2),
                    textColor: Colors.white,
                  ).animate().fadeIn(delay: 180.ms),

                  // Apple sadece iOS/macOS'ta göster
                  if (Platform.isIOS || Platform.isMacOS) ...[
                    const SizedBox(height: 12),
                    _AuthButton(
                      label: 'Apple ile Devam Et',
                      icon: const Icon(Icons.apple_rounded,
                          color: Colors.white, size: 22),
                      onTap: vm.isLoading
                          ? null
                          : () =>
                              _handleSignIn(context, vm, vm.signInWithApple),
                      bgColor: Colors.black,
                      textColor: Colors.white,
                      border: Border.all(color: Colors.white24),
                    ).animate().fadeIn(delay: 260.ms),
                  ],

                  const SizedBox(height: 24),

                  // ── Ayırıcı ─────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: Colors.white12, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'veya',
                          style: GoogleFonts.poppins(
                              color: Colors.white30, fontSize: 12),
                        ),
                      ),
                      const Expanded(
                          child: Divider(color: Colors.white12, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Misafir butonu ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: vm.isLoading
                          ? null
                          : () =>
                              _handleSignIn(context, vm, vm.signInAnonymously),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white54),
                            )
                          : Text(
                              'Misafir olarak devam et',
                              style: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 340.ms),

                  const Spacer(),

                  // ── Alt not ─────────────────────────────────────────────
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Giriş yaparak Gizlilik Politikası\'nı kabul edersiniz.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn(
    BuildContext context,
    AuthViewModel vm,
    Future<bool> Function() signInFn,
  ) async {
    final success = await signInFn();
    if (!context.mounted) return;
    if (success) {
      NavigationService.instance
          .navigateToPageClear(path: NavigationConstants.MAIN);
    }
  }
}

// ── Giriş Butonu Widget ───────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color textColor;
  final BoxBorder? border;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: border,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

// ── Google SVG İkonu ──────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: const Icon(Icons.g_mobiledata_rounded,
          color: Color(0xFF4285F4), size: 24),
    );
  }
}

// ── Arka plan glow painter ────────────────────────────────────────────────────

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    paint.color = const Color(0xFF6C63FF).withOpacity(0.15);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 180, paint);

    paint.color = const Color(0xFF48CFE8).withOpacity(0.1);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.75), 150, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => false;
}
