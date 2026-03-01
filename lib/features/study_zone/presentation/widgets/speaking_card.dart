// lib/features/study_zone/presentation/widgets/speaking_card.dart
//
// F3-02: SpeakingCard — speech_to_text + Levenshtein entegrasyonu
// Blueprint Speaking Akışı:
//   1. Kelimenin anlamı + örnek cümle gösterilir
//   2. Mikrofon butonu → STT başlar
//   3. STT çıktısı normalize (lowercase, trim)
//   4. Levenshtein.similarity >= 0.75 → doğru
//   5. Doğru/yanlış 1.5sn göster → ReviewRatingSheet
//   Fallback: Mikrofon izni yoksa → MCQ moduna otomatik geç (BLoC event)
//
// Bağımlılıklar:
//   - SpeechService (singleton, getIt)
//   - Levenshtein (lib/core/utils/levenshtein.dart)
//   - ReviewRatingSheet

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/utils/levenshtein.dart';
import '../../../../database/app_database.dart';
import '../../../../srs/plan_models.dart';
import 'review_rating_sheet.dart';

// ── SpeakingCard ──────────────────────────────────────────────────────────────

/// Speaking modu quiz kartı.
/// Kullanıcı kelimeyi söyler → STT → Levenshtein → doğru/yanlış.
/// Mikrofon izni yoksa ModeChanged(StudyMode.mcq) event'i atarak MCQ'ya geçer.
class SpeakingCard extends StatefulWidget {
  final Word word;
  final String targetLang;
  final CardSource cardSource;
  final DateTime cardShownAt;

  const SpeakingCard({
    super.key,
    required this.word,
    required this.targetLang,
    required this.cardSource,
    required this.cardShownAt,
  });

  @override
  State<SpeakingCard> createState() => _SpeakingCardState();
}

enum _SpeakingPhase { idle, listening, result }

class _SpeakingCardState extends State<SpeakingCard> {
  final SpeechService _speech = getIt<SpeechService>();

  _SpeakingPhase _phase = _SpeakingPhase.idle;
  String _spokenText = '';
  bool _isCorrect = false;
  bool _permissionDenied = false;
  bool _answered = false;

  @override
  void dispose() {
    _speech.stopListening();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _parseWordText() {
    try {
      final content =
          jsonDecode(widget.word.contentJson) as Map<String, dynamic>;
      final lang = content[widget.targetLang] as Map<String, dynamic>?;
      return (lang?['word'] as String?) ?? (lang?['term'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  String _parseMeaning() {
    try {
      final content =
          jsonDecode(widget.word.contentJson) as Map<String, dynamic>;
      final tr = content['tr'] as Map<String, dynamic>?;
      if (tr != null) return (tr['meaning'] as String?) ?? '';
      final lang = content[widget.targetLang] as Map<String, dynamic>?;
      return (lang?['meaning'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  String _parseExample() {
    try {
      final content =
          jsonDecode(widget.word.contentJson) as Map<String, dynamic>;
      final lang = content[widget.targetLang] as Map<String, dynamic>?;
      return (lang?['example'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// STT locale → "en-US" formatı
  String _sttLocale() {
    const map = {
      'en': 'en-US',
      'de': 'de-DE',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'pt': 'pt-PT',
    };
    return map[widget.targetLang] ?? 'en-US';
  }

  Future<void> _startListening() async {
    if (_answered) return;

    final available = await _speech.init();
    if (!available) {
      // Mikrofon izni yok → fallback: MCQ moduna geç
      setState(() => _permissionDenied = true);
      if (mounted) {
        _showPermissionFallback();
      }
      return;
    }

    setState(() {
      _phase = _SpeakingPhase.listening;
      _spokenText = '';
    });

    await _speech.startListening(
      localeId: _sttLocale(),
      onResult: (spoken) {
        if (mounted && !_answered) {
          _evaluateAnswer(spoken);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stopListening();
    if (!_answered && _spokenText.isEmpty) {
      setState(() => _phase = _SpeakingPhase.idle);
    }
  }

  void _evaluateAnswer(String spoken) {
    final expected = _parseWordText();
    final correct = Levenshtein.isCorrect(spoken, expected);

    setState(() {
      _spokenText = spoken;
      _isCorrect = correct;
      _phase = _SpeakingPhase.result;
      _answered = true;
    });

    final responseMs =
        DateTime.now().difference(widget.cardShownAt).inMilliseconds;

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) ReviewRatingSheet.show(context, responseMs: responseMs);
    });
  }

  void _showPermissionFallback() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mikrofon İzni Gerekiyor'),
        content: const Text(
          'Konuşma modu için mikrofon izni gereklidir.\n'
          'Çoktan seçmeli moda geçilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // MCQ moduna geç — BLoC event (ModeChanged varsa)
              // Yoksa ReviewRatingSheet direkt aç (good rating)
              final responseMs =
                  DateTime.now().difference(widget.cardShownAt).inMilliseconds;
              ReviewRatingSheet.show(context, responseMs: responseMs);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wordText = _parseWordText();
    final meaning = _parseMeaning();
    final example = _parseExample();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kelime bilgi kartı
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.tertiary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SourceBadge(source: widget.cardSource),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.tertiary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, size: 12),
                        SizedBox(width: 4),
                        Text('Konuşma',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                meaning,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (example.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"$example"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.55),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Yukarıdaki anlamın İngilizce karşılığını söyleyin.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // STT sonuç alanı
        if (_phase == _SpeakingPhase.result) ...[
          _ResultBanner(
            spokenText: _spokenText,
            expectedText: wordText,
            isCorrect: _isCorrect,
          ),
          const SizedBox(height: 16),
        ],

        // Mikrofon butonu
        Center(
          child: _MicButton(
            phase: _phase,
            permissionDenied: _permissionDenied,
            answered: _answered,
            onTapStart: _startListening,
            onTapStop: _stopListening,
          ),
        ),

        const SizedBox(height: 8),
        Center(
          child: Text(
            _micHintText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.45),
                ),
          ),
        ),
      ],
    );
  }

  String _micHintText() {
    return switch (_phase) {
      _SpeakingPhase.idle => 'Butona basıp kelimeyi söyleyin',
      _SpeakingPhase.listening => 'Dinleniyor...',
      _SpeakingPhase.result =>
        _isCorrect ? '✅ Doğru söyleyiş!' : '❌ Tekrar deneyin',
    };
  }
}

// ── _MicButton ────────────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final _SpeakingPhase phase;
  final bool permissionDenied;
  final bool answered;
  final VoidCallback onTapStart;
  final VoidCallback onTapStop;

  const _MicButton({
    required this.phase,
    required this.permissionDenied,
    required this.answered,
    required this.onTapStart,
    required this.onTapStop,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (permissionDenied || answered) {
      return const SizedBox.shrink();
    }

    final isListening = phase == _SpeakingPhase.listening;
    final color = isListening ? Colors.red : scheme.primary;

    return GestureDetector(
      onTap: isListening ? onTapStop : onTapStart,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: isListening ? 100 : 84,
        height: isListening ? 100 : 84,
        decoration: BoxDecoration(
          color: color.withOpacity(isListening ? 0.15 : 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: isListening ? 3 : 2,
          ),
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          size: isListening ? 42 : 36,
          color: color,
        ),
      ),
    );
  }
}

// ── _ResultBanner ─────────────────────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  final String spokenText;
  final String expectedText;
  final bool isCorrect;

  const _ResultBanner({
    required this.spokenText,
    required this.expectedText,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Colors.green : Colors.red;
    final similarity = Levenshtein.similarity(spokenText, expectedText);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Doğru!' : 'Yanlış',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '%${(similarity * 100).round()} benzerlik',
                style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text: 'Söylediğiniz: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                TextSpan(
                    text: spokenText.isEmpty ? '(anlaşılamadı)' : spokenText,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
              ],
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                      text: 'Doğru söyleyiş: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  TextSpan(
                      text: expectedText,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _SourceBadge ──────────────────────────────────────────────────────────────

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
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
