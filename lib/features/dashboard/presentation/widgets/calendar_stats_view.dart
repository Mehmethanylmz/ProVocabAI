// lib/features/dashboard/presentation/widgets/calendar_stats_view.dart
//
// FAZ 12 — F12-09: Ay takvimi + gün bazlı istatistik görünümü
//   - Ay navigasyonu (önceki/sonraki)
//   - Aktiviteye göre renklendirilmiş günler
//   - Seçili gün → detay satırı

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/init/theme/app_theme_extension.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

class CalendarStatsView extends StatefulWidget {
  final List<DayActivity> heatmapData;

  const CalendarStatsView({super.key, required this.heatmapData});

  @override
  State<CalendarStatsView> createState() => _CalendarStatsViewState();
}

class _CalendarStatsViewState extends State<CalendarStatsView> {
  late DateTime _viewMonth;
  String? _selectedDate;

  // Day lookup from heatmap data
  late Map<String, DayActivity> _lookup;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
    _lookup = {for (final d in widget.heatmapData) d.date: d};
  }

  @override
  void didUpdateWidget(CalendarStatsView old) {
    super.didUpdateWidget(old);
    _lookup = {for (final d in widget.heatmapData) d.date: d};
  }

  String _toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _levelFor(int count) {
    if (count == 0) return 0;
    if (count <= 5) return 1;
    if (count <= 15) return 2;
    if (count <= 30) return 3;
    return 4;
  }

  Color _cellColor(int level, AppThemeExtension ext) {
    if (level == 0) return Colors.transparent;
    final alphas = [0.0, 0.2, 0.45, 0.7, 1.0];
    return ext.success.withValues(alpha: alphas[level]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final today = DateTime.now();

    // Calendar grid for _viewMonth
    final firstDay = _viewMonth;
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);

    // ISO weekday of first day: Mon=1..Sun=7
    // We use Mon-start grid
    final startOffset = (firstDay.weekday - 1) % 7;

    // Build all cells: blanks + days
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    final selectedActivity =
        _selectedDate != null ? _lookup[_selectedDate!] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Month navigation ───────────────────────────────────────────────
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => setState(() {
                _viewMonth =
                    DateTime(_viewMonth.year, _viewMonth.month - 1);
                _selectedDate = null;
              }),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              iconSize: 18,
            ),
            Expanded(
              child: Text(
                '${_monthName(_viewMonth.month)} ${_viewMonth.year}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _viewMonth.year < today.year ||
                      _viewMonth.month < today.month
                  ? () => setState(() {
                        _viewMonth =
                            DateTime(_viewMonth.year, _viewMonth.month + 1);
                        _selectedDate = null;
                      })
                  : null,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                backgroundColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              iconSize: 18,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Day header ────────────────────────────────────────────────────
        Row(
          children: dayNames.map((name) {
            return Expanded(
              child: Center(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 4),

        // ── Calendar grid ─────────────────────────────────────────────────
        ...List.generate(rows, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - startOffset + 1;
                if (dayNum < 1 || dayNum > lastDay.day) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(_viewMonth.year, _viewMonth.month, dayNum);
                final dateStr = _toDateStr(date);
                final activity = _lookup[dateStr];
                final count = activity?.questionCount ?? 0;
                final level = _levelFor(count);
                final isFuture = date.isAfter(today);
                final isToday = dateStr == _toDateStr(today);
                final isSelected = _selectedDate == dateStr;

                return Expanded(
                  child: GestureDetector(
                    onTap: isFuture
                        ? null
                        : () => setState(() {
                              _selectedDate =
                                  isSelected ? null : dateStr;
                            }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFuture
                            ? Colors.transparent
                            : isSelected
                                ? scheme.primary.withValues(alpha: 0.2)
                                : _cellColor(level, ext),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: scheme.primary, width: 1.5)
                            : isSelected
                                ? Border.all(
                                    color: scheme.primary, width: 1.5)
                                : level > 0
                                    ? Border.all(
                                        color: ext.success
                                            .withValues(alpha: 0.3))
                                    : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isFuture
                                ? scheme.onSurface.withValues(alpha: 0.2)
                                : isSelected
                                    ? scheme.primary
                                    : level > 0
                                        ? ext.success
                                        : scheme.onSurface
                                            .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),

        // ── Seçili gün detayı ─────────────────────────────────────────────
        if (_selectedDate != null) ...[
          const SizedBox(height: 12),
          _DayDetail(
            date: _selectedDate!,
            activity: selectedActivity,
          ),
        ],
      ],
    );
  }

  String _monthName(int m) {
    const names = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return m >= 1 && m <= 12 ? names[m] : '';
  }
}

class _DayDetail extends StatelessWidget {
  final String date;
  final DayActivity? activity;

  const _DayDetail({required this.date, this.activity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final q = activity?.questionCount ?? 0;
    final correct = activity?.correctCount ?? 0;
    final wrong = q - correct;
    final mins = activity?.timeMinutes ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: q == 0
          ? Row(
              children: [
                Icon(Icons.sentiment_neutral_rounded,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Text(
                  '$date — Aktivite yok',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatChip(
                        label: '$q soru', color: scheme.primary),
                    const SizedBox(width: 8),
                    _StatChip(label: '$correct doğru', color: ext.success),
                    const SizedBox(width: 8),
                    _StatChip(label: '$wrong yanlış', color: scheme.error),
                    if (mins > 0) ...[
                      const SizedBox(width: 8),
                      _StatChip(label: '$mins dk', color: ext.tertiary),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
