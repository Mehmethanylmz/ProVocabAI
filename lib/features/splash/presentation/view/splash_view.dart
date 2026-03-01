// lib/features/splash/presentation/view/splash_view.dart
//
// FAZ 8A: Premium splash tasarımı
//   - Gradient arka plan (primary → violet → purple)
//   - Glow efektli logo
//   - Pulsating dot indicator (CircularProgressIndicator yerine)
//   - Smooth scale + fade animasyonları

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app/color_palette.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../state/splash_bloc.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SplashBloc>().add(
              SplashInitialized(
                currentLocale: Localizations.localeOf(context),
              ),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToOnboarding) {
          NavigationService.instance
              .navigateToPageClear(path: NavigationConstants.ONBOARDING);
        } else if (state is SplashNavigateToLogin) {
          NavigationService.instance
              .navigateToPageClear(path: NavigationConstants.LOGIN);
        } else if (state is SplashNavigateToMain) {
          NavigationService.instance
              .navigateToPageClear(path: NavigationConstants.MAIN);
        }
      },
      child: BlocBuilder<SplashBloc, SplashState>(
        builder: (context, state) {
          final isSeedingDb = state is SplashLoading && state.seedingDatabase;

          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: ColorPalette.gradientPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // ── Glow orbs (arka plan dekor) ──────────────────────
                  Positioned(
                    top: -80,
                    left: -60,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -80,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFA855F7).withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Ana içerik ─────────────────────────────────────
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // Logo icon — glow efekti ile
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  blurRadius: 40,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                          )
                              .animate()
                              .scale(
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1, 1),
                              )
                              .then()
                              .shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),

                          const SizedBox(height: 28),

                          // App name
                          Text(
                            'ProVocab AI',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 400.ms)
                              .slideY(begin: 0.15, curve: Curves.easeOut),

                          const SizedBox(height: 8),

                          // Tagline
                          Text(
                            'Master words, daily.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                          const Spacer(flex: 2),

                          // Pulsating dot indicator
                          _PulsatingDots()
                              .animate()
                              .fadeIn(delay: 700.ms, duration: 300.ms),

                          if (isSeedingDb) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Kelime veritabanı hazırlanıyor...',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ).animate().fadeIn(),
                          ],

                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Pulsating Dots ────────────────────────────────────────────────────────────

class _PulsatingDots extends StatefulWidget {
  @override
  State<_PulsatingDots> createState() => _PulsatingDotsState();
}

class _PulsatingDotsState extends State<_PulsatingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (1 - (2 * value - 1).abs());

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3 + 0.5 * scale),
              ),
            );
          },
        );
      }),
    );
  }
}
