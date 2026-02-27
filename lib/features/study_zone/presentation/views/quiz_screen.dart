// lib/features/study_zone/presentation/views/quiz_screen.dart
//
// Blueprint T-12: BlocBuilder<StudyZoneBloc>, WordCard widget,
// AnswerOptions (4 seçenek, randomize), progress bar, hint butonu.
// SİLİNDİ: lib/features/study_zone/presentation/view/quiz_view.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../srs/fsrs_state.dart';
import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';
import '../widgets/review_rating_sheet.dart';
import 'session_result_screen.dart';

// ── QuizScreen ────────────────────────────────────────────────────────────────

/// Ana quiz ekranı — BloC state'e göre render eder.
/// Route: NavigationConstants.quizScreen (T-14'te bağlanır)
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudyZoneBloc, StudyZoneState>(
      listenWhen: (prev, curr) =>
          curr is StudyZoneCompleted || curr is StudyZoneIdle,
      listener: (context, state) {
        if (state is StudyZoneCompleted) {
          final bloc = context.read<StudyZoneBloc>();
          Navigator.of(context).pushReplacement(PageRouteBuilder(
            pageBuilder: (_, __, ___) => BlocProvider.value(
              value: bloc,
              child: const SessionResultScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ));
        } else if (state is StudyZoneIdle) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is StudyZoneInSession) {
          return _QuizBody(state: state);
        }
        if (state is StudyZoneReviewing) {
          return _ReviewingOverlay(state: state);
        }
        if (state is StudyZonePaused) {
          return _PausedOverlay(snapshot: state.snapshot);
        }
        // Fallback — olmamalı
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// ── _QuizBody ─────────────────────────────────────────────────────────────────

class _QuizBody extends StatefulWidget {
  final StudyZoneInSession state;
  const _QuizBody({required this.state});

  @override
  State<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends State<_QuizBody> {
  bool _hintVisible = false;
  bool _answered = false;
  late DateTime _cardShownAt;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _resetCard();
  }

  @override
  void didUpdateWidget(_QuizBody old) {
    super.didUpdateWidget(old);
    if (old.state.cardIndex != widget.state.cardIndex) {
      _resetCard();
    }
  }

  void _resetCard() {
    _hintVisible = false;
    _answered = false;
    _cardShownAt = DateTime.now();
    _options = _buildOptions(widget.state.currentCard);
  }

  /// MCQ için 4 seçenek üret — 1 doğru + 3 dummy (randomize).
  List<String> _buildOptions(PlanCard card) {
    // Production'da WordDao'dan distractor'lar çekilir (T-14+).
    // Şimdilik wordId tabanlı placeholder.
    final correct = 'Kelime ${card.wordId}';
    final distractors = [
      'Kelime ${card.wordId + 10}',
      'Kelime ${card.wordId + 20}',
      'Kelime ${card.wordId + 30}',
    ];
    final all = [correct, ...distractors]..shuffle(Random());
    return all;
  }

  void _onAnswerSelected(String option) {
    if (_answered) return;
    setState(() => _answered = true);

    final responseMs = DateTime.now().difference(_cardShownAt).inMilliseconds;
    ReviewRatingSheet.show(context, responseMs: responseMs);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: _QuizAppBar(
        cardIndex: s.cardIndex,
        totalCards: s.totalCards,
        sessionId: s.sessionId,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _ProgressBar(current: s.cardIndex, total: s.totalCards),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kart tipi badge
                    _CardTypeBadge(source: s.currentCard.source),
                    const SizedBox(height: 12),

                    // WordCard
                    WordCard(
                      card: s.currentCard,
                      mode: s.currentMode,
                      hintVisible: _hintVisible,
                    ),
                    const SizedBox(height: 8),

                    // Hint butonu
                    if (!_hintVisible)
                      TextButton.icon(
                        key: const Key('hint_button'),
                        onPressed: () => setState(() => _hintVisible = true),
                        icon: const Icon(Icons.lightbulb_outline, size: 18),
                        label: const Text('İpucu göster'),
                      ),
                    const SizedBox(height: 20),

                    // 4 seçenek
                    ...List.generate(
                      _options.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AnswerOptionTile(
                          key: ValueKey('option_$i'),
                          text: _options[i],
                          onTap: () => _onAnswerSelected(_options[i]),
                          enabled: !_answered,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // XP + streak bar
            _SessionStatusBar(
              streak: s.sessionStreak,
              hasBonus: s.hasRewardedAdBonus,
            ),
          ],
        ),
      ),
    );
  }
}

// ── WordCard ──────────────────────────────────────────────────────────────────

/// Mevcut kelimeyi gösterir — mod bazlı içerik.
class WordCard extends StatelessWidget {
  final PlanCard card;
  final dynamic mode; // StudyMode
  final bool hintVisible;

  const WordCard({
    super.key,
    required this.card,
    required this.mode,
    required this.hintVisible,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey('word_card_${card.wordId}'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Kelime placeholder (Production'da contentJson'dan parse edilir)
          Text(
            'Kelime #${card.wordId}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
            textAlign: TextAlign.center,
          ),

          if (hintVisible) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '💡 İpucu: anlamla ilgili bir bağlam',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 12),
          _ModeChip(mode: mode),
        ],
      ),
    );
  }
}

// ── _AnswerOptionTile ─────────────────────────────────────────────────────────

class _AnswerOptionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool enabled;

  const _AnswerOptionTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── _ReviewingOverlay ─────────────────────────────────────────────────────────

/// Rating verildi — FSRS sonucu + XP göster, "Devam" beklenir.
class _ReviewingOverlay extends StatelessWidget {
  final StudyZoneReviewing state;
  const _ReviewingOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCorrect = state.lastRating != ReviewRating.again;

    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(
              current: state.cardIndex,
              total: state.totalCards,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sonuç ikonu
                      Icon(
                        isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 72,
                        color: isCorrect
                            ? const Color(0xFF43A047)
                            : const Color(0xFFE53935),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        isCorrect ? 'Doğru!' : 'Tekrar edilecek',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),

                      if (state.xpJustEarned > 0) ...[
                        const SizedBox(height: 8),
                        _XPBadge(xp: state.xpJustEarned),
                      ],

                      const SizedBox(height: 8),
                      Text(
                        _nextReviewText(state.updatedFSRS),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Devam butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('next_card_button'),
                  onPressed: () => context
                      .read<StudyZoneBloc>()
                      .add(const NextCardRequested()),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Devam',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextReviewText(FSRSState fsrs) {
    final days = fsrs.nextReview.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Tekrar: bugün';
    if (days == 1) return 'Tekrar: yarın';
    return 'Tekrar: $days gün sonra';
  }
}

// ── _PausedOverlay ────────────────────────────────────────────────────────────

class _PausedOverlay extends StatelessWidget {
  final StudyZoneInSession snapshot;
  const _PausedOverlay({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pause_circle_outline, size: 80),
            const SizedBox(height: 16),
            const Text('Duraklatıldı',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context
                  .read<StudyZoneBloc>()
                  .add(const AppLifecycleChanged(AppLifecycleState.resumed)),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int cardIndex;
  final int totalCards;
  final String sessionId;

  const _QuizAppBar({
    required this.cardIndex,
    required this.totalCards,
    required this.sessionId,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('${cardIndex + 1} / $totalCards'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          context.read<StudyZoneBloc>().add(const SessionAborted());
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;
    return LinearProgressIndicator(
      key: const Key('quiz_progress_bar'),
      value: progress,
      minHeight: 4,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}

class _CardTypeBadge extends StatelessWidget {
  final CardSource source;
  const _CardTypeBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      CardSource.newCard => ('Yeni', const Color(0xFF1E88E5)),
      CardSource.leech => ('Zor', const Color(0xFFE53935)),
      CardSource.due => ('Tekrar', const Color(0xFF43A047)),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final dynamic mode;
  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final label = mode.toString().split('.').last.toUpperCase();
    return Chip(
      label: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SessionStatusBar extends StatelessWidget {
  final int streak;
  final bool hasBonus;

  const _SessionStatusBar({required this.streak, required this.hasBonus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (streak > 0)
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFFF7043), size: 20),
                const SizedBox(width: 4),
                Text('$streak',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            )
          else
            const SizedBox.shrink(),
          if (hasBonus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('2x XP',
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _XPBadge extends StatelessWidget {
  final int xp;
  const _XPBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Text(
        '+$xp XP',
        style: const TextStyle(
          color: Colors.amber,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}
