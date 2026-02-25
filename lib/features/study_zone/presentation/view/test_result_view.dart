import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../domain/entities/word_entity.dart';
import '../../../main/presentation/view/main_view.dart';

class TestResultView extends StatefulWidget {
  const TestResultView({super.key});

  @override
  State<TestResultView> createState() => _TestResultViewState();
}

class _TestResultViewState extends State<TestResultView> {
  bool _resultSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_resultSaved) return;
      final vm = context.read<StudyViewModel>();
      if (vm.correctCount + vm.incorrectCount > 0) {
        await vm.saveTestResult();
        _resultSaved = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyViewModel>(
      builder: (context, vm, _) {
        final correct = vm.correctCount;
        final wrong = vm.incorrectCount;
        final total = correct + wrong;
        final successRate = total > 0 ? (correct / total) * 100 : 0.0;
        final duration = vm.testDuration;
        final wrongWords = vm.wrongAnswersInSession;

        final Color accentColor = successRate >= 80
            ? const Color(0xFFFFC107)
            : successRate >= 50
                ? const Color(0xFF00E5A0)
                : context.colors.error;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF0A0A0F),
                pinned: true,
                title: Text(
                  'test_result_title'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainView()),
                      (r) => false,
                    ),
                    icon: const Icon(Icons.home_rounded,
                        color: Colors.white54, size: 18),
                    label: Text(
                      'btn_home'.tr(),
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                  ),
                ],
              ),

              // ── Sonuç Kartı ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _ResultSummaryCard(
                    correct: correct,
                    wrong: wrong,
                    total: total,
                    successRate: successRate,
                    duration: duration,
                    accentColor: accentColor,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: Offset(0.95, 0.95)),
                ),
              ),

              // ── Yanlış Kelimeler ──────────────────────────────────────────
              if (wrongWords.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: context.colors.error,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Yanlış Yapılan Kelimeler (${wrongWords.length})',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _WrongWordCard(
                      word: wrongWords[i],
                      sourceLang: context.read<StudyViewModel>().sourceLang,
                      targetLang: context.read<StudyViewModel>().targetLang,
                      index: i,
                    ).animate().fadeIn(delay: (80 * i).ms).slideX(begin: 0.08),
                    childCount: wrongWords.length,
                  ),
                ),
              ] else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.celebration_rounded,
                            color: Color(0xFFFFC107), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Hiç yanlış yapmadınız! 🎉',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                  ),
                ),
              ],

              // ── Alt boşluk ────────────────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        );
      },
    );
  }
}

// ── Özet Kart ─────────────────────────────────────────────────────────────────

class _ResultSummaryCard extends StatelessWidget {
  final int correct;
  final int wrong;
  final int total;
  final double successRate;
  final Duration duration;
  final Color accentColor;

  const _ResultSummaryCard({
    required this.correct,
    required this.wrong,
    required this.total,
    required this.successRate,
    required this.duration,
    required this.accentColor,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}d ${s}s';
    return '${s} saniye';
  }

  @override
  Widget build(BuildContext context) {
    final emoji = successRate >= 80
        ? '🏆'
        : successRate >= 50
            ? '👍'
            : '💪';

    final label = successRate >= 80
        ? 'Mükemmel!'
        : successRate >= 50
            ? 'test_result_good'.tr()
            : 'Daha fazla çalış!';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF131320),
            const Color(0xFF0D0D1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Emoji + başlık ──────────────────────────────────────────
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: accentColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 24),

            // ── Büyük yüzde göstergesi ──────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: successRate / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '%${successRate.toInt()}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'başarı',
                      style: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── İstatistik kutuları ─────────────────────────────────────
            Row(
              children: [
                _StatBox(
                  label: 'Doğru',
                  value: '$correct',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF00E5A0),
                ),
                const SizedBox(width: 10),
                _StatBox(
                  label: 'Yanlış',
                  value: '$wrong',
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFFF5C5C),
                ),
                const SizedBox(width: 10),
                _StatBox(
                  label: 'Toplam',
                  value: '$total',
                  icon: Icons.format_list_numbered_rounded,
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 10),
                _StatBox(
                  label: 'Süre',
                  value: _formatDuration(duration),
                  icon: Icons.timer_rounded,
                  color: const Color(0xFF48CFE8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Kutusu ───────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Yanlış Kelime Kartı ───────────────────────────────────────────────────────

class _WrongWordCard extends StatelessWidget {
  final WordEntity word;
  final String sourceLang;
  final String targetLang;
  final int index;

  const _WrongWordCard({
    required this.word,
    required this.sourceLang,
    required this.targetLang,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final targetContent = word.getLocalizedContent(targetLang);
    final sourceContent = word.getLocalizedContent(sourceLang);
    final targetWord = targetContent['word'] ?? '—';
    final sourceWord = sourceContent['word'] ?? '—';
    final example = targetContent['example_sentence'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Index
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Hedef kelime
                  Expanded(
                    child: Text(
                      targetWord,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Ok
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white24, size: 16),
                  const SizedBox(width: 8),

                  // Kaynak kelime
                  Text(
                    sourceWord,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Örnek cümle
              if (example.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✦ ',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 10)),
                      Expanded(
                        child: Text(
                          example,
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
