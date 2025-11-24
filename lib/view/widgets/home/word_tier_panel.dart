import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/constants/app_colors.dart';

class WordTierPanel extends StatelessWidget {
  final Map<String, int> tierDistribution;

  const WordTierPanel({
    super.key,
    required this.tierDistribution,
  });

  int get totalWords =>
      tierDistribution.values.fold(0, (sum, count) => sum + count);

  double getPercentage(int count) {
    if (totalWords == 0) return 0;
    return (count / totalWords) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final tierInfo = {
      'Expert': {
        'color': AppColors.success,
        'gradient': AppColors.gradientGreen,
        'icon': Icons.workspace_premium,
        'label': 'expert'.tr()
      },
      'Apprentice': {
        'color': AppColors.primary,
        'gradient': AppColors.gradientPurple,
        'icon': Icons.trending_up,
        'label': 'apprentice'.tr()
      },
      'Novice': {
        'color': AppColors.warning,
        'gradient': AppColors.gradientOrange,
        'icon': Icons.school,
        'label': 'novice'.tr()
      },
      'Struggling': {
        'color': AppColors.error,
        'gradient': AppColors.gradientPink,
        'icon': Icons.priority_high,
        'label': 'struggling'.tr()
      },
      'Unlearned': {
        'color': AppColors.textDisabled,
        'gradient': const [Color(0xFF525252), Color(0xFF3d3d3d)],
        'icon': Icons.circle_outlined,
        'label': 'unlearned'.tr()
      },
    };

    final validEntries = tierDistribution.entries
        .where((entry) => tierInfo.containsKey(entry.key))
        .toList();

    return Card(
      elevation: context.responsive.elevationMedium,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: Padding(
          padding: context.responsive.paddingCard,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.responsive.spacingXS),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            context.responsive.borderRadiusM,
                          ),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: AppColors.primary,
                          size: context.responsive.iconSizeM,
                        ),
                      ),
                      SizedBox(width: context.responsive.spacingM),
                      Text(
                        'level_distribution'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeH3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.spacingM,
                      vertical: context.responsive.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        context.responsive.borderRadiusXL,
                      ),
                      border: Border.all(
                        color: AppColors.primaryLight.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$totalWords ${'words'.tr()}',
                      style: GoogleFonts.poppins(
                        fontSize: context.responsive.fontSizeCaption,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsive.spacingL),
              if (validEntries.isEmpty)
                Padding(
                  padding: context.responsive.paddingSection,
                  child: Text(
                    "no_data_yet".tr(),
                    style: GoogleFonts.poppins(color: AppColors.textDisabled),
                  ),
                )
              else
                ...validEntries.map((entry) {
                  final info = tierInfo[entry.key]!;
                  final percentage = getPercentage(entry.value);
                  final gradientColors = info['gradient'] as List<Color>;
                  final label = info['label'] as String;
                  final icon = info['icon'] as IconData;
                  final baseColor = info['color'] as Color;

                  return Padding(
                    padding:
                        EdgeInsets.only(bottom: context.responsive.spacingL),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: context.responsive.value(
                                mobile: 40,
                                tablet: 48,
                                desktop: 56,
                              ),
                              height: context.responsive.value(
                                mobile: 40,
                                tablet: 48,
                                desktop: 56,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                    LinearGradient(colors: gradientColors),
                                borderRadius: BorderRadius.circular(
                                  context.responsive.borderRadiusM,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientColors[0].withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: context.responsive.iconSizeS,
                              ),
                            ),
                            SizedBox(width: context.responsive.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.poppins(
                                      fontSize: context.responsive.fontSizeBody,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: GoogleFonts.poppins(
                                      fontSize:
                                          context.responsive.fontSizeCaption,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: context.responsive.fontSizeH3,
                                fontWeight: FontWeight.bold,
                                color: baseColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.responsive.spacingM),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            context.responsive.borderRadiusS,
                          ),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: AppColors.borderLight,
                            color: baseColor,
                            minHeight: context.responsive.value(
                              mobile: 6,
                              tablet: 8,
                              desktop: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
                }),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }
}
