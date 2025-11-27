import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';

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
        'color': context.ext.success,
        'gradient': [context.ext.success, context.ext.success.withOpacity(0.7)],
        'icon': Icons.workspace_premium,
        'label': 'expert'.tr()
      },
      'Apprentice': {
        'color': context.colors.primary,
        'gradient': context.ext.gradientPurple,
        'icon': Icons.trending_up,
        'label': 'apprentice'.tr()
      },
      'Novice': {
        'color': context.ext.warning,
        'gradient': [context.ext.warning, context.ext.warning.withOpacity(0.7)],
        'icon': Icons.school,
        'label': 'novice'.tr()
      },
      'Struggling': {
        'color': context.colors.error,
        'gradient': [
          context.colors.error,
          context.colors.error.withOpacity(0.7)
        ],
        'icon': Icons.priority_high,
        'label': 'struggling'.tr()
      },
      'Unlearned': {
        'color': context.colors.onSurfaceVariant,
        'gradient': [
          context.colors.surfaceContainerHighest,
          context.colors.surfaceContainerHighest
        ],
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
            colors: [
              context.colors.surface,
              context.colors.surfaceContainerLowest
            ],
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
                          color: context.colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusM),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: context.colors.primary,
                          size: context.responsive.iconSizeM,
                        ),
                      ),
                      SizedBox(width: context.responsive.spacingM),
                      Text(
                        'level_distribution'.tr(),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
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
                      color: context.colors.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusXL),
                      border: Border.all(
                        color: context.colors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$totalWords ${'words'.tr()}',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
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
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: context.colors.onSurfaceVariant),
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
                              width: context.responsive
                                  .value(mobile: 40, tablet: 48, desktop: 56),
                              height: context.responsive
                                  .value(mobile: 40, tablet: 48, desktop: 56),
                              decoration: BoxDecoration(
                                gradient:
                                    LinearGradient(colors: gradientColors),
                                borderRadius: BorderRadius.circular(
                                    context.responsive.borderRadiusM),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientColors[0].withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(icon,
                                  color: Colors.white,
                                  size: context.responsive.iconSizeS),
                            ),
                            SizedBox(width: context.responsive.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                            color: context
                                                .colors.onSurfaceVariant),
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
                              context.responsive.borderRadiusS),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: context.colors.outlineVariant,
                            color: baseColor,
                            minHeight: context.responsive
                                .value(mobile: 6, tablet: 8, desktop: 10),
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
