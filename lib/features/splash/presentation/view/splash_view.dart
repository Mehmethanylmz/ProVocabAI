import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/init/di/injection_container.dart';
import '../viewmodel/splash_view_model.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView<SplashViewModel>(
      viewModel: locator<SplashViewModel>(),
      onModelReady: (model) {
        model.setContext(context);
        model.initializeApp(context);
      },
      builder: (context, viewModel, child) {
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
                      )
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
                  "Global Kelime",
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
              ],
            ),
          ),
        );
      },
    );
  }
}
