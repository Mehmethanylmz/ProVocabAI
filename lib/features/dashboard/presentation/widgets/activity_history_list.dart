// lib/features/dashboard/presentation/widgets/activity_history_list.dart
//
// REWRITE: context.watch<DashboardViewModel>() → prop injection
// Widget artık dışarıdan monthlyActivity listesini alıyor (SRP: sadece UI)
// Provider import kaldırıldı.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';

class ActivityHistoryList extends StatefulWidget {
  final List<Map<String, dynamic>> monthlyActivity;

  const ActivityHistoryList({
    super.key,
    required this.monthlyActivity,
  });

  @override
  State<ActivityHistoryList> createState() => _ActivityHistoryListState();
}

class _ActivityHistoryListState extends State<ActivityHistoryList> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final monthlyActivity = widget.monthlyActivity;

    if (monthlyActivity.isEmpty) {
      return _buildEmptyState(context);
    }

    // İlk ay varsayılan seçili
    _selectedMonth ??= (monthlyActivity.isNotEmpty
        ? monthlyActivity.first['monthYear'] as String
        : null);

    return Column(
      children: [
        _buildMonthSelector(monthlyActivity, context),
        SizedBox(height: context.responsive.spacingM),
        if (_selectedMonth != null) _buildMonthDetail(context, _selectedMonth!),
      ],
    );
  }

  Widget _buildMonthSelector(
      List<Map<String, dynamic>> monthlyActivity, BuildContext context) {
    return SizedBox(
      height: context.responsive
          .value(mobile: 110, tablet: 140, desktop: 160)
          .toDouble(),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: monthlyActivity.length,
        padding: context.responsive.paddingPage.copyWith(top: 0, bottom: 0),
        itemBuilder: (context, index) {
          final monthData = monthlyActivity[index];
          final isSelected = _selectedMonth == monthData['monthYear'];
          return _buildMonthChip(monthData, isSelected, context);
        },
      ),
    );
  }

  Widget _buildMonthChip(
      Map<String, dynamic> monthData, bool isSelected, BuildContext context) {
    final parts = (monthData['monthYear'] as String).split('-');
    final monthName = _getMonthName(parts[1]);
    final year = parts[0];
    final total = (monthData['total'] as int?) ?? 0;
    final correct = (monthData['correct'] as int?) ?? 0;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;

    final gradient = isSelected
        ? [context.colors.primary, context.colors.secondary]
        : [
            context.colors.surface,
            context.colors.surface,
          ];

    return GestureDetector(
      onTap: () => setState(() => _selectedMonth = monthData['monthYear']),
      child: Container(
        width: context.responsive
            .value(mobile: 100, tablet: 120, desktop: 140)
            .toDouble(),
        margin: EdgeInsets.only(right: context.responsive.spacingS),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
          border: Border.all(
            color:
                isSelected ? Colors.transparent : context.colors.outlineVariant,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.responsive.spacingS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                monthName,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeCaption,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? context.colors.onPrimary
                      : context.colors.onSurface,
                ),
              ),
              Text(
                year,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeCaption,
                  color: isSelected
                      ? context.colors.onPrimary.withOpacity(0.9)
                      : context.colors.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: context.responsive.spacingXS),
              Text(
                '%${successRate.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH2,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? context.colors.onPrimary
                      : context.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms),
    );
  }

  Widget _buildMonthDetail(BuildContext context, String monthYear) {
    final monthData = widget.monthlyActivity.firstWhere(
      (m) => m['monthYear'] == monthYear,
      orElse: () => {'total': 0, 'correct': 0},
    );

    final total = (monthData['total'] as int?) ?? 0;
    final correct = (monthData['correct'] as int?) ?? 0;
    final wrong = total - correct;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;

    return Container(
      padding: EdgeInsets.all(context.responsive.spacingM),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
              'total'.tr(), '$total', Icons.quiz, context.ext.info, context),
          _buildStatItem('correct'.tr(), '$correct', Icons.check_circle,
              context.ext.success, context),
          _buildStatItem('incorrect'.tr(), '$wrong', Icons.cancel,
              context.colors.error, context),
          _buildStatItem(
              'success_rate'.tr(),
              '%${successRate.toStringAsFixed(0)}',
              Icons.percent,
              context.colors.primary,
              context),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: context.responsive.iconSizeM),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: context.responsive.fontSizeH3,
            color: context.colors.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeCaption,
            color: context.colors.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.spacingXL),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            size: context.responsive
                .value(mobile: 60, tablet: 80, desktop: 100)
                .toDouble(),
            color: context.colors.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: context.responsive.spacingM),
          Text(
            'activity_empty_title'.tr(),
            style: context.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: context.responsive.spacingS),
          Text(
            'activity_empty_desc'.tr(),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: context.colors.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  String _getMonthName(String monthNum) {
    const months = [
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
    final idx = int.tryParse(monthNum) ?? 0;
    return idx >= 1 && idx <= 12 ? months[idx] : '';
  }
}
