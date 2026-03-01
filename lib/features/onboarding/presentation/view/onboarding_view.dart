// lib/features/onboarding/presentation/view/onboarding_view.dart
//
// FAZ 8B: Premium Onboarding — 4 sayfa PageView
//   Sayfa 1: Ana dil seçimi (bayrak kartları)
//   Sayfa 2: Hedef dil seçimi
//   Sayfa 3: Seviye seçimi (emoji + açıklama kartları)
//   Sayfa 4: Günlük hedef (animasyonlu grid)
//
// UX prensipleri:
//   - Her sayfa üstte emoji + başlık + açıklama
//   - Smooth PageView + animated dot indicator
//   - Seçim: border highlight + haptic
//   - İleri butonu: gradient pill shape
//   - Geri: text button, minimal

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app/color_palette.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/init/lang/language_manager.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../state/onboarding_bloc.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) =>
          curr.isCompleted != prev.isCompleted ||
          curr.errorMessage != prev.errorMessage ||
          curr.currentPage != prev.currentPage,
      listener: (context, state) {
        if (state.isCompleted) {
          NavigationService.instance
              .navigateToPageClear(path: NavigationConstants.LOGIN);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        // Sayfa değişimi animasyonu
        if (_pageController.hasClients &&
            _pageController.page?.round() != state.currentPage) {
          _animateToPage(state.currentPage);
        }
      },
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.colors.surface,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Dot Indicator ──────────────────────────────────
                  _DotIndicator(
                    currentPage: state.currentPage,
                    totalPages: OnboardingState.totalPages,
                  ),

                  const SizedBox(height: 8),

                  // ── PageView ───────────────────────────────────────
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _LanguagePage(
                          emoji: '🌍',
                          title: 'onboard_lang_source_title'.tr(),
                          subtitle: 'onboard_lang_source_desc'.tr(),
                          selectedValue: state.sourceLang,
                          onSelect: (code) {
                            HapticFeedback.lightImpact();
                            context
                                .read<OnboardingBloc>()
                                .add(OnboardingSourceLangChanged(code));
                          },
                        ),
                        _LanguagePage(
                          emoji: '🎯',
                          title: 'onboard_lang_target_title'.tr(),
                          subtitle: 'onboard_lang_target_desc'.tr(),
                          selectedValue: state.targetLang,
                          excludeCode: state.sourceLang,
                          onSelect: (code) {
                            HapticFeedback.lightImpact();
                            context
                                .read<OnboardingBloc>()
                                .add(OnboardingTargetLangChanged(code));
                          },
                        ),
                        _LevelPage(
                          selectedLevel: state.selectedLevel,
                          onSelect: (level) {
                            HapticFeedback.lightImpact();
                            context
                                .read<OnboardingBloc>()
                                .add(OnboardingLevelChanged(level));
                          },
                        ),
                        _DailyGoalPage(
                          selectedGoal: state.selectedDailyGoal,
                          onSelect: (goal) {
                            HapticFeedback.lightImpact();
                            context
                                .read<OnboardingBloc>()
                                .add(OnboardingDailyGoalChanged(goal));
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom Bar ─────────────────────────────────────
                  _BottomBar(state: state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DOT INDICATOR
// ═══════════════════════════════════════════════════════════════════════════════

class _DotIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _DotIndicator({required this.currentPage, required this.totalPages});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final isActive = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? context.colors.primary
                : context.colors.outlineVariant,
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _PageHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(emoji, style: const TextStyle(fontSize: 48))
            .animate()
            .scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: context.colors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.colors.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LANGUAGE PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class _LanguagePage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String selectedValue;
  final String? excludeCode;
  final ValueChanged<String> onSelect;

  const _LanguagePage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selectedValue,
    this.excludeCode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final langs = OnboardingBloc.supportedLanguages
        .where((c) => c != excludeCode)
        .toList();

    return Column(
      children: [
        _PageHeader(emoji: emoji, title: title, subtitle: subtitle),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: langs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final code = langs[i];
              final isSelected = code == selectedValue;
              final name = LanguageManager.instance.getLanguageName(code);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primaryContainer.withValues(alpha: 0.4)
                      : context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.outline.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(code),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Text(_getFlag(code),
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: context.colors.primary, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: 0.05);
            },
          ),
        ),
      ],
    );
  }

  String _getFlag(String code) {
    return switch (code.split('-')[0]) {
      'tr' => '🇹🇷',
      'en' => '🇬🇧',
      'es' => '🇪🇸',
      'de' => '🇩🇪',
      'fr' => '🇫🇷',
      'pt' => '🇵🇹',
      _ => '🏳️',
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEVEL PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class _LevelPage extends StatelessWidget {
  final String selectedLevel;
  final ValueChanged<String> onSelect;

  const _LevelPage({required this.selectedLevel, required this.onSelect});

  static const _levels = [
    _LevelData('beginner', '🌱', 'Başlangıç', 'Dile yeni başlıyorum'),
    _LevelData('intermediate', '🌿', 'Orta Seviye',
        'Temel bilgim var, geliştirmek istiyorum'),
    _LevelData('advanced', '🌳', 'İleri Seviye',
        'Akıcıyım ama kelime dağarcığımı genişletmek istiyorum'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PageHeader(
          emoji: '📊',
          title: 'Seviyen ne?',
          subtitle: 'Sana en uygun kelimeleri seçmemize yardımcı olur.',
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _levels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final level = _levels[i];
              final isSelected = level.key == selectedLevel;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primaryContainer.withValues(alpha: 0.4)
                      : context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.outline.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(level.key),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Text(level.emoji,
                              style: const TextStyle(fontSize: 36)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? context.colors.primary
                                        : context.colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  level.desc,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: context.colors.primary, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate(delay: (i * 80).ms).fadeIn().slideX(begin: 0.05);
            },
          ),
        ),
      ],
    );
  }
}

class _LevelData {
  final String key;
  final String emoji;
  final String label;
  final String desc;
  const _LevelData(this.key, this.emoji, this.label, this.desc);
}

// ═══════════════════════════════════════════════════════════════════════════════
// DAILY GOAL PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class _DailyGoalPage extends StatelessWidget {
  final int selectedGoal;
  final ValueChanged<int> onSelect;

  const _DailyGoalPage({required this.selectedGoal, required this.onSelect});

  static const _goalData = [
    _GoalOption(5, '☕', 'Rahat'),
    _GoalOption(10, '📖', 'Normal'),
    _GoalOption(15, '🔥', 'Yoğun'),
    _GoalOption(20, '🚀', 'Hızlı'),
    _GoalOption(30, '💎', 'Hardcore'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PageHeader(
          emoji: '⚡',
          title: 'Günlük hedefini belirle',
          subtitle:
              'Her gün kaç kelime öğrenmek istiyorsun? Sonra değiştirebilirsin.',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _goalData.length,
              itemBuilder: (context, i) {
                final goal = _goalData[i];
                final isSelected = goal.count == selectedGoal;

                return GestureDetector(
                  onTap: () => onSelect(goal.count),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: ColorPalette.gradientPrimary,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color:
                          isSelected ? null : context.colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(
                              color:
                                  context.colors.outline.withValues(alpha: 0.3),
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    ColorPalette.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          '${goal.count}',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : context.colors.onSurface,
                          ),
                        ),
                        Text(
                          '${goal.label} · kelime/gün',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (i * 70).ms).fadeIn().scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalOption {
  final int count;
  final String emoji;
  final String label;
  const _GoalOption(this.count, this.emoji, this.label);
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  final OnboardingState state;

  const _BottomBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          // Geri butonu
          if (state.currentPage > 0)
            TextButton(
              onPressed: () => context
                  .read<OnboardingBloc>()
                  .add(const OnboardingPreviousPage()),
              child: Text(
                'btn_back'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(width: 80),

          const Spacer(),

          // İleri / Başla butonu — gradient pill
          _GradientButton(
            label: state.isLastPage ? 'btn_start'.tr() : 'btn_next'.tr(),
            isLoading: state.isLoading,
            onTap: state.isLoading
                ? null
                : () {
                    if (!state.isLastPage) {
                      context
                          .read<OnboardingBloc>()
                          .add(const OnboardingNextPage());
                    } else {
                      context
                          .read<OnboardingBloc>()
                          .add(const OnboardingCompleted());
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: ColorPalette.gradientPrimary,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }
}
