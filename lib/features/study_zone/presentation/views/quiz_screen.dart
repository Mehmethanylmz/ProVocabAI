// lib/features/study_zone/presentation/views/quiz_screen.dart
//
// FAZ 9:
//   F9-06: Answered phase inline — timeout ve bottom sheet kaldırıldı.
//          Cevap seçilince anlam + cümleler + rating inline gösterilir.
//   F9-07: Part of speech chip + genişleyebilir örnek cümleler (3 seviye).
//   F9-08: Rating butonları inline — review_rating_sheet.dart artık kullanılmıyor.
//   F9-09: XP + tekrar günü BlocConsumer listener'da SnackBar olarak gösterilir.
//   F9-10: TTS otomatik okuma (MCQ) + session-scoped 🔊 toggle + tap-to-replay.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app/app_ui_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/init/theme/app_theme_extension.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/utils/levenshtein.dart';
import '../../../../database/app_database.dart';
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/mode_selector.dart';
import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';
import 'session_result_screen.dart';

// ── AnswerPhase ───────────────────────────────────────────────────────────────

enum AnswerPhase { question, answered }

// ── QuizScreen ────────────────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  /// Son geçerli InSession snapshot — StudyZoneReviewing sırasında da
  /// QuizBody'yi aynı kart görüntüsüyle tutmak için saklanır.
  StudyZoneInSession? _lastSession;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showAbortDialog(context);
      },
      child: BlocConsumer<StudyZoneBloc, StudyZoneState>(
        listenWhen: (prev, curr) =>
            curr is StudyZoneCompleted ||
            curr is StudyZoneIdle ||
            curr is StudyZoneReviewing,
        listener: (context, state) {
          if (state is StudyZoneCompleted) {
            final bloc = context.read<StudyZoneBloc>();
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              pageBuilder: (_, __, ___) => BlocProvider.value(
                value: bloc,
                child: const SessionResultScreen(),
              ),
              transitionDuration: AppDuration.pageTransition,
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ));
          } else if (state is StudyZoneIdle) {
            Navigator.of(context).pop();
          } else if (state is StudyZoneReviewing) {
            // F9-09: XP + tekrar tarihi SnackBar olarak göster
            final days =
                state.updatedFSRS.nextReview.difference(DateTime.now()).inDays;
            final reviewText = days <= 0
                ? 'bugün'
                : days == 1
                    ? 'yarın'
                    : '$days gün sonra';
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: Text(
                  '+${state.xpJustEarned} XP · Tekrar: $reviewText',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                duration: AppDuration.snackBar,
                behavior: SnackBarBehavior.floating,
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            // 500ms sonra sonraki kart
            Future.delayed(AppDuration.nextCard, () {
              if (mounted) {
                context
                    .read<StudyZoneBloc>()
                    .add(const NextCardRequested());
              }
            });
          }
        },
        builder: (context, state) {
          if (state is StudyZoneInSession) {
            _lastSession = state;
            return _QuizBody(state: state);
          }
          // F9-06: StudyZoneReviewing geldiğinde son InSession snapshot'ıyla
          // aynı body'yi göster — kullanıcı answered phase'de rating bekler.
          if (state is StudyZoneReviewing) {
            final snap = _lastSession;
            if (snap != null) return _QuizBody(state: snap);
          }
          if (state is StudyZonePaused) {
            return _PausedOverlay(snapshot: state.snapshot);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  static void _showAbortDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkmak istiyor musun?'),
        content:
            const Text('İlerlemen kaydedilecek ama oturum yarıda kalacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Devam Et'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<StudyZoneBloc>().add(const SessionAborted());
            },
            child: const Text('Çık'),
          ),
        ],
      ),
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
  AnswerPhase _phase = AnswerPhase.question;
  String? _selectedOption;
  bool _isCorrect = false;
  late int _responseMs;
  late DateTime _cardShownAt;
  late List<_McqOption> _options;

  // F9-10: session-scoped TTS toggle
  bool _ttsEnabled = true;
  final TtsService _ttsService = getIt<TtsService>();

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

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _resetCard() {
    _phase = AnswerPhase.question;
    _selectedOption = null;
    _isCorrect = false;
    _responseMs = 0;
    _cardShownAt = DateTime.now();
    _options = _buildMcqOptions(widget.state);
    // F9-10: MCQ modunda yeni kart gelince kelimeyi otomatik oku
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPlayTts());
  }

  // F9-10: TTS otomatik okuma — sadece MCQ modunda.
  // Listening modu kendi kartında yönetir; speaking modunda TTS yok.
  void _autoPlayTts() {
    if (!_ttsEnabled) return;
    if (widget.state.currentMode != StudyMode.mcq) return;
    final text = widget.state.currentWordText ?? '';
    if (text.isEmpty) return;
    _ttsService.speak(text, widget.state.targetLang);
  }

  List<_McqOption> _buildMcqOptions(StudyZoneInSession s) {
    final correctWord = s.currentWord;
    if (correctWord == null) return [];

    final correctMeaning = _parseMeaning(correctWord, s.targetLang);
    final options = <_McqOption>[
      _McqOption(text: correctMeaning, isCorrect: true),
    ];
    for (final decoy in s.decoys) {
      final m = _parseMeaning(decoy, s.targetLang);
      if (m.isNotEmpty && m != correctMeaning) {
        options.add(_McqOption(text: m, isCorrect: false));
      }
    }
    while (options.length < 4) {
      options.add(_McqOption(text: '—', isCorrect: false));
    }
    options.shuffle(Random());
    return options.take(4).toList();
  }

  String _parseMeaning(Word word, String targetLang) {
    try {
      final Map<String, dynamic> content = jsonDecode(word.contentJson);
      final trData = content['tr'] as Map<String, dynamic>?;
      if (trData != null) {
        final trWord = trData['word'] as String?;
        if (trWord != null && trWord.isNotEmpty) return trWord;
      }
      final langData = content[targetLang] as Map<String, dynamic>?;
      return (langData?['meaning'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Ana dil (Türkçe) anlamını döner — answered bölümünde "📖 Anlam" için.
  String _parseSourceMeaning(Word? word) {
    if (word == null) return '';
    try {
      final Map<String, dynamic> content = jsonDecode(word.contentJson);
      final trData = content['tr'] as Map<String, dynamic>?;
      if (trData != null) {
        final meaning = trData['meaning'] as String?;
        if (meaning != null && meaning.isNotEmpty) return meaning;
        final trWord = trData['word'] as String?;
        if (trWord != null && trWord.isNotEmpty) return trWord;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// sentencesJson'dan hedef dil cümlelerini çıkarır.
  /// Dönen map: {'beginner': '...', 'intermediate': '...', 'advanced': '...'}
  Map<String, String> _parseSentences(Word? word, String targetLang) {
    if (word == null) return {};
    try {
      final Map<String, dynamic> sentences = jsonDecode(word.sentencesJson);
      final result = <String, String>{};
      for (final level in ['beginner', 'intermediate', 'advanced']) {
        final levelData = sentences[level];
        if (levelData is Map) {
          final text = (levelData[targetLang] as String?)?.trim() ?? '';
          if (text.isNotEmpty) result[level] = text;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  void _onAnswerSelected(String option, bool isCorrect) {
    if (_phase == AnswerPhase.answered) return;
    _responseMs = DateTime.now().difference(_cardShownAt).inMilliseconds;
    setState(() {
      _phase = AnswerPhase.answered;
      _selectedOption = option;
      _isCorrect = isCorrect;
    });
    // F9-06: timeout yok, bottom sheet yok — answered bölümü inline açılır
  }

  void _onSpeakingAnswered(int responseMs, bool isCorrect) {
    if (_phase == AnswerPhase.answered) return;
    _responseMs = responseMs;
    setState(() {
      _phase = AnswerPhase.answered;
      _isCorrect = isCorrect;
    });
  }

  // F9-08: Rating seçilince BLoC'a gönder
  void _onRating(ReviewRating rating) {
    context.read<StudyZoneBloc>().add(AnswerSubmitted(
          rating: rating,
          responseMs: _responseMs,
          isCorrect: _isCorrect,
        ));
  }

  // F9-10: Tap-to-replay
  void _replayTts() {
    final text = widget.state.currentWordText ?? '';
    if (text.isEmpty) return;
    _ttsService.speak(text, widget.state.targetLang);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final scheme = Theme.of(context).colorScheme;
    final word = s.currentWord;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _QuizAppBar(
        cardIndex: s.cardIndex,
        totalCards: s.totalCards,
        sessionId: s.sessionId,
        ttsEnabled: _ttsEnabled,
        onToggleTts: () => setState(() => _ttsEnabled = !_ttsEnabled),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(current: s.cardIndex, total: s.totalCards),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppDuration.cardSwitch,
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: SingleChildScrollView(
                  key: ValueKey('card_${s.cardIndex}'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CardTypeBadge(source: s.currentCard.source),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ModeChip(mode: s.currentMode),
                      ),
                      const SizedBox(height: 12),
                      _buildQuestionWidget(s, word),
                      const SizedBox(height: 20),
                      if (s.currentMode != StudyMode.speaking)
                        ..._options.map((opt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AnswerOptionTile(
                                text: opt.text,
                                isCorrect: opt.isCorrect,
                                phase: _phase,
                                isSelected: _selectedOption == opt.text,
                                onTap: () =>
                                    _onAnswerSelected(opt.text, opt.isCorrect),
                              ),
                            )),
                      // F9-06: Answered inline bölümü
                      if (_phase == AnswerPhase.answered)
                        _InlineAnsweredSection(
                          word: word,
                          targetLang: s.targetLang,
                          sourceMeaning: _parseSourceMeaning(word),
                          sentences: _parseSentences(word, s.targetLang),
                          onReplayTts: _replayTts,
                          onRating: _onRating,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _SessionStatusBar(
              streak: s.sessionStreak,
              hasBonus: s.hasRewardedAdBonus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(StudyZoneInSession s, Word? word) {
    switch (s.currentMode) {
      case StudyMode.mcq:
        return _McqWordCard(
          word: word,
          targetLang: s.targetLang,
        );
      case StudyMode.listening:
        return _ListeningWordCard(
          word: word,
          targetLang: s.targetLang,
        );
      case StudyMode.speaking:
        return _SpeakingWordCard(
          word: word,
          targetLang: s.targetLang,
          cardShownAt: _cardShownAt,
          onAnswered: _onSpeakingAnswered,
        );
    }
  }
}

// ── _InlineAnsweredSection ────────────────────────────────────────────────────

/// F9-06/07/08: Cevap sonrası inline gösterim.
/// Anlam + POS chip + genişleyebilir cümleler + TTS replay + rating butonları.
class _InlineAnsweredSection extends StatefulWidget {
  final Word? word;
  final String targetLang;
  final String sourceMeaning;
  final Map<String, String> sentences;
  final VoidCallback onReplayTts;
  final void Function(ReviewRating) onRating;

  const _InlineAnsweredSection({
    required this.word,
    required this.targetLang,
    required this.sourceMeaning,
    required this.sentences,
    required this.onReplayTts,
    required this.onRating,
  });

  @override
  State<_InlineAnsweredSection> createState() => _InlineAnsweredSectionState();
}

class _InlineAnsweredSectionState extends State<_InlineAnsweredSection> {
  bool _sentencesExpanded = false;

  static const _levelEmoji = {
    'beginner': '🌱',
    'intermediate': '🌿',
    'advanced': '🌳',
  };

  static const _levelLabel = {
    'beginner': 'Başlangıç',
    'intermediate': 'Orta',
    'advanced': 'İleri',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final word = widget.word;
    final partOfSpeech = word?.partOfSpeech ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Divider(color: scheme.outline.withValues(alpha: 0.25)),
        const SizedBox(height: 12),

        // F9-07: Anlam satırı
        if (widget.sourceMeaning.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📖 ',
                  style: Theme.of(context).textTheme.bodyMedium),
              Expanded(
                child: Text(
                  widget.sourceMeaning,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // F9-07: Part of speech chip
        if (partOfSpeech.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: scheme.secondary.withValues(alpha: 0.35)),
                ),
                child: Text(
                  partOfSpeech,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // F9-10: TTS tekrar dinle butonu
        OutlinedButton.icon(
          onPressed: widget.onReplayTts,
          icon: const Icon(Icons.volume_up_rounded, size: 18),
          label: const Text('Tekrar Dinle'),
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            visualDensity: VisualDensity.compact,
          ),
        ),

        // F9-07: Genişleyebilir örnek cümleler
        if (widget.sentences.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () =>
                setState(() => _sentencesExpanded = !_sentencesExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Text('💬 ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Örnek Cümleler',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.75),
                              ),
                    ),
                  ),
                  Icon(
                    _sentencesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (_sentencesExpanded) ...[
            const SizedBox(height: 6),
            ...['beginner', 'intermediate', 'advanced']
                .where((l) => widget.sentences.containsKey(l))
                .map((level) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_levelEmoji[level] ?? '•'} ',
                                style: const TextStyle(fontSize: 13)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _levelLabel[level] ?? level,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.sentences[level]!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
          ],
        ],

        const SizedBox(height: 20),

        // F9-08: Rating sorusu ve butonları inline
        Text(
          'Bu kelimeyi ne kadar hatırladın?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InlineRatingButton(
                label: 'Çok Zor',
                sublabel: 'Unutmuştum',
                color: scheme.error,
                onTap: () => widget.onRating(ReviewRating.again),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InlineRatingButton(
                label: 'Zor',
                sublabel: 'Zorlandım',
                color: ext.warning,
                onTap: () => widget.onRating(ReviewRating.hard),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _InlineRatingButton(
                label: 'İyi',
                sublabel: 'Hatırladım',
                color: ext.success,
                isDefault: true,
                onTap: () => widget.onRating(ReviewRating.good),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InlineRatingButton(
                label: 'Kolay',
                sublabel: 'Çok kolaydı',
                color: scheme.secondary,
                onTap: () => widget.onRating(ReviewRating.easy),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── _InlineRatingButton ───────────────────────────────────────────────────────

class _InlineRatingButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final bool isDefault;
  final VoidCallback onTap;

  const _InlineRatingButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isDefault ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _McqOption ────────────────────────────────────────────────────────────────

class _McqOption {
  final String text;
  final bool isCorrect;
  const _McqOption({required this.text, required this.isCorrect});
}

// ── _AnswerOptionTile ─────────────────────────────────────────────────────────

class _AnswerOptionTile extends StatelessWidget {
  final String text;
  final bool isCorrect;
  final AnswerPhase phase;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOptionTile({
    required this.text,
    required this.isCorrect,
    required this.phase,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color? bgColor;
    Color borderColor = scheme.outline.withValues(alpha: 0.3);

    if (phase == AnswerPhase.answered) {
      if (isCorrect) {
        final ext = Theme.of(context).extension<AppThemeExtension>();
        final successColor = ext?.success ?? scheme.primary;
        bgColor = successColor.withValues(alpha: 0.12);
        borderColor = successColor;
      } else if (isSelected && !isCorrect) {
        bgColor = scheme.error.withValues(alpha: 0.12);
        borderColor = scheme.error;
      }
    }

    return Material(
      color: bgColor ?? scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: phase == AnswerPhase.question ? onTap : null,
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
              if (phase == AnswerPhase.answered && isCorrect)
                Icon(Icons.check_circle_rounded,
                    color: Theme.of(context)
                            .extension<AppThemeExtension>()
                            ?.success ??
                        Theme.of(context).colorScheme.primary,
                    size: 20),
              if (phase == AnswerPhase.answered && isSelected && !isCorrect)
                Icon(Icons.cancel_rounded, color: scheme.error, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Soru Widgetları ───────────────────────────────────────────────────────────

class _McqWordCard extends StatelessWidget {
  final Word? word;
  final String targetLang;

  const _McqWordCard({required this.word, required this.targetLang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String wordText = '...';

    if (word != null) {
      try {
        final content = jsonDecode(word!.contentJson) as Map<String, dynamic>;
        final langData = content[targetLang] as Map<String, dynamic>?;
        wordText = (langData?['word'] as String?) ??
            (langData?['term'] as String?) ??
            '?';
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: scheme.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            wordText,
            key: Key('word_text_$wordText'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
            textAlign: TextAlign.center,
          ),
          if (word?.transcription != null &&
              word!.transcription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '[${word!.transcription}]',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Listening — TTS ile kelimeyi dinlet, 4 şıktan Türkçe anlamı seçtir.
class _ListeningWordCard extends StatefulWidget {
  final Word? word;
  final String targetLang;

  const _ListeningWordCard({required this.word, required this.targetLang});

  @override
  State<_ListeningWordCard> createState() => _ListeningWordCardState();
}

class _ListeningWordCardState extends State<_ListeningWordCard> {
  final TtsService _tts = getIt<TtsService>();
  bool _ttsPlaying = false;
  bool _ttsError = false;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String _getWordText() {
    try {
      final c = jsonDecode(widget.word!.contentJson) as Map<String, dynamic>;
      final lang = c[widget.targetLang] as Map<String, dynamic>?;
      return (lang?['word'] as String?) ?? (lang?['term'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _play() async {
    if (widget.word == null) return;
    final text = _getWordText();
    if (text.isEmpty) {
      setState(() => _ttsError = true);
      return;
    }
    setState(() {
      _ttsPlaying = true;
      _ttsError = false;
    });
    try {
      await _tts.speak(text, widget.targetLang);
      if (mounted) {
        setState(() {
          _played = true;
          _ttsPlaying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ttsError = true;
          _ttsPlaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: scheme.secondary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          if (_ttsError)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ext.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ext.warning.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Icon(Icons.volume_off, color: ext.warning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  'Ses çalınamadı. Kelime: ${_getWordText()}',
                  style: TextStyle(color: ext.warning, fontSize: 12),
                )),
              ]),
            ),
          GestureDetector(
            onTap: _ttsPlaying ? null : _play,
            child: AnimatedContainer(
              duration: AppDuration.scaleIn,
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _ttsPlaying
                    ? scheme.secondary.withValues(alpha: 0.2)
                    : scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _ttsPlaying
                    ? Icons.volume_up_rounded
                    : Icons.play_circle_fill_rounded,
                size: 44,
                color: scheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _ttsPlaying
                ? 'Çalıyor...'
                : (_played ? 'Tekrar Dinle' : 'Kelimeyi Dinle'),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            'Anlamını şıklardan seçin',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

/// Speaking — anlamı göster, STT ile kelimeyi söylet, Levenshtein ile değerlendir.
class _SpeakingWordCard extends StatefulWidget {
  final Word? word;
  final String targetLang;
  // F9-10: isCorrect de callback'e eklendi
  final void Function(int responseMs, bool isCorrect) onAnswered;
  final DateTime cardShownAt;

  const _SpeakingWordCard({
    required this.word,
    required this.targetLang,
    required this.onAnswered,
    required this.cardShownAt,
  });

  @override
  State<_SpeakingWordCard> createState() => _SpeakingWordCardState();
}

enum _SpeakPhase { idle, listening, result }

class _SpeakingWordCardState extends State<_SpeakingWordCard> {
  final SpeechService _speech = getIt<SpeechService>();
  _SpeakPhase _phase = _SpeakPhase.idle;
  String _spokenText = '';
  bool _isCorrect = false;
  bool _answered = false;

  @override
  void dispose() {
    _speech.stopListening();
    super.dispose();
  }

  String _getMeaning() {
    try {
      final c = jsonDecode(widget.word!.contentJson) as Map<String, dynamic>;
      final tr = c['tr'] as Map<String, dynamic>?;
      return (tr?['meaning'] as String?) ?? '?';
    } catch (_) {
      return '?';
    }
  }

  String _getWordText() {
    try {
      final c = jsonDecode(widget.word!.contentJson) as Map<String, dynamic>;
      final lang = c[widget.targetLang] as Map<String, dynamic>?;
      return (lang?['word'] as String?) ?? (lang?['term'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  String _sttLocale() {
    const map = {
      'en': 'en-US',
      'de': 'de-DE',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'pt': 'pt-PT'
    };
    return map[widget.targetLang] ?? 'en-US';
  }

  Future<void> _startListening() async {
    if (_answered) return;
    final ok = await _speech.init();
    if (!ok) {
      widget.onAnswered(
        DateTime.now().difference(widget.cardShownAt).inMilliseconds,
        false,
      );
      return;
    }
    setState(() {
      _phase = _SpeakPhase.listening;
      _spokenText = '';
    });
    await _speech.startListening(
      localeId: _sttLocale(),
      onResult: (spoken) {
        if (mounted && !_answered) _evaluate(spoken);
      },
    );
  }

  void _evaluate(String spoken) {
    final expected = _getWordText();
    final correct = Levenshtein.isCorrect(spoken, expected);
    setState(() {
      _spokenText = spoken;
      _isCorrect = correct;
      _phase = _SpeakPhase.result;
      _answered = true;
    });
    widget.onAnswered(
      DateTime.now().difference(widget.cardShownAt).inMilliseconds,
      correct,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final meaning = _getMeaning();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: scheme.tertiary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Text(meaning,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Bu anlamı ifade eden kelimeyi söyleyin',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),

          if (_phase == _SpeakPhase.result) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_isCorrect ? ext.success : scheme.error)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (_isCorrect ? ext.success : scheme.error)
                        .withValues(alpha: 0.4)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(_isCorrect ? Icons.check_circle : Icons.cancel,
                          color: _isCorrect ? ext.success : scheme.error,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(_isCorrect ? 'Doğru!' : 'Yanlış',
                          style: TextStyle(
                              color: _isCorrect ? ext.success : scheme.error,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                          '%${(Levenshtein.similarity(_spokenText, _getWordText()) * 100).round()} benzerlik',
                          style: TextStyle(
                              color: (_isCorrect ? ext.success : scheme.error)
                                  .withValues(alpha: 0.8),
                              fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: 'Söylediğiniz: ',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      TextSpan(
                          text: _spokenText.isEmpty
                              ? '(anlaşılamadı)'
                              : _spokenText,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ])),
                    if (!_isCorrect) ...[
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Doğrusu: ',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                        TextSpan(
                            text: _getWordText(),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ext.success)),
                      ])),
                    ],
                  ]),
            ),
            const SizedBox(height: 16),
          ],

          if (!_answered)
            GestureDetector(
              onTap: _phase == _SpeakPhase.listening
                  ? _speech.stopListening
                  : _startListening,
              child: AnimatedContainer(
                duration: AppDuration.slideIn,
                width: _phase == _SpeakPhase.listening ? 90 : 72,
                height: _phase == _SpeakPhase.listening ? 90 : 72,
                decoration: BoxDecoration(
                  color: (_phase == _SpeakPhase.listening
                          ? scheme.error
                          : scheme.tertiary)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _phase == _SpeakPhase.listening
                          ? scheme.error
                          : scheme.tertiary,
                      width: _phase == _SpeakPhase.listening ? 3 : 2),
                ),
                child: Icon(
                    _phase == _SpeakPhase.listening
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    size: _phase == _SpeakPhase.listening ? 40 : 32,
                    color: _phase == _SpeakPhase.listening
                        ? scheme.error
                        : scheme.tertiary),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            switch (_phase) {
              _SpeakPhase.idle => 'Mikrofona basıp kelimeyi söyleyin',
              _SpeakPhase.listening => 'Dinleniyor...',
              _SpeakPhase.result =>
                _isCorrect ? '✅ Harika!' : '❌ Tekrar deneyin',
            },
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
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
  // F9-10: TTS toggle
  final bool ttsEnabled;
  final VoidCallback onToggleTts;

  const _QuizAppBar({
    required this.cardIndex,
    required this.totalCards,
    required this.sessionId,
    required this.ttsEnabled,
    required this.onToggleTts,
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
        onPressed: () => _QuizScreenState._showAbortDialog(context),
      ),
      actions: [
        // F9-10: session-scoped TTS toggle butonu
        IconButton(
          icon: Icon(
            ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
          tooltip: ttsEnabled ? 'Sesi Kapat' : 'Sesi Aç',
          onPressed: onToggleTts,
        ),
      ],
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context)
                      .extension<AppThemeExtension>()
                      ?.gradientAccent ??
                  [scheme.primary, scheme.secondary],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _CardTypeBadge extends StatelessWidget {
  final CardSource source;
  const _CardTypeBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final scheme = Theme.of(context).colorScheme;

    final (label, color) = switch (source) {
      CardSource.newCard => ('Yeni', scheme.secondary),
      CardSource.leech => ('Zor', scheme.error),
      CardSource.due => ('Tekrar', ext?.success ?? scheme.primary),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
  final StudyMode mode;
  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      StudyMode.mcq => 'MCQ',
      StudyMode.listening => '🔊 Dinleme',
      StudyMode.speaking => '🎤 Konuşma',
    };
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
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (streak > 0)
            Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: ext.tertiary, size: 20),
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
                color: ext.tertiary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: ext.tertiary, size: 16),
                  const SizedBox(width: 4),
                  Text('2x XP',
                      style: TextStyle(
                          color: ext.tertiary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
