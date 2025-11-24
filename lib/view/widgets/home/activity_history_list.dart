import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../viewmodel/home_viewmodel.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/constants/app_colors.dart';

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
    final provider = context.watch<HomeViewModel>();
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
          AppColors.primary.withOpacity(0.05),
          AppColors.info.withOpacity(0.05)
        ]),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
      ),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.all(context.responsive.spacingXL), // paddingHigh yerine
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            size:
                context.responsive.value(mobile: 60, tablet: 80, desktop: 100),
            color: AppColors.textDisabled,
          ),
          SizedBox(height: context.responsive.spacingM),
          Text(
            'activity_empty_title'.tr(),
            style: GoogleFonts.poppins(
              fontSize: context.responsive.fontSizeH3,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.responsive.spacingS),
          Text(
            'activity_empty_desc'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: context.responsive.fontSizeBody,
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
      AppColors.gradientPurple,
      AppColors.gradientGreen,
      AppColors.gradientPink,
      AppColors.gradientBlue,
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
          padding: EdgeInsets.all(
              context.responsive.spacingM), // paddingMedium yerine
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: gradient)
                : LinearGradient(
                    colors: [AppColors.surface, AppColors.background]),
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
                      blurRadius: context.responsive
                          .value(mobile: 8, tablet: 12, desktop: 16),
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
                  color: isSelected ? AppColors.surface : gradient[0],
                ),
              ),
              Text(
                year,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeCaption,
                  color: isSelected
                      ? AppColors.surface.withOpacity(0.9)
                      : AppColors.textSecondary,
                ),
              ),
              SizedBox(height: context.responsive.spacingS),
              Text(
                '%${successRate.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH2,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.surface : gradient[0],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms);
  }

  Widget _buildMonthDetail(
      BuildContext context, HomeViewModel provider, String monthYear) {
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
          padding: EdgeInsets.all(
              context.responsive.spacingM), // paddingMedium yerine
          decoration: BoxDecoration(
            color: AppColors.surface,
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
              _buildStatItem(
                  "total".tr(), "$total", Icons.quiz, AppColors.info, context),
              _buildStatItem("correct".tr(), "$correct", Icons.check_circle,
                  AppColors.success, context),
              _buildStatItem("incorrect".tr(), "$wrong", Icons.cancel,
                  AppColors.error, context),
              _buildStatItem(
                  "success_rate".tr(),
                  "%${successRate.toStringAsFixed(0)}",
                  Icons.percent,
                  AppColors.primary,
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
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeH3,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeCaption,
            color: AppColors.textSecondary,
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
            style: GoogleFonts.poppins(
              fontSize: context.responsive.fontSizeH3,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
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
          padding: EdgeInsets.all(
              context.responsive.spacingS), // paddingNormal yerine spacingS
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusM),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.borderLight,
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
                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.responsive.spacingXS),
              Text(
                '$total ${'questions'.tr()}',
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeCaption,
                  color: isSelected
                      ? AppColors.surface.withOpacity(0.9)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDetail(BuildContext context, HomeViewModel provider,
      String weekOfYear, String monthYear) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getDailyStats(weekOfYear, monthYear.split('-')[0]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(
                  context.responsive.spacingM), // paddingMedium yerine
              child: CircularProgressIndicator(color: AppColors.primary),
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
          padding: EdgeInsets.all(
              context.responsive.spacingM), // paddingMedium yerine
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(
                    context.responsive.spacingM), // paddingMedium yerine
                margin: EdgeInsets.only(bottom: context.responsive.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusM),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("total".tr(), "$weekTotal", Icons.quiz,
                        AppColors.info, context),
                    _buildStatItem("correct".tr(), "$weekCorrect",
                        Icons.check_circle, AppColors.success, context),
                    _buildStatItem("incorrect".tr(), "$weekWrong", Icons.cancel,
                        AppColors.error, context),
                    _buildStatItem(
                        "success_rate".tr(),
                        "%${weekSuccessRate.toStringAsFixed(0)}",
                        Icons.percent,
                        AppColors.primary,
                        context),
                  ],
                ),
              ),
              Text(
                'activity_daily_detail'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH3,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: context.responsive.spacingM),
              ...dailyStats.map((dayData) => _buildDayRow(dayData, context)),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildDayRow(Map<String, dynamic> dayData, BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(
        ((dayData['date'] as int?) ?? 0) * 1000);
    final total = (dayData['total'] as int?) ?? 0;
    final correct = (dayData['correct'] as int?) ?? 0;
    final wrong = total - correct;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;

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
              color: AppColors.getSuccessColor(successRate).withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(context.responsive.borderRadiusM),
            ),
            child: Center(
              child: Text(
                "${date.day}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getSuccessColor(successRate),
                  fontSize: context.responsive.fontSizeBody,
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
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: context.responsive.fontSizeBody,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: context.responsive.spacingXS),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.spacingXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            context.responsive.borderRadiusS),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.quiz,
                            size: context.responsive.fontSizeCaption,
                            color: AppColors.info,
                          ),
                          SizedBox(width: context.responsive.spacingXS),
                          Text(
                            "$total",
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive.fontSizeCaption,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.responsive.spacingS),
                    Icon(
                      Icons.check_circle,
                      size: context.responsive.fontSizeCaption,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 2),
                    Text(
                      "$correct",
                      style: GoogleFonts.poppins(
                        color: AppColors.success,
                        fontSize: context.responsive.fontSizeCaption,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: context.responsive.spacingS),
                    Icon(
                      Icons.cancel,
                      size: context.responsive.fontSizeCaption,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 2),
                    Text(
                      "$wrong",
                      style: GoogleFonts.poppins(
                        color: AppColors.error,
                        fontSize: context.responsive.fontSizeCaption,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            "%${successRate.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: context.responsive.fontSizeH3,
              color: AppColors.getSuccessColor(successRate),
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
}
