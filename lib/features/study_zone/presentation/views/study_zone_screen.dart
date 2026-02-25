// lib/features/study_zone/presentation/views/study_zone_screen.dart
//
// Blueprint T-13: DailyProgressCard (plan.dueCount, progress bar,
// estimatedMinutes), ModeSelectorRow (MCQ/Dinleme/Konuşma),
// CategoryFilterChips, LeechWarningBanner (varsa), "Hızlı 5 dk" mini session.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';

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

  static const _allCategories = ['a1', 'a2', 'b1', 'b2', 'c1', 'oxford'];

  @override
  void initState() {
    super.initState();
    // Ekran açılınca plan yükle
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlan());
  }

  void _loadPlan() {
    context.read<StudyZoneBloc>().add(LoadPlanRequested(
          targetLang: _targetLang,
          categories: _selectedCategories,
          newWordsGoal: _newWordsGoal,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
        listenWhen: (_, curr) =>
            curr is StudyZoneInSession || curr is StudyZoneError,
        listener: (context, state) {
          if (state is StudyZoneInSession) {
            Navigator.of(context).pushNamed('/quiz');
          } else if (state is StudyZoneError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) => _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, StudyZoneState state) {
    return RefreshIndicator(
      onRefresh: () async => _loadPlan(),
      child: CustomScrollView(
        slivers: [
          // Filtre: hedef dil + kategoriler
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

          // Plan kartı veya skeleton
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildPlanCard(context, state),
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
                  // TODO T-14: mini session parametresi (isMiniSession=true)
                  if (state is StudyZoneReady) {
                    context.read<StudyZoneBloc>().add(const SessionStarted());
                  }
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
    final done = 0; // sprint 3'te progress sayacı eklenir

    return Container(
      key: const Key('daily_progress_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + tahminî süre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Günlük Plan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                  color: const Color(0xFF43A047)),
              const SizedBox(width: 12),
              _PlanStat(
                  key: const Key('stat_new'),
                  label: 'Yeni',
                  value: plan.newCount,
                  color: const Color(0xFF1E88E5)),
              if (plan.leechCount > 0) ...[
                const SizedBox(width: 12),
                _PlanStat(
                    label: 'Zor',
                    value: plan.leechCount,
                    color: const Color(0xFFE53935)),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar (session içi dolacak)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const Key('plan_progress_bar'),
              value: total == 0 ? 0 : done / total,
              minHeight: 6,
              backgroundColor: scheme.surfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$done / $total kart',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.5),
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
        color: const Color(0xFFE53935).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$leechCount zor kart var — ekstra tekrar gerekebilir',
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE53935),
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
        color: const Color(0xFF43A047).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
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
                color: Color(0xFF43A047)),
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
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
                color: color.withOpacity(0.75),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
