// lib/features/study_zone/presentation/views/quiz_screen.dart
//
// FAZ 1 FIX:
//   F1-02: PopScope(canPop: false) → SessionAborted → tek Navigator.pop()
//   F1-03: AnimatedSwitcher + ValueKey(cardIndex) → fade soru geçişi
//   F1-05: Cevap bekleme 1500ms → 800ms
//   Deprecated API düzeltmeleri

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../core/constants/app/color_palette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/init/theme/app_theme_extension.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/utils/levenshtein.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/word_dao.dart';
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/mode_selector.dart';
import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';
import '../widgets/review_rating_sheet.dart';
import 'session_result_screen.dart';

// ── AnswerPhase ───────────────────────────────────────────────────────────────

enum AnswerPhase { question, answered }

// ── QuizScreen ────────────────────────────────────────────────────────────────

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // F1-02: PopScope — geri tuşu quiz'i kapatmaz, SessionAborted gönderir
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Kullanıcıya onay sor
        _showAbortDialog(context);
      },
      child: BlocConsumer<StudyZoneBloc, StudyZoneState>(
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
            // Session aborted → pop quiz route (tek pop)
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  /// Çıkış onay diyalogu
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
  late DateTime _cardShownAt;
  late List<_McqOption> _options;

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
    _phase = AnswerPhase.question;
    _selectedOption = null;
    _cardShownAt = DateTime.now();
    _options = _buildMcqOptions(widget.state);
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
        final trWord = (trData['word'] as String?);
        if (trWord != null && trWord.isNotEmpty) return trWord;
      }
      final langData = content[targetLang] as Map<String, dynamic>?;
      return (langData?['meaning'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  void _onAnswerSelected(String option, bool isCorrect) {
    if (_phase == AnswerPhase.answered) return;
    setState(() {
      _phase = AnswerPhase.answered;
      _selectedOption = option;
    });

    // F1-05: Cevap bekleme 1500ms → 800ms
    final responseMs = DateTime.now().difference(_cardShownAt).inMilliseconds;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        ReviewRatingSheet.show(context, responseMs: responseMs);
      }
    });
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(current: s.cardIndex, total: s.totalCards),
            Expanded(
              // F1-03: AnimatedSwitcher — her kart geçişinde fade animasyonu
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: SingleChildScrollView(
                  // ValueKey → cardIndex değişince yeni widget sayılır
                  key: ValueKey('card_${s.cardIndex}'),
                  padding: const EdgeInsets.all(20),
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
          onAnswered: (responseMs) {
            if (_phase == AnswerPhase.answered) return;
            setState(() => _phase = AnswerPhase.answered);
            // F1-05: 1500ms → 800ms
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                ReviewRatingSheet.show(context, responseMs: responseMs);
              }
            });
          },
        );
    }
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
        bgColor = scheme.primary
            .withValues(alpha: 0.0); // ext kullanılamaz, aşağıda override
        // success renk: tema extension'dan
        final ext = Theme.of(context).extension<AppThemeExtension>();
        final successColor = ext?.success ?? Colors.green;
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
                        Colors.green,
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
    String example = '';

    if (word != null) {
      try {
        final content = jsonDecode(word!.contentJson) as Map<String, dynamic>;
        final langData = content[targetLang] as Map<String, dynamic>?;
        wordText = (langData?['word'] as String?) ??
            (langData?['term'] as String?) ??
            '?';
        example = (langData?['example'] as String?) ?? '';
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
          if (example.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              example,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
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
                color: Colors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.volume_off, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  'Ses çalınamadı. Kelime: ${_getWordText()}',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                )),
              ]),
            ),
          GestureDetector(
            onTap: _ttsPlaying ? null : _play,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
  final void Function(int responseMs) onAnswered;
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
          DateTime.now().difference(widget.cardShownAt).inMilliseconds);
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
        DateTime.now().difference(widget.cardShownAt).inMilliseconds);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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

          // Sonuç banner
          if (_phase == _SpeakPhase.result) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_isCorrect ? Colors.green : Colors.red)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (_isCorrect ? Colors.green : Colors.red)
                        .withValues(alpha: 0.4)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(_isCorrect ? Icons.check_circle : Icons.cancel,
                          color: _isCorrect ? Colors.green : Colors.red,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(_isCorrect ? 'Doğru!' : 'Yanlış',
                          style: TextStyle(
                              color: _isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                          '%${(Levenshtein.similarity(_spokenText, _getWordText()) * 100).round()} benzerlik',
                          style: TextStyle(
                              color: (_isCorrect ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.8),
                              fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    Text.rich(TextSpan(children: [
                      const TextSpan(
                          text: 'Söylediğiniz: ',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                        const TextSpan(
                            text: 'Doğrusu: ',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        TextSpan(
                            text: _getWordText(),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.green)),
                      ])),
                    ],
                  ]),
            ),
            const SizedBox(height: 16),
          ],

          // Mikrofon butonu
          if (!_answered)
            GestureDetector(
              onTap: _phase == _SpeakPhase.listening
                  ? _speech.stopListening
                  : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _phase == _SpeakPhase.listening ? 90 : 72,
                height: _phase == _SpeakPhase.listening ? 90 : 72,
                decoration: BoxDecoration(
                  color: (_phase == _SpeakPhase.listening
                          ? Colors.red
                          : scheme.tertiary)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _phase == _SpeakPhase.listening
                          ? Colors.red
                          : scheme.tertiary,
                      width: _phase == _SpeakPhase.listening ? 3 : 2),
                ),
                child: Icon(
                    _phase == _SpeakPhase.listening
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    size: _phase == _SpeakPhase.listening ? 40 : 32,
                    color: _phase == _SpeakPhase.listening
                        ? Colors.red
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

// ── _ReviewingOverlay ─────────────────────────────────────────────────────────

class _ReviewingOverlay extends StatelessWidget {
  final StudyZoneReviewing state;
  const _ReviewingOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _QuizAppBar(
        cardIndex: state.cardIndex,
        totalCards: state.totalCards,
        sessionId: state.sessionId,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(current: state.cardIndex, total: state.totalCards),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RatingBadge(rating: state.lastRating),
                        const SizedBox(height: 16),
                        if (state.xpJustEarned > 0) ...[
                          _XPBadge(xp: state.xpJustEarned),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          _nextReviewText(state.updatedFSRS),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
        onPressed: () => QuizScreen._showAbortDialog(context),
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
      CardSource.due => ('Tekrar', ext?.success ?? Colors.green),
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

class _RatingBadge extends StatelessWidget {
  final ReviewRating rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>();
    final scheme = Theme.of(context).colorScheme;

    final (label, color) = switch (rating) {
      ReviewRating.again => ('Tekrar', scheme.error),
      ReviewRating.hard => ('Zor', ext?.warning ?? Colors.orange),
      ReviewRating.good => ('İyi', ext?.success ?? Colors.green),
      ReviewRating.easy => ('Kolay', scheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
      ),
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
                    color: ColorPalette.tertiary, size: 20),
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
                color: Colors.amber.withValues(alpha: 0.2),
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
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
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
