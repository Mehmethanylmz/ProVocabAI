// lib/features/splash/presentation/view/splash_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
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
            backgroundColor: context.colors.primary,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: context.colors.primary,
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(duration: 1500.ms),
                  const SizedBox(height: 24),
                  Text(
                    'ProVocab AI',
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ).animate().fadeIn(delay: 500.ms),
                  if (isSeedingDb) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Kelime veritabanı hazırlanıyor...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ).animate().fadeIn(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
