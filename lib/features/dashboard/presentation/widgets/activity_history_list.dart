import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../view_model/dashboard_view_model.dart';

class ActivityHistoryList extends StatefulWidget {
  const ActivityHistoryList({super.key});

  @override
  State<ActivityHistoryList> createState() => _ActivityHistoryListState();
}

class _ActivityHistoryListState extends State<ActivityHistoryList> {
  String? _selectedMonth;
  String? _selectedWeek;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardViewModel>();
    final monthlyActivity = provider.monthlyActivity;

    if (provider.isLoading && monthlyActivity.isEmpty) {
      return _buildLoadingState(context);
    }

    if (monthlyActivity.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        _buildMonthSelector(monthlyActivity, context),
        SizedBox(height: context.responsive.spacingM),
        if (_selectedMonth != null)
          _buildMonthDetail(context, provider, _selectedMonth!),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: context.responsive.value(mobile: 200, tablet: 250, desktop: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          context.colors.primary.withOpacity(0.05),
          context.ext.info.withOpacity(0.05)
        ]),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
      ),
      child: Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      ),
    ).animate().fadeIn();
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
            size:
                context.responsive.value(mobile: 60, tablet: 80, desktop: 100),
            color: context.colors.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: context.responsive.spacingM),
          Text(
            'activity_empty_title'.tr(),
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
          SizedBox(height: context.responsive.spacingS),
          Text(
            'activity_empty_desc'.tr(),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(
      List<Map<String, dynamic>> monthlyActivity, BuildContext context) {
    if (_selectedMonth == null && monthlyActivity.isNotEmpty) {
      _selectedMonth = monthlyActivity.first['monthYear'] as String;
    }

    return SizedBox(
      height: context.responsive.value(mobile: 110, tablet: 140, desktop: 160),
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

    final gradients = [
      context.ext.gradientPurple,
      [context.ext.success, context.ext.success.withOpacity(0.7)],
      [context.ext.warning, context.ext.warning.withOpacity(0.7)],
      context.ext.gradientBlue,
    ];
    final gradient = gradients[int.parse(parts[1]) % gradients.length];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.spacingS),
      child: InkWell(
        onTap: () => setState(() {
          _selectedMonth = monthData['monthYear'];
          _selectedWeek = null;
        }),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width:
              context.responsive.value(mobile: 130, tablet: 160, desktop: 180),
          padding: EdgeInsets.all(context.responsive.spacingM),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: gradient)
                : LinearGradient(
                    colors: [context.colors.surface, context.colors.surface]),
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : gradient[0].withOpacity(0.3),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                monthName,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? context.colors.onPrimary : gradient[0],
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
              SizedBox(height: context.responsive.spacingS),
              Text(
                '%${successRate.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH2,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? context.colors.onPrimary : gradient[0],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms);
  }

  Widget _buildMonthDetail(
      BuildContext context, DashboardViewModel provider, String monthYear) {
    final weeklyData = provider.getWeeklyActivity(monthYear);
    final monthData = provider.monthlyActivity.firstWhere(
      (m) => m['monthYear'] == monthYear,
      orElse: () => {'total': 0, 'correct': 0},
    );

    final total = (monthData['total'] as int?) ?? 0;
    final correct = (monthData['correct'] as int?) ?? 0;
    final wrong = total - correct;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(context.responsive.spacingM),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
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
              _buildStatItem("total".tr(), "$total", Icons.quiz,
                  context.ext.info, context),
              _buildStatItem("correct".tr(), "$correct", Icons.check_circle,
                  context.ext.success, context),
              _buildStatItem("incorrect".tr(), "$wrong", Icons.cancel,
                  context.colors.error, context),
              _buildStatItem(
                  "success_rate".tr(),
                  "%${successRate.toStringAsFixed(0)}",
                  Icons.percent,
                  context.colors.primary,
                  context),
            ],
          ),
        ),
        SizedBox(height: context.responsive.spacingM),
        if (weeklyData.isNotEmpty)
          _buildWeekSelector(weeklyData, monthYear, context),
        SizedBox(height: context.responsive.spacingM),
        if (_selectedWeek != null)
          _buildWeekDetail(context, provider, _selectedWeek!, monthYear),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: context.responsive.iconSizeM),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSelector(List<Map<String, dynamic>> weeklyData,
      String monthYear, BuildContext context) {
    if (_selectedWeek == null && weeklyData.isNotEmpty) {
      _selectedWeek = weeklyData.first['weekOfYear'] as String;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: context.responsive.spacingS,
            bottom: context.responsive.spacingS,
          ),
          child: Text(
            'activity_weekly_performance'.tr(),
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height:
              context.responsive.value(mobile: 90, tablet: 110, desktop: 130),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weeklyData.length,
            padding: context.responsive.paddingPage.copyWith(top: 0, bottom: 0),
            itemBuilder: (context, index) {
              final weekData = weeklyData[index];
              final isSelected = _selectedWeek == weekData['weekOfYear'];
              return _buildWeekChip(weekData, isSelected, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekChip(
      Map<String, dynamic> weekData, bool isSelected, BuildContext context) {
    final weekOfYear = weekData['weekOfYear'] as String;
    final total = (weekData['total'] as int?) ?? 0;
    final weekStartDate = DateTime.fromMillisecondsSinceEpoch(
        ((weekData['weekStartDate'] as int?) ?? 0) * 1000);
    final weekNumber = (weekStartDate.day / 7).ceil();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.spacingS),
      child: InkWell(
        onTap: () => setState(() => _selectedWeek = weekOfYear),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width:
              context.responsive.value(mobile: 90, tablet: 110, desktop: 130),
          padding: EdgeInsets.all(context.responsive.spacingS),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.primary : context.colors.surface,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusM),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: context.colors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : context.colors.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${'week'.tr()} $weekNumber',
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? context.colors.onPrimary
                      : context.colors.onSurface,
                ),
              ),
              SizedBox(height: context.responsive.spacingXS),
              Text(
                '$total ${'questions'.tr()}',
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeCaption,
                  color: isSelected
                      ? context.colors.onPrimary.withOpacity(0.9)
                      : context.colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDetail(BuildContext context, DashboardViewModel provider,
      String weekOfYear, String monthYear) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getDailyStats(weekOfYear, monthYear.split('-')[0]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsive.spacingM),
              child: CircularProgressIndicator(color: context.colors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final dailyStats = snapshot.data!;
        int weekTotal = 0;
        int weekCorrect = 0;
        for (var day in dailyStats) {
          weekTotal += (day['total'] as int? ?? 0);
          weekCorrect += (day['correct'] as int? ?? 0);
        }
        int weekWrong = weekTotal - weekCorrect;
        double weekSuccessRate =
            weekTotal > 0 ? (weekCorrect / weekTotal * 100) : 0.0;

        return Container(
          padding: EdgeInsets.all(context.responsive.spacingM),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(context.responsive.spacingM),
                margin: EdgeInsets.only(bottom: context.responsive.spacingM),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusM),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("total".tr(), "$weekTotal", Icons.quiz,
                        context.ext.info, context),
                    _buildStatItem("correct".tr(), "$weekCorrect",
                        Icons.check_circle, context.ext.success, context),
                    _buildStatItem("incorrect".tr(), "$weekWrong", Icons.cancel,
                        context.colors.error, context),
                    _buildStatItem(
                        "success_rate".tr(),
                        "%${weekSuccessRate.toStringAsFixed(0)}",
                        Icons.percent,
                        context.colors.primary,
                        context),
                  ],
                ),
              ),
              ...dailyStats.map((day) => _buildDayRow(day, context)),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildDayRow(Map<String, dynamic> dayData, BuildContext context) {
    // Tarih ve veri işlemleri
    final date = DateTime.fromMillisecondsSinceEpoch(
        ((dayData['date'] as int?) ?? 0) * 1000);
    final total = (dayData['total'] as int?) ?? 0;
    final correct = (dayData['correct'] as int?) ?? 0;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;
    final rateColor = _getSuccessColor(context, successRate);

    return Padding(
      padding: EdgeInsets.only(bottom: context.responsive.spacingS),
      child: Row(
        children: [
          Container(
            width:
                context.responsive.value(mobile: 40, tablet: 48, desktop: 56),
            height:
                context.responsive.value(mobile: 40, tablet: 48, desktop: 56),
            decoration: BoxDecoration(
              color: rateColor.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(context.responsive.borderRadiusM),
            ),
            child: Center(
              child: Text(
                "${date.day}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: rateColor,
                ),
              ),
            ),
          ),
          SizedBox(width: context.responsive.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayName(date.weekday),
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "$total ${'questions'.tr()}",
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            "%${successRate.toStringAsFixed(0)}",
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: rateColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(String monthNum) {
    const monthNames = {
      '01': 'Jan',
      '02': 'Feb',
      '03': 'Mar',
      '04': 'Apr',
      '05': 'May',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Aug',
      '09': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec'
    };
    return monthNames[monthNum] ?? monthNum;
  }

  String _getDayName(int weekday) {
    const dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun'
    };
    return dayNames[weekday] ?? '';
  }

  Color _getSuccessColor(BuildContext context, double rate) {
    if (rate >= 80) return context.ext.success;
    if (rate >= 50) return context.ext.warning;
    return context.colors.error;
  }
}
