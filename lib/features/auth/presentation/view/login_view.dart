// lib/features/auth/presentation/view/login_view.dart
//
// FAZ 3 FIX:
//   Deprecated API: withOpacity → withValues (Flutter 3.22+)
//   Login sonrası navigasyon LoginView BlocListener'da kalıyor (login-specific)
//   Global sign-out navigasyonu app.dart'ta.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../state/auth_bloc.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          NavigationService.instance
              .navigateToPageClear(path: NavigationConstants.MAIN);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Stack(
              children: [
                // ── Arka plan ───────────────────────────────────────────────
                CustomPaint(
                  painter: _GlowPainter(),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),

                        // ── Logo / Başlık ────────────────────────────────────
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF48CFE8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.4),
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
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.1),

                        const Spacer(flex: 2),

                        // ── Giriş Butonları ──────────────────────────────────
                        _AuthButton(
                          label: 'Google ile Giriş Yap',
                          icon: _GoogleIcon(),
                          onTap: isLoading
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(const GoogleSignInRequested()),
                          bgColor: Colors.white,
                          textColor: Colors.black87,
                        ).animate().fadeIn(delay: 180.ms),

                        const SizedBox(height: 12),

                        _AuthButton(
                          label: 'Apple ile Giriş Yap',
                          icon: const Icon(Icons.apple_rounded,
                              color: Colors.white, size: 22),
                          onTap: isLoading
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(const AppleSignInRequested()),
                          bgColor: Colors.black,
                          textColor: Colors.white,
                          border: Border.all(color: Colors.white24),
                        ).animate().fadeIn(delay: 220.ms),

                        const SizedBox(height: 12),

                        _AuthButton(
                          label: 'Facebook ile Giriş Yap',
                          icon: const Icon(Icons.facebook_rounded,
                              color: Colors.white, size: 22),
                          onTap: isLoading
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(const FacebookSignInRequested()),
                          bgColor: const Color(0xFF1877F2),
                          textColor: Colors.white,
                        ).animate().fadeIn(delay: 260.ms),

                        const SizedBox(height: 24),

                        // ── Ayırıcı ─────────────────────────────────────────
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(
                                    color: Colors.white12, thickness: 1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'veya',
                                style: GoogleFonts.poppins(
                                    color: Colors.white30, fontSize: 12),
                              ),
                            ),
                            const Expanded(
                                child: Divider(
                                    color: Colors.white12, thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Misafir butonu ───────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context
                                    .read<AuthBloc>()
                                    .add(const GuestSignInRequested()),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Colors.white12),
                              ),
                            ),
                            child: isLoading
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
                        ).animate().fadeIn(delay: 300.ms),

                        const Spacer(),

                        // ── Alt not ─────────────────────────────────────────
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Giriş yaparak Gizlilik Politikası\'nı kabul edersiniz.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: const Color.fromRGBO(255, 255, 255, 0.2),
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
            );
          },
        ),
      ),
    );
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

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child:
          Icon(Icons.g_mobiledata_rounded, color: Color(0xFF4285F4), size: 24),
    );
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    paint.color = const Color.fromRGBO(108, 99, 255, 0.15);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 180, paint);

    paint.color = const Color.fromRGBO(72, 207, 232, 0.1);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.75), 150, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => false;
}
