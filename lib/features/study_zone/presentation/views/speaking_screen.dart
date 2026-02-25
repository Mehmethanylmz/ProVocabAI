// lib/features/study_zone/presentation/views/speaking_screen.dart
//
// T-23: SpeakingScreen — REWRITE (speaking_view.dart → speaking_screen.dart)
//
// Silindi: lib/features/study_zone/presentation/view/speaking_view.dart
//   git rm lib/features/study_zone/presentation/view/speaking_view.dart
//
// Değişiklikler:
//   Provider/StudyViewModel → BlocBuilder<StudyZoneBloc>
//   checkTextAnswer (exact) → Levenshtein.isCorrect(score >= 0.75)
//   SpeechService.startListening/stopListening → DI üzerinden çağrı
//   bloc.add(AnswerSubmitted(rating, responseMs)) → SubmitReview use case
//   Blueprint: score >= 0.75 → ReviewRating.good | < 0.75 → ReviewRating.again

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pratikapp/core/constants/navigation/navigation_constants.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/utils/levenshtein.dart';
import '../../../../srs/fsrs_state.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isListening = false;
  bool _hasPermission = false;
  String _spokenText = '';
  double _matchScore = 0.0;
  DateTime? _cardShownAt;

  @override
  void initState() {
    super.initState();
    _cardShownAt = DateTime.now();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (mounted) setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _startListening() async {
    if (_isAnswered || !_hasPermission) return;
    setState(() {
      _isListening = true;
      _spokenText = '';
    });

    final speechService = getIt<SpeechService>();
    final state = context.read<StudyZoneBloc>().state;
    final lang = state is StudyZoneInSession ? state.targetLang : 'en';

    await speechService.startListening(
      localeId: _ttsLocale(lang),
      onResult: (result) {
        if (mounted) setState(() => _spokenText = result);
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    final speechService = getIt<SpeechService>();
    await speechService.stopListening();
    if (mounted) setState(() => _isListening = false);
    _evaluateAnswer();
  }

  void _evaluateAnswer() {
    if (_isAnswered || _spokenText.isEmpty) return;

    final state = context.read<StudyZoneBloc>().state;
    if (state is! StudyZoneInSession) return;

    final expected = state.currentWordText ?? '';
    final score = Levenshtein.similarity(_spokenText, expected);
    final correct = score >= 0.75; // Blueprint eşiği

    final responseMs = DateTime.now()
        .difference(_cardShownAt ?? DateTime.now())
        .inMilliseconds;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      _matchScore = score;
    });

    // Blueprint: speaking score >= 0.75 → good | < 0.75 → again
    final rating = correct ? ReviewRating.good : ReviewRating.again;
    context.read<StudyZoneBloc>().add(AnswerSubmitted(
          rating: rating,
          responseMs: responseMs,
        ));
  }

  void _nextCard() {
    setState(() {
      _isAnswered = false;
      _isCorrect = false;
      _isListening = false;
      _spokenText = '';
      _matchScore = 0.0;
      _cardShownAt = DateTime.now();
    });
    context.read<StudyZoneBloc>().add(NextCardRequested());
  }

  String _ttsLocale(String lang) {
    // LanguageManager.instance.getTtsLocale(lang) yerine inline map
    const locales = {
      'en': 'en-US',
      'de': 'de-DE',
      'fr': 'fr-FR',
      'es': 'es-ES',
      'pt': 'pt-PT',
    };
    return locales[lang] ?? 'en-US';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudyZoneBloc, StudyZoneState>(
      listener: (ctx, state) {
        if (state is StudyZoneCompleted) {
          Navigator.of(ctx)
              .pushReplacementNamed(NavigationConstants.SESSION_RESULT);
        }
      },
      builder: (ctx, state) {
        if (state is! StudyZoneInSession) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final progress = state.totalCards > 0
            ? state.completedCount / state.totalCards
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text('speaking_test'.tr()),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(value: progress),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Kelimeyi göster (speaking'de çeviriyi göster, kelimeyi söyle)
                Text(
                  state.currentWordMeaning ?? '',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                Text(
                  'speaking_hold_to_talk'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Söylenen metin
                if (_spokenText.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"$_spokenText"',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 16),

                // Sonuç gösterimi
                if (_isAnswered) ...[
                  _ResultBadge(
                    isCorrect: _isCorrect,
                    score: _matchScore,
                    expected: state.currentWordText ?? '',
                  ),
                  const SizedBox(height: 16),
                ],

                const Spacer(),

                // Mikrofon butonu veya Devam Et
                if (!_isAnswered)
                  _MicButton(
                    isListening: _isListening,
                    hasPermission: _hasPermission,
                    onPressStart: _startListening,
                    onPressEnd: _stopListening,
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextCard,
                      child: Text('btn_continue'.tr()),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Result Badge ──────────────────────────────────────────────────────────────

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({
    required this.isCorrect,
    required this.score,
    required this.expected,
  });

  final bool isCorrect;
  final double score;
  final String expected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isCorrect ? 'speaking_perfect'.tr() : 'speaking_try_again'.tr(),
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        if (!isCorrect) ...[
          const SizedBox(height: 4),
          Text(
            'correct_answer'.tr(args: [expected]),
            style: const TextStyle(color: Colors.red),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Eşleşme: %${(score * 100).toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}

// ── Mic Button ────────────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.isListening,
    required this.hasPermission,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final bool isListening;
  final bool hasPermission;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    final color =
        isListening ? Colors.red : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: hasPermission ? (_) => onPressStart() : null,
      onTapUp: isListening ? (_) => onPressEnd() : null,
      onTapCancel: isListening ? onPressEnd : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isListening ? 110 : 96,
        height: isListening ? 110 : 96,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          size: 48,
          color: color,
        ),
      ),
    );
  }
}
