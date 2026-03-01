// lib/features/study_zone/presentation/views/mini_session_screen.dart
//
// F1-05: MiniSessionScreen — "Hızlı 5 dk" butonu için özel ekran.
//
// Özellikler:
//   - Kendi StudyZoneBloc factory instance'ı (DI: getIt<StudyZoneBloc>())
//   - 5-10 kart limiti (newWordsGoal=5, due cap DailyPlanner içinden)
//   - MCQ only — ModeSelector'ı bypass etmez, ancak isMiniSession bilgisini
//     LoadPlanRequested event'ine flag olarak geçer.
//   - Session tamamlanınca session_result_screen değil, kendi özet overlay'i.
//   - Çıkış: tek pop (StudyZoneScreen'e döner).
//
// Bağımlılıklar:
//   - injection_container.dart (getIt<StudyZoneBloc>())
//   - study_zone_bloc.dart, study_zone_event.dart, study_zone_state.dart
//   - quiz_screen.dart (QuizScreen içindeki _QuizBody, _ReviewingOverlay tekrar
//     kullanılmaz — MiniSession kendi basit body'sini kullanır)
//   - session_result_screen.dart (StudyZoneCompleted → pop)
//   - settings_repository (targetLang okumak için getIt<ISettingsRepository>())

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../database/app_database.dart';
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';
import '../widgets/review_rating_sheet.dart';

// ── MiniSessionScreen ─────────────────────────────────────────────────────────

/// Hızlı 5 dk mini çalışma ekranı.
/// StudyZoneScreen'den Navigator.push ile açılır; BlocProvider kendi içinde.
class MiniSessionScreen extends StatelessWidget {
  /// Hangi hedef dilde mini session yapılacak.
  final String targetLang;

  const MiniSessionScreen({super.key, required this.targetLang});

  @override
  Widget build(BuildContext context) {
    // Her mini session için taze bir BLoC instance'ı
    return BlocProvider(
      create: (_) => getIt<StudyZoneBloc>()
        ..add(LoadPlanRequested(
          targetLang: targetLang,
          categories: const [], // tüm kategoriler
          newWordsGoal: 5, // Mini session: max 5 yeni kelime
        )),
      child: const _MiniSessionBody(),
    );
  }
}

// ── _MiniSessionBody ──────────────────────────────────────────────────────────

class _MiniSessionBody extends StatelessWidget {
  const _MiniSessionBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudyZoneBloc, StudyZoneState>(
      listenWhen: (_, curr) =>
          curr is StudyZoneCompleted || curr is StudyZoneIdle,
      listener: (context, state) {
        if (state is StudyZoneCompleted) {
          // Quiz bitince özet sheet göster, sonra pop
          showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            enableDrag: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _MiniResultSheet(state: state),
          ).then((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        } else if (state is StudyZoneIdle) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        // Plan yükleniyorsa — loading
        if (state is StudyZonePlanning || state is StudyZoneIdle) {
          return _MiniLoadingScaffold(
            onClose: () => Navigator.of(context).pop(),
          );
        }

        // Plan hazır — otomatik başlat
        if (state is StudyZoneReady) {
          // Bir frame sonra session'ı başlat (build içinde event yayamayız)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<StudyZoneBloc>().add(const SessionStarted());
          });
          return _MiniLoadingScaffold(
            onClose: () => Navigator.of(context).pop(),
          );
        }

        // Aktif kart gösterimi
        if (state is StudyZoneInSession) {
          return _MiniQuizScaffold(state: state);
        }

        // Cevap verildi — reviewing
        if (state is StudyZoneReviewing) {
          return _MiniReviewingScaffold(state: state);
        }

        // Hata
        if (state is StudyZoneError) {
          return _MiniErrorScaffold(
            message: state.message,
            onClose: () => Navigator.of(context).pop(),
          );
        }

        return _MiniLoadingScaffold(
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

// ── _MiniQuizScaffold ─────────────────────────────────────────────────────────

class _MiniQuizScaffold extends StatefulWidget {
  final StudyZoneInSession state;
  const _MiniQuizScaffold({required this.state});

  @override
  State<_MiniQuizScaffold> createState() => _MiniQuizScaffoldState();
}

class _MiniQuizScaffoldState extends State<_MiniQuizScaffold> {
  bool _answered = false;
  String? _selectedOption;
  late DateTime _cardShownAt;
  late List<_McqOpt> _options;

  @override
  void initState() {
    super.initState();
    _resetCard();
  }

  @override
  void didUpdateWidget(_MiniQuizScaffold old) {
    super.didUpdateWidget(old);
    if (old.state.cardIndex != widget.state.cardIndex) _resetCard();
  }

  void _resetCard() {
    _answered = false;
    _selectedOption = null;
    _cardShownAt = DateTime.now();
    _options = _buildOptions(widget.state);
  }

  List<_McqOpt> _buildOptions(StudyZoneInSession s) {
    final correct = s.currentWord;
    if (correct == null) return [];

    final correctMeaning = _parseMeaning(correct, s.targetLang);
    final opts = <_McqOpt>[_McqOpt(text: correctMeaning, isCorrect: true)];

    for (final decoy in s.decoys) {
      final m = _parseMeaning(decoy, s.targetLang);
      if (m.isNotEmpty && m != correctMeaning) {
        opts.add(_McqOpt(text: m, isCorrect: false));
      }
    }
    while (opts.length < 4) {
      opts.add(_McqOpt(text: '—', isCorrect: false));
    }
    opts.shuffle();
    return opts.take(4).toList();
  }

  String _parseMeaning(Word word, String targetLang) {
    try {
      final content = jsonDecode(word.contentJson) as Map<String, dynamic>;
      final trData = content['tr'] as Map<String, dynamic>?;
      if (trData != null) return (trData['meaning'] as String?) ?? '';
      final langData = content[targetLang] as Map<String, dynamic>?;
      return (langData?['meaning'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  String _parseWordText(StudyZoneInSession s) {
    final word = s.currentWord;
    if (word == null) return '?';
    try {
      final content = jsonDecode(word.contentJson) as Map<String, dynamic>;
      final langData = content[s.targetLang] as Map<String, dynamic>?;
      return (langData?['word'] as String?) ??
          (langData?['term'] as String?) ??
          '?';
    } catch (_) {
      return '?';
    }
  }

  void _onSelect(String option, bool isCorrect) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedOption = option;
    });
    final responseMs = DateTime.now().difference(_cardShownAt).inMilliseconds;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) ReviewRatingSheet.show(context, responseMs: responseMs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final scheme = Theme.of(context).colorScheme;
    final wordText = _parseWordText(s);

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              'Hızlı 5 dk  ${s.cardIndex + 1}/${s.totalCards}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.read<StudyZoneBloc>().add(const SessionAborted()),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: s.totalCards == 0 ? 0 : s.cardIndex / s.totalCards,
              minHeight: 4,
              backgroundColor: scheme.surfaceVariant,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kelime kartı
                    Container(
                      padding: const EdgeInsets.all(28),
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
                          // "Yeni" / "Tekrar" badge
                          _SourceBadge(source: s.currentCard.source),
                          const SizedBox(height: 12),
                          Text(
                            wordText,
                            key: Key('mini_word_$wordText'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (s.currentWord?.transcription != null &&
                              s.currentWord!.transcription!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '[${s.currentWord!.transcription}]',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.55),
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'Anlamını seçin',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface.withOpacity(0.5),
                                    ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seçenekler
                    ..._options.map((opt) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MiniOptionTile(
                            text: opt.text,
                            isCorrect: opt.isCorrect,
                            answered: _answered,
                            isSelected: _selectedOption == opt.text,
                            onTap: () => _onSelect(opt.text, opt.isCorrect),
                          ),
                        )),
                  ],
                ),
              ),
            ),

            // Streak bar
            if (s.sessionStreak > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Color(0xFFFF7043), size: 18),
                    const SizedBox(width: 4),
                    Text('${s.sessionStreak} seri',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _MiniReviewingScaffold ────────────────────────────────────────────────────

class _MiniReviewingScaffold extends StatelessWidget {
  final StudyZoneReviewing state;
  const _MiniReviewingScaffold({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (ratingLabel, ratingColor) = switch (state.lastRating) {
      ReviewRating.again => ('Tekrar', Colors.red),
      ReviewRating.hard => ('Zor', Colors.orange),
      ReviewRating.good => ('İyi', Colors.green),
      ReviewRating.easy => ('Kolay', Colors.blue),
    };

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              'Hızlı 5 dk  ${state.cardIndex + 1}/${state.totalCards}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.read<StudyZoneBloc>().add(const SessionAborted()),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: state.totalCards == 0
                  ? 0
                  : state.cardIndex / state.totalCards,
              minHeight: 4,
              backgroundColor: scheme.surfaceVariant,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rating chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: ratingColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: ratingColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          ratingLabel,
                          style: TextStyle(
                            color: ratingColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (state.xpJustEarned > 0) ...[
                        Text(
                          '+${state.xpJustEarned} XP',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('mini_next_button'),
                  onPressed: () => context
                      .read<StudyZoneBloc>()
                      .add(const NextCardRequested()),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Devam',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

// ── _MiniResultSheet ──────────────────────────────────────────────────────────

/// Mini session tamamlanınca gösterilen bottom sheet özeti.
class _MiniResultSheet extends StatelessWidget {
  final StudyZoneCompleted state;
  const _MiniResultSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final accuracy = (state.accuracy * 100).round();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text('⚡', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            'Mini Session Tamamlandı!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // İstatistikler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                label: 'Kart',
                value: '${state.totalCards}',
                color: scheme.primary,
              ),
              _MiniStat(
                label: 'Doğruluk',
                value: '%$accuracy',
                color: accuracy >= 70 ? Colors.green : Colors.orange,
              ),
              _MiniStat(
                label: 'XP',
                value: '+${state.xpEarned}',
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Tamam',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading / Error Scaffolds ─────────────────────────────────────────────────

class _MiniLoadingScaffold extends StatelessWidget {
  final VoidCallback onClose;
  const _MiniLoadingScaffold({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        title: const Text('Hızlı 5 dk',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MiniErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _MiniErrorScaffold({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        title: const Text('Hata'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onClose, child: const Text('Kapat')),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tiny Helpers ──────────────────────────────────────────────────────────────

class _McqOpt {
  final String text;
  final bool isCorrect;
  const _McqOpt({required this.text, required this.isCorrect});
}

class _MiniOptionTile extends StatelessWidget {
  final String text;
  final bool isCorrect;
  final bool answered;
  final bool isSelected;
  final VoidCallback onTap;

  const _MiniOptionTile({
    required this.text,
    required this.isCorrect,
    required this.answered,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? bgColor;
    Color borderColor = scheme.outline.withOpacity(0.3);

    if (answered) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.13);
        borderColor = Colors.green;
      } else if (isSelected) {
        bgColor = Colors.red.withOpacity(0.13);
        borderColor = Colors.red;
      }
    }

    return Material(
      color: bgColor ?? scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (answered && isCorrect)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              if (answered && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: Colors.red, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final CardSource source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      CardSource.newCard => ('Yeni', const Color(0xFF1E88E5)),
      CardSource.leech => ('Zor', const Color(0xFFE53935)),
      CardSource.due => ('Tekrar', const Color(0xFF43A047)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.75),
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
