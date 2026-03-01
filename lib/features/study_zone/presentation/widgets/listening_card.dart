// lib/features/study_zone/presentation/widgets/listening_card.dart
//
// F3-01: ListeningCard — flutter_tts entegrasyonu
// Blueprint Listening Akışı:
//   1. TtsService → kelime sesini çal (hedef dil)
//   2. 4 seçenek (Türkçe anlamlar: 1 doğru + 3 decoy)
//   3. Seçim → 1.5sn renk feedback → ReviewRatingSheet
//   Fallback: TTS başlatılamazsa yazılı kelimeyi göster + uyarı banner
//
// Bağımlılıklar:
//   - TtsService (singleton, getIt)
//   - Word entity (contentJson parse)
//   - ReviewRatingSheet

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../database/app_database.dart';
import '../../../../srs/plan_models.dart';
import 'review_rating_sheet.dart';

// ── ListeningCard ─────────────────────────────────────────────────────────────

/// Listening modu quiz kartı.
/// [word]: hedef kelime, [decoys]: 3 yanlış şık, [targetLang]: 'en' | 'de' vb.
/// [onAnswered]: cevap seçilip 1.5sn sonra ReviewRatingSheet açıldığında
///               parent'ı bilgilendirmek için (opsiyonel).
class ListeningCard extends StatefulWidget {
  final Word word;
  final List<Word> decoys;
  final String targetLang;
  final CardSource cardSource;
  final DateTime cardShownAt;

  const ListeningCard({
    super.key,
    required this.word,
    required this.decoys,
    required this.targetLang,
    required this.cardSource,
    required this.cardShownAt,
  });

  @override
  State<ListeningCard> createState() => _ListeningCardState();
}

class _ListeningCardState extends State<ListeningCard> {
  final TtsService _tts = getIt<TtsService>();

  bool _answered = false;
  String? _selectedOption;
  bool _ttsError = false;
  bool _ttsPlaying = false;
  late List<_Opt> _options;

  @override
  void initState() {
    super.initState();
    _options = _buildOptions();
    // Kart açılınca otomatik ses çal
    WidgetsBinding.instance.addPostFrameCallback((_) => _playWord());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<_Opt> _buildOptions() {
    final correctMeaning = _parseMeaning(widget.word);
    final opts = <_Opt>[_Opt(text: correctMeaning, isCorrect: true)];

    for (final decoy in widget.decoys) {
      final m = _parseMeaning(decoy);
      if (m.isNotEmpty && m != correctMeaning) {
        opts.add(_Opt(text: m, isCorrect: false));
      }
    }
    while (opts.length < 4) {
      opts.add(_Opt(text: '—', isCorrect: false));
    }
    opts.shuffle();
    return opts.take(4).toList();
  }

  /// contentJson → Türkçe anlam (native language = 'tr').
  /// Eğer tr yoksa meaning alanını dene.
  String _parseMeaning(Word word) {
    try {
      final content = jsonDecode(word.contentJson) as Map<String, dynamic>;
      // Önce Türkçe
      final tr = content['tr'] as Map<String, dynamic>?;
      if (tr != null) return (tr['meaning'] as String?) ?? '';
      // Yoksa hedef dil
      final lang = content[widget.targetLang] as Map<String, dynamic>?;
      return (lang?['meaning'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

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

  Future<void> _playWord() async {
    final text = _parseWordText();
    if (text.isEmpty) {
      setState(() => _ttsError = true);
      return;
    }
    setState(() => _ttsPlaying = true);
    try {
      await _tts.speak(text, widget.targetLang);
    } catch (_) {
      if (mounted) setState(() => _ttsError = true);
    } finally {
      if (mounted) setState(() => _ttsPlaying = false);
    }
  }

  void _onSelect(String option) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedOption = option;
    });
    final responseMs =
        DateTime.now().difference(widget.cardShownAt).inMilliseconds;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) ReviewRatingSheet.show(context, responseMs: responseMs);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TTS hata banner
        if (_ttsError) _TtsFallbackBanner(wordText: _parseWordText()),

        // Ses çalma kartı
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.secondary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _SourceBadge(source: widget.cardSource),
              const SizedBox(height: 16),

              // Büyük hoparlör ikonu
              GestureDetector(
                onTap: _ttsPlaying ? null : _playWord,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _ttsPlaying
                        ? scheme.secondary.withOpacity(0.2)
                        : scheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _ttsPlaying
                        ? Icons.volume_up_rounded
                        : Icons.play_circle_fill_rounded,
                    size: 48,
                    color: scheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _ttsPlaying ? 'Çalıyor...' : 'Kelimeyi Dinle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
              ),

              // Tekrar dinle butonu (küçük)
              if (!_ttsPlaying) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const Key('replay_button'),
                  onPressed: _playWord,
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Tekrar Dinle',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),
        Text(
          'Hangi anlama geliyor?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.5),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Seçenekler
        ..._options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                text: opt.text,
                isCorrect: opt.isCorrect,
                answered: _answered,
                isSelected: _selectedOption == opt.text,
                onTap: () => _onSelect(opt.text),
              ),
            )),
      ],
    );
  }
}

// ── SpeakingCard ──────────────────────────────────────────────────────────────
// Dosya adı listening_card.dart ama speaking card'ı da burada değil,
// speaking_card.dart ayrı dosyada — bu dosya sadece ListeningCard içerir.

// ── Private Widgets ───────────────────────────────────────────────────────────

class _Opt {
  final String text;
  final bool isCorrect;
  const _Opt({required this.text, required this.isCorrect});
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool isCorrect;
  final bool answered;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
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
                child: Text(text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500)),
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

class _TtsFallbackBanner extends StatelessWidget {
  final String wordText;
  const _TtsFallbackBanner({required this.wordText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_off, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Ses çalınamadı. Kelime: ',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
                children: [
                  TextSpan(
                    text: wordText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
