// lib/features/dashboard/presentation/widgets/heatmap_widget.dart
//
// FAZ 12 — F12-05: GitHub contribution graph benzeri ısı haritası
//   - 26 hafta × 7 gün grid
//   - 5 renk seviyesi (0=boş, 1-4=açık→koyu yeşil)
//   - Gün etiketi solda, ay etiketi üstte
//   - Hücreye tıklanınca seçili gün callback

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/init/theme/app_theme_extension.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

class HeatmapWidget extends StatefulWidget {
  final List<DayActivity> data;

  /// Seçili güne tıklanınca çağrılır. null = seçim kaldırıldı.
  final ValueChanged<DayActivity?>? onDayTap;

  const HeatmapWidget({
    super.key,
    required this.data,
    this.onDayTap,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  DayActivity? _selected;

  // Renk seviyeleri (questionCount bazlı)
  static int _levelFor(int count) {
    if (count == 0) return 0;
    if (count <= 5) return 1;
    if (count <= 15) return 2;
    if (count <= 30) return 3;
    return 4;
  }

  static Color _colorFor(int level, ColorScheme scheme, AppThemeExtension ext) {
    if (level == 0) {
      return scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    }
    final alphas = [0.0, 0.25, 0.45, 0.70, 1.0];
    return ext.success.withValues(alpha: alphas[level]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    // Build lookup map: 'yyyy-MM-dd' → DayActivity
    final lookup = {for (final d in widget.data) d.date: d};

    // Compute 26-week grid ending today
    final today = DateTime.now();
    // Start from the most recent Sunday (or Monday) → align to week start
    // We'll use ISO week: Mon=1...Sun=7, so start from last Monday
    final endDate = today;
    // Go back 181 days (26 weeks = 182 days)
    final startDate = today.subtract(const Duration(days: 181));

    // Build weeks: each week is a list of 7 days [Mon..Sun]
    final weeks = <List<DateTime>>[];
    var current = _weekStart(startDate);
    while (!current.isAfter(endDate)) {
      final week = List.generate(7, (i) => current.add(Duration(days: i)));
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }

    const cellSize = 11.0;
    const cellGap = 2.0;
    const dayLabelWidth = 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Grid ──────────────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels (Mon, Wed, Fri)
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 4),
                child: SizedBox(
                  width: dayLabelWidth,
                  child: Column(
                    children: List.generate(7, (i) {
                      const labels = ['S', 'P', 'S', 'Ç', 'P', 'C', 'P'];
                      final show = i == 0 || i == 2 || i == 4;
                      return SizedBox(
                        height: cellSize + cellGap,
                        child: show
                            ? Text(
                                labels[i],
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: scheme.onSurface.withValues(alpha: 0.4),
                                ),
                              )
                            : null,
                      );
                    }),
                  ),
                ),
              ),

              // Weeks
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month labels row
                  SizedBox(
                    height: 18,
                    child: Row(
                      children: weeks.asMap().entries.map((entry) {
                        final week = entry.value;
                        final firstDay = week.first;
                        // Show month label when month changes
                        final showLabel = entry.key == 0 ||
                            week.first.month !=
                                weeks[entry.key - 1].first.month;
                        return SizedBox(
                          width: cellSize + cellGap,
                          child: showLabel
                              ? Text(
                                  _monthAbbr(firstDay.month),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color:
                                        scheme.onSurface.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),

                  // Cell grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weeks.map((week) {
                      return Column(
                        children: week.map((day) {
                          final dateStr = _toDateStr(day);
                          final activity = lookup[dateStr];
                          final count = activity?.questionCount ?? 0;
                          final level = _levelFor(count);
                          final isSelected = _selected?.date == dateStr;
                          final isFuture = day.isAfter(today);

                          return GestureDetector(
                            onTap: isFuture
                                ? null
                                : () {
                                    setState(() {
                                      _selected = isSelected ? null : activity;
                                    });
                                    widget.onDayTap?.call(
                                        isSelected ? null : activity);
                                  },
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.all(cellGap / 2),
                              decoration: BoxDecoration(
                                color: isFuture
                                    ? Colors.transparent
                                    : _colorFor(level, scheme, ext),
                                borderRadius: BorderRadius.circular(2),
                                border: isSelected
                                    ? Border.all(
                                        color: scheme.primary, width: 1.5)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Renk açıklaması ───────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Az',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: _colorFor(i, scheme, ext),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            Text(
              'Çok',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),

        // ── Seçili gün özeti ──────────────────────────────────────────────
        if (_selected != null) ...[
          const SizedBox(height: 10),
          _SelectedDaySummary(activity: _selected!),
        ],
      ],
    );
  }

  DateTime _weekStart(DateTime date) {
    // ISO week: Monday = weekday 1
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  String _toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _monthAbbr(int month) {
    const abbr = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return month >= 1 && month <= 12 ? abbr[month] : '';
  }
}

class _SelectedDaySummary extends StatelessWidget {
  final DayActivity activity;
  const _SelectedDaySummary({required this.activity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 14, color: scheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            activity.date,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          _Pill(label: '${activity.questionCount} soru', color: scheme.primary),
          const SizedBox(width: 6),
          _Pill(label: '${activity.correctCount} doğru', color: ext.success),
          if (activity.timeMinutes > 0) ...[
            const SizedBox(width: 6),
            _Pill(label: '${activity.timeMinutes} dk', color: ext.tertiary),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
