// lib/features/auth/presentation/view/login_view.dart
//
// FAZ 8B: Premium Login — "Midnight Sapphire" paleti
//   - Gradient bg: surfaceDark → derinlik
//   - Glow orbs: indigo + violet
//   - Frosted glass butonlar
//   - Inter tipografi

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app/color_palette.dart';
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                // ── Gradient arka plan ─────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorPalette.surfaceDark,
                        Color(0xFF12122E),
                        Color(0xFF0F0F23),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // ── Glow orbs ─────────────────────────────────────
                const _GlowOrbs(),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),

                        // ── Logo + Başlık ──────────────────────────
                        _buildLogo()
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.08),

                        const Spacer(flex: 2),

                        // ── Auth Butonları ─────────────────────────
                        _AuthButton(
                          label: 'Google ile Giriş Yap',
                          icon: const _GoogleIcon(),
                          onTap: isLoading
                              ? null
                              : () => context
                                  .read<AuthBloc>()
                                  .add(const GoogleSignInRequested()),
                          bgColor: Colors.white,
                          textColor: const Color(0xFF1F2937),
                        ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),

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
                          bgColor: Colors.white.withValues(alpha: 0.08),
                          textColor: Colors.white,
                          borderColor: Colors.white.withValues(alpha: 0.12),
                        ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.08),

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
                        ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.08),

                        const SizedBox(height: 28),

                        // ── Ayırıcı ───────────────────────────────
                        _buildDivider(),

                        const SizedBox(height: 28),

                        // ── Misafir butonu ─────────────────────────
                        _buildGuestButton(context, isLoading)
                            .animate()
                            .fadeIn(delay: 340.ms),

                        const Spacer(),

                        // ── Alt not ───────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Giriş yaparak Gizlilik Politikası\'nı kabul edersiniz.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.15),
                              fontSize: 11,
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: ColorPalette.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.primary.withValues(alpha: 0.4),
                blurRadius: 32,
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
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kelime ustası ol',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
              color: Colors.white.withValues(alpha: 0.08), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
              color: Colors.white.withValues(alpha: 0.08), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildGuestButton(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading
            ? null
            : () => context.read<AuthBloc>().add(const GuestSignInRequested()),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

// ── Glow Orbs ─────────────────────────────────────────────────────────────────

class _GlowOrbs extends StatelessWidget {
  const _GlowOrbs();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _GlowPainter());
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    paint.color = ColorPalette.primary.withValues(alpha: 0.12);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.18), 180, paint);

    paint.color = const Color(0xFFA855F7).withValues(alpha: 0.08);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.72), 160, paint);

    paint.color = ColorPalette.secondary.withValues(alpha: 0.04);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Auth Button ───────────────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
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
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  borderColor != null ? Border.all(color: borderColor!) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
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
  const _GoogleIcon();

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
