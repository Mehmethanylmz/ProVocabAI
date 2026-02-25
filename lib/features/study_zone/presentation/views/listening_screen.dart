// lib/features/study_zone/presentation/views/listening_screen.dart
//
// T-23: ListeningScreen — REWRITE (listening_view.dart → listening_screen.dart)
//
// Silindi: lib/features/study_zone/presentation/view/listening_view.dart
//   git rm lib/features/study_zone/presentation/view/listening_view.dart
//
// Değişiklikler:
//   Provider/StudyViewModel → BlocBuilder<StudyZoneBloc>
//   reviewQueue → StudyZoneInSession.currentCard (BLoC state'den)
//   handleAnswer → bloc.add(AnswerSubmitted(rating, responseMs))
//   modeHistoryJson → ProgressDao.updateModeHistory() (SubmitReview use case'de)
//   wasCorrect (listening): normalizedUser == normalizedExpected (trim + lowercase)
//   Doğru/yanlış sonrası → bloc.add(NextCardRequested())

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../srs/fsrs_state.dart';
import '../../../../srs/plan_models.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';
import '../state/study_zone_state.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAnswered = false;
  bool _isCorrect = false;
  DateTime? _cardShownAt;

  @override
  void initState() {
    super.initState();
    _cardShownAt = DateTime.now();
    // TTS: kart gösterilince kelimeyi seslendir
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentCard());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _speakCurrentCard() async {
    final state = context.read<StudyZoneBloc>().state;
    if (state is! StudyZoneInSession) return;
    final card = state.currentCard;
    final tts = getIt<TtsService>();
    final word = _getWordText(card);
    if (word.isNotEmpty) {
      await tts.speak(word, state.targetLang);
    }
  }

  String _getWordText(PlanCard card) {
    final state = context.read<StudyZoneBloc>().state;
    if (state is StudyZoneInSession) {
      return state.currentWordText ?? '';
    }
    return '';
  }

  void _checkAnswer() {
    if (_isAnswered) return;
    final state = context.read<StudyZoneBloc>().state;
    if (state is! StudyZoneInSession) return;

    final expected = state.currentWordText ?? '';
    final userInput = _controller.text.trim().toLowerCase();
    final normalizedExpected = expected.trim().toLowerCase();

    final correct = userInput == normalizedExpected;
    final responseMs = DateTime.now()
        .difference(_cardShownAt ?? DateTime.now())
        .inMilliseconds;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    // Blueprint: listening'de wasCorrect = exact match (veya Levenshtein >= 0.75 ile genişletilebilir)
    final rating = correct ? ReviewRating.good : ReviewRating.again;
    context.read<StudyZoneBloc>().add(AnswerSubmitted(
          rating: rating,
          responseMs: responseMs,
        ));
  }

  void _nextCard() {
    _controller.clear();
    setState(() {
      _isAnswered = false;
      _isCorrect = false;
      _cardShownAt = DateTime.now();
    });
    context.read<StudyZoneBloc>().add(NextCardRequested());
    _speakCurrentCard();
    _focusNode.requestFocus();
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
            title: Text('listening_test'.tr()),
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

                // Dinleme ikonu + tekrar dinle butonu
                _ListenButton(onPressed: _speakCurrentCard),

                const SizedBox(height: 8),
                Text(
                  'listen_and_write'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Cevap kutusu
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !_isAnswered,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    hintText: 'write_here'.tr(),
                    border: const OutlineInputBorder(),
                    filled: true,
                    suffixIcon: _isAnswered
                        ? Icon(
                            _isCorrect ? Icons.check_circle : Icons.cancel,
                            color: _isCorrect ? Colors.green : Colors.red,
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _isAnswered ? null : _checkAnswer(),
                ),

                const SizedBox(height: 8),
                Text(
                  'case_sensitive_info'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),

                // Yanlış cevap → doğrusu göster
                if (_isAnswered && !_isCorrect) ...[
                  const SizedBox(height: 12),
                  Text(
                    'correct_answer'.tr(args: [state.currentWordText ?? '']),
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],

                const Spacer(),

                // Kontrol Et / Devam Et butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isAnswered ? _nextCard : _checkAnswer,
                    child: Text(_isAnswered
                        ? 'btn_continue'.tr()
                        : 'check_answer'.tr()),
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

// ── Listen Button ─────────────────────────────────────────────────────────────

class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.volume_up_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
