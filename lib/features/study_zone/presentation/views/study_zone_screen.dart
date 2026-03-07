// lib/features/study_zone/presentation/views/study_zone_screen.dart
//
// FAZ 1 FIX: F1-01, F1-09, F1-10 (korunuyor)
// FAZ 2 FIX:
//   F2-01: Mod seçici chip bar (MCQ / Dinleme / Konuşma) plan kartı altında
//   F2-05: Disabled state — yeni kartlarda listening/speaking soluk + tooltip
//   F2-06: Streak göstergesi plan kartı üzerinde

import 'package:flutter/material.dart';
import '../../../../core/constants/app/category_constants.dart';
import '../../../../core/init/theme/app_theme_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../features/dashboard/presentation/state/dashboard_bloc.dart';
import '../../../../features/settings/domain/repositories/i_settings_repository.dart';
import '../../../../srs/mode_selector.dart';
import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';
import '../widgets/category_picker_sheet.dart';
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
          // F11-02/04/05: Kategori filtre bölümü (seviye + alan)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CategoryFilterSection(
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

          // F10-06: Günlük hedef tamamlandı banner'ı
          if (state is StudyZoneReady && state.goalMet)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _GoalMetBanner(
                  hasPendingCards: !state.plan.isEmpty,
                  onContinue: () => context
                      .read<StudyZoneBloc>()
                      .add(const ContinueBeyondGoal()),
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
      // F10-06: goalMet + plan boş → sadece hedef tamamlandı kartı göster
      // (banner ayrıca gösteriliyor, burada plan kartı gizlenir)
      if (state.goalMet && state.plan.isEmpty) {
        return const SizedBox.shrink();
      }
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
                  fontSize: 14, color: isEnabled ? null : scheme.onSurfaceVariant)),
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
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
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
                  color: ext.success),
              const SizedBox(width: 12),
              _PlanStat(
                  key: const Key('stat_new'),
                  label: 'Yeni',
                  value: plan.newCount,
                  color: scheme.secondary),
              if (plan.leechCount > 0) ...[
                const SizedBox(width: 12),
                _PlanStat(
                    label: 'Zor',
                    value: plan.leechCount,
                    color: scheme.error),
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
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ext.tertiary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              color: ext.tertiary, size: 14),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              color: ext.tertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _CategoryFilterSection (F11-02, F11-04, F11-05) ──────────────────────────

/// Kategori filtre bölümü — iki satır:
///   1. Seviye chip bar (A1–C2)
///   2. Seçili alan kategorileri + "Alan Seç" butonu + "Tümü" butonu
class _CategoryFilterSection extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _CategoryFilterSection({
    required this.selected,
    required this.onChanged,
  });

  List<String> get _selectedLevels =>
      selected.where((s) => CategoryConstants.findBySlug(s)?.group == CategoryGroup.level).toList();

  List<String> get _selectedDomains =>
      selected.where((s) => CategoryConstants.findBySlug(s)?.group == CategoryGroup.domain).toList();

  void _onLevelToggled(String slug, bool val) {
    final next = List<String>.from(selected);
    val ? next.add(slug) : next.remove(slug);
    onChanged(next);
  }

  Future<void> _openDomainPicker(BuildContext context) async {
    final result = await CategoryPickerSheet.show(
      context,
      initialSelected: _selectedDomains,
    );
    if (result == null) return;
    // Seviyeleri koru, alan seçimini güncelle
    final next = [..._selectedLevels, ...result];
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFilter = selected.isNotEmpty;
    final domainSelected = _selectedDomains;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Satır 1: Seviye chip bar (F11-02) ────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CategoryConstants.levels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final cat = CategoryConstants.levels[i];
                    final isSelected = selected.contains(cat.slug);
                    return _LevelChip(
                      info: cat,
                      isSelected: isSelected,
                      onToggled: (val) => _onLevelToggled(cat.slug, val),
                    );
                  },
                ),
              ),
            ),
            // F11-05: "Tümü" butonu — filtreler varsa göster
            if (hasFilter) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onChanged([]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Tümü',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        // ── Satır 2: Seçili alanlar + Alan Seç butonu (F11-04) ───────────────
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Seçili alan kategorileri chip'leri
              ...domainSelected.map((slug) {
                final info = CategoryConstants.findBySlug(slug);
                if (info == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _SelectedDomainChip(
                    info: info,
                    onRemove: () {
                      final next = List<String>.from(selected)..remove(slug);
                      onChanged(next);
                    },
                  ),
                );
              }),

              // "Alan Seç" / "Alan Ekle" butonu
              GestureDetector(
                onTap: () => _openDomainPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: scheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        domainSelected.isEmpty ? 'Alan Seç' : 'Alan Ekle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tekil seviye chip'i (A1–C2)
class _LevelChip extends StatelessWidget {
  final CategoryInfo info;
  final bool isSelected;
  final ValueChanged<bool> onToggled;

  const _LevelChip({
    required this.info,
    required this.isSelected,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onToggled(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.15)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info.icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              info.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçili alan kategorisi chip'i (kaldırma ikonu ile)
class _SelectedDomainChip extends StatelessWidget {
  final CategoryInfo info;
  final VoidCallback onRemove;

  const _SelectedDomainChip({required this.info, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.primary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(info.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: scheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
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
    final error = Theme.of(context).colorScheme.error;
    return Container(
      key: const Key('leech_warning_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$leechCount zor kart var — ekstra tekrar gerekebilir',
              style: TextStyle(
                  fontSize: 13,
                  color: error,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _GoalMetBanner (F10-06) ───────────────────────────────────────────────────

/// Günlük yeni kelime hedefine ulaşıldığında gösterilen banner.
///
/// [hasPendingCards] true → due kartlar hâlâ var, "Devam Et" sadece ek yeni kelime
///   için geçerli. Banner bilgi niteliğinde gösterilir.
/// [hasPendingCards] false → plan boş, "Devam Et" tek aksiyon.
class _GoalMetBanner extends StatelessWidget {
  final bool hasPendingCards;
  final VoidCallback onContinue;

  const _GoalMetBanner({
    required this.hasPendingCards,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Container(
      key: const Key('goal_met_banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: ext.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Günlük hedefini tamamladın!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ext.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasPendingCards
                ? 'Tekrar kartlarını da bitirdikten sonra ek kelimeler ekleyebilirsin.'
                : 'Bugün için tüm kartları tamamladın. Devam etmek ister misin?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          if (!hasPendingCards) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('continue_beyond_goal_button'),
                onPressed: onContinue,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ext.success),
                  foregroundColor: ext.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Devam Et',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
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
        color: Theme.of(context).extension<AppThemeExtension>()!.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).extension<AppThemeExtension>()!.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Bugünlük tamamladın!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).extension<AppThemeExtension>()!.success),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni kartlar yarın seni bekliyor.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Çalışılacak kart bulunamadı',
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
