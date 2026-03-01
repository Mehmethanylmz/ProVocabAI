// lib/features/study_zone/presentation/views/study_zone_screen.dart
//
// FAZ 1 FIX: F1-01, F1-09, F1-10 (korunuyor)
// FAZ 2 FIX:
//   F2-01: Mod seçici chip bar (MCQ / Dinleme / Konuşma) plan kartı altında
//   F2-05: Disabled state — yeni kartlarda listening/speaking soluk + tooltip
//   F2-06: Streak göstergesi plan kartı üzerinde

import 'package:flutter/material.dart';
import '../../../../core/constants/app/color_palette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../features/dashboard/presentation/state/dashboard_bloc.dart';
import '../../../../features/settings/domain/repositories/i_settings_repository.dart';
import '../../../../srs/mode_selector.dart';
import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';
import 'mini_session_screen.dart';
import 'quiz_screen.dart';

// ── StudyZoneScreen ───────────────────────────────────────────────────────────

class StudyZoneScreen extends StatefulWidget {
  const StudyZoneScreen({super.key});

  @override
  State<StudyZoneScreen> createState() => _StudyZoneScreenState();
}

class _StudyZoneScreenState extends State<StudyZoneScreen> {
  String _targetLang = 'en';
  final List<String> _selectedCategories = [];
  int _newWordsGoal = 10;
  int _sessionCardLimit = 10;

  /// F2-01: Kullanıcının seçtiği mod (chip bar'dan)
  StudyMode? _selectedMode;

  static const _allCategories = ['a1', 'a2', 'b1', 'b2', 'c1', 'oxford'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = getIt<ISettingsRepository>();

      final goalResult = await repo.getDailyGoal();
      goalResult.fold((_) {}, (g) {
        if (mounted) setState(() => _newWordsGoal = g);
      });

      final batchResult = await repo.getBatchSize();
      batchResult.fold((_) {}, (b) {
        if (mounted) setState(() => _sessionCardLimit = b);
      });

      if (mounted) _loadPlan();
    });
  }

  void _loadPlan() {
    context.read<StudyZoneBloc>().add(LoadPlanRequested(
          targetLang: _targetLang,
          categories: _selectedCategories,
          newWordsGoal: _newWordsGoal,
          sessionCardLimit: _sessionCardLimit,
        ));
  }

  /// F2-01: Mod değişikliğini BLoC'a bildir
  void _onModeSelected(StudyMode? mode) {
    setState(() => _selectedMode = mode);
    context.read<StudyZoneBloc>().add(StudyModeManuallyChanged(mode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:
            const Text('Çalış', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Planı yenile',
            onPressed: _loadPlan,
          ),
        ],
      ),
      body: BlocConsumer<StudyZoneBloc, StudyZoneState>(
        listenWhen: (prev, curr) {
          if (prev is StudyZoneReady && curr is StudyZoneInSession) return true;
          if (curr is StudyZoneError) return true;
          if (curr is StudyZoneIdle &&
              prev is! StudyZoneIdle &&
              prev is! StudyZonePlanning) {
            return true;
          }
          return false;
        },
        listener: (context, state) {
          if (state is StudyZoneInSession) {
            final bloc = context.read<StudyZoneBloc>();
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => BlocProvider.value(
                value: bloc,
                child: const QuizScreen(),
              ),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 250),
            ));
          } else if (state is StudyZoneError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is StudyZoneIdle) {
            _loadPlan();
            try {
              context
                  .read<DashboardBloc>()
                  .add(const DashboardRefreshRequested());
            } catch (_) {}
          }
        },
        builder: (context, state) => _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, StudyZoneState state) {
    // Plan'dan kart bilgisi (mod seçici için)
    final bool hasReviewCards;
    if (state is StudyZoneReady) {
      hasReviewCards = state.plan.dueCount > 0 || state.plan.leechCount > 0;
    } else {
      hasReviewCards = false;
    }

    return RefreshIndicator(
      onRefresh: () async => _loadPlan(),
      child: CustomScrollView(
        slivers: [
          // Filtre: kategoriler
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: CategoryFilterChips(
                allCategories: _allCategories,
                selected: _selectedCategories,
                onChanged: (cats) {
                  setState(() {
                    _selectedCategories
                      ..clear()
                      ..addAll(cats);
                  });
                  _loadPlan();
                },
              ),
            ),
          ),

          // Plan kartı
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildPlanCard(context, state),
            ),
          ),

          // F2-01: Mod seçici chip bar (plan hazır ise göster)
          if (state is StudyZoneReady)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _ModeChipBar(
                  selectedMode: _selectedMode,
                  onModeSelected: _onModeSelected,
                  advancedEnabled: hasReviewCards,
                ),
              ),
            ),

          // Leech uyarısı
          if (state is StudyZoneReady && state.plan.leechCount > 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: LeechWarningBanner(leechCount: state.plan.leechCount),
              ),
            ),

          // Hızlı 5 dk mini session
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _MiniSessionButton(
                enabled: state is StudyZoneReady,
                onTap: () {
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (_, __, ___) => MiniSessionScreen(
                      targetLang: _targetLang,
                    ),
                    transitionsBuilder: (_, animation, __, child) =>
                        SlideTransition(
                      position: Tween(
                        begin: const Offset(0.0, 1.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeInOut)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 280),
                  ));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, StudyZoneState state) {
    if (state is StudyZonePlanning) {
      return const _PlanCardSkeleton();
    }
    if (state is StudyZoneReady) {
      return DailyProgressCard(
        plan: state.plan,
        onStart: () =>
            context.read<StudyZoneBloc>().add(const SessionStarted()),
        newWordsGoal: _newWordsGoal,
        onNewWordsGoalChanged: (val) {
          setState(() => _newWordsGoal = val);
          _loadPlan();
        },
      );
    }
    if (state is StudyZoneIdle && state.emptyReason == EmptyReason.allDone) {
      return const _AllDoneCard();
    }
    if (state is StudyZoneIdle &&
        state.emptyReason == EmptyReason.noCardsAvailable) {
      return const _EmptyCard();
    }
    return const _PlanCardSkeleton();
  }
}

// ── _ModeChipBar (F2-01 + F2-05) ─────────────────────────────────────────────

/// Mod seçici chip bar — MCQ / Dinleme / Konuşma
///
/// [selectedMode] null → "Otomatik" seçili
/// [advancedEnabled] false → listening/speaking chip'leri disabled + tooltip
class _ModeChipBar extends StatelessWidget {
  final StudyMode? selectedMode;
  final ValueChanged<StudyMode?> onModeSelected;
  final bool advancedEnabled;

  const _ModeChipBar({
    required this.selectedMode,
    required this.onModeSelected,
    required this.advancedEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Çalışma Modu',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Otomatik chip
              _ModeChipItem(
                label: 'Otomatik',
                icon: '🔄',
                isSelected: selectedMode == null,
                isEnabled: true,
                onTap: () => onModeSelected(null),
              ),
              const SizedBox(width: 8),

              // MCQ — her zaman aktif
              _ModeChipItem(
                label: StudyMode.mcq.label,
                icon: StudyMode.mcq.icon,
                isSelected: selectedMode == StudyMode.mcq,
                isEnabled: true,
                onTap: () => onModeSelected(StudyMode.mcq),
              ),
              const SizedBox(width: 8),

              // Dinleme — F2-05: review kartı yoksa disabled
              _ModeChipItem(
                label: StudyMode.listening.label,
                icon: StudyMode.listening.icon,
                isSelected: selectedMode == StudyMode.listening,
                isEnabled: advancedEnabled,
                disabledTooltip: 'Dinleme modu için tekrar kartları gerekli',
                onTap: () => onModeSelected(StudyMode.listening),
              ),
              const SizedBox(width: 8),

              // Konuşma — F2-05: review kartı yoksa disabled
              _ModeChipItem(
                label: StudyMode.speaking.label,
                icon: StudyMode.speaking.icon,
                isSelected: selectedMode == StudyMode.speaking,
                isEnabled: advancedEnabled,
                disabledTooltip: 'Konuşma modu için tekrar kartları gerekli',
                onTap: () => onModeSelected(StudyMode.speaking),
              ),
            ],
          ),
        ),

        // F2-05: Seçili mod açıklaması
        if (selectedMode != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _modeDescription(selectedMode!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
      ],
    );
  }

  String _modeDescription(StudyMode mode) {
    return switch (mode) {
      StudyMode.mcq => 'Çoktan seçmeli — tüm kartlarda kullanılır',
      StudyMode.listening =>
        'Kelimeyi dinle, anlamını seç — yeni kartlarda MCQ\'ya döner',
      StudyMode.speaking =>
        'Kelimeyi söyle, telaffuzun değerlendirilir — yeni kartlarda MCQ\'ya döner',
    };
  }
}

/// Tekil mod chip'i
class _ModeChipItem extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final bool isEnabled;
  final String? disabledTooltip;
  final VoidCallback onTap;

  const _ModeChipItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    this.disabledTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? scheme.primary.withValues(alpha: 0.15)
            : isEnabled
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? scheme.primary
              : isEnabled
                  ? scheme.outline.withValues(alpha: 0.2)
                  : scheme.outline.withValues(alpha: 0.1),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon,
              style: TextStyle(
                  fontSize: 14, color: isEnabled ? null : Colors.grey)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? scheme.primary
                  : isEnabled
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );

    // F2-05: Disabled durumda tooltip göster
    if (!isEnabled && disabledTooltip != null) {
      return Tooltip(
        message: disabledTooltip!,
        child: chip,
      );
    }

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: chip,
    );
  }
}

// ── DailyProgressCard ─────────────────────────────────────────────────────────

class DailyProgressCard extends StatelessWidget {
  final DailyPlan plan;
  final VoidCallback onStart;
  final int newWordsGoal;
  final ValueChanged<int> onNewWordsGoalChanged;

  const DailyProgressCard({
    super.key,
    required this.plan,
    required this.onStart,
    required this.newWordsGoal,
    required this.onNewWordsGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = plan.totalCards;
    final done = plan.completedCount;

    return Container(
      key: const Key('daily_progress_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + tahminî süre + streak (F2-06)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Günlük Plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  // F2-06: Streak göstergesi (completedCount > 0 ise)
                  if (done > 0) ...[
                    const SizedBox(width: 8),
                    _StreakBadge(count: done),
                  ],
                ],
              ),
              _TimeChip(minutes: plan.estimatedMinutes),
            ],
          ),
          const SizedBox(height: 16),

          // Kart sayıları
          Row(
            children: [
              _PlanStat(
                  key: const Key('stat_due'),
                  label: 'Tekrar',
                  value: plan.dueCount,
                  color: ColorPalette.success),
              const SizedBox(width: 12),
              _PlanStat(
                  key: const Key('stat_new'),
                  label: 'Yeni',
                  value: plan.newCount,
                  color: ColorPalette.secondary),
              if (plan.leechCount > 0) ...[
                const SizedBox(width: 12),
                _PlanStat(
                    label: 'Zor',
                    value: plan.leechCount,
                    color: ColorPalette.error),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const Key('plan_progress_bar'),
              value: total == 0 ? 0 : done / total,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$done / $total kart',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 20),

          // Başla butonu
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('start_session_button'),
              onPressed: onStart,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Başla',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _StreakBadge (F2-06) ──────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int count;
  const _StreakBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ColorPalette.tertiary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: ColorPalette.tertiary, size: 14),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              color: ColorPalette.tertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CategoryFilterChips ───────────────────────────────────────────────────────

class CategoryFilterChips extends StatelessWidget {
  final List<String> allCategories;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const CategoryFilterChips({
    super.key,
    required this.allCategories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = allCategories[i];
          final isSelected = selected.contains(cat);
          return FilterChip(
            key: Key('category_$cat'),
            label: Text(cat.toUpperCase(),
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            selected: isSelected,
            onSelected: (val) {
              final next = List<String>.from(selected);
              val ? next.add(cat) : next.remove(cat);
              onChanged(next);
            },
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

// ── LeechWarningBanner ────────────────────────────────────────────────────────

class LeechWarningBanner extends StatelessWidget {
  final int leechCount;
  const LeechWarningBanner({super.key, required this.leechCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('leech_warning_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ColorPalette.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: ColorPalette.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$leechCount zor kart var — ekstra tekrar gerekebilir',
              style: const TextStyle(
                  fontSize: 13,
                  color: ColorPalette.error,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _MiniSessionButton ────────────────────────────────────────────────────────

class _MiniSessionButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _MiniSessionButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('mini_session_button'),
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.bolt_rounded, size: 20),
      label: const Text('Hızlı 5 dk',
          style: TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ── Skeleton + Empty Cards ────────────────────────────────────────────────────

class _PlanCardSkeleton extends StatelessWidget {
  const _PlanCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('plan_skeleton'),
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('all_done_card'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ColorPalette.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorPalette.success.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'Bugünlük tamamladın!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ColorPalette.success),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Yeni kartlar yarın seni bekliyor.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('empty_card'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Çalışılacak kart bulunamadı',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Tiny Helpers ──────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final int minutes;
  const _TimeChip({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14),
          const SizedBox(width: 4),
          Text('~$minutes dk',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _PlanStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: color),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
