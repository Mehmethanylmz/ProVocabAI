import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/theme/app_theme_extension.dart';

class SkillRadarCard extends StatelessWidget {
  final Map<String, double> volumeStats;
  final Map<String, double> accuracyStats;
  final String message;

  const SkillRadarCard({
    super.key,
    required this.volumeStats,
    required this.accuracyStats,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final bgColors = [scheme.surfaceContainerHigh, scheme.surfaceContainer];
    final onSurface = scheme.onSurface;

    return Container(
      height: context.responsive.value(mobile: 280, tablet: 350, desktop: 400),
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        boxShadow: [
          BoxShadow(
            color: ext.glowPrimary,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.radar_outlined,
              size: context.responsive
                  .value(mobile: 150, tablet: 200, desktop: 250),
              color: onSurface.withValues(alpha: 0.03),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.responsive.spacingM),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: context.ext.chartVolume.withValues(alpha: 0.15),
                          borderColor: context.ext.chartVolume,
                          entryRadius: 2,
                          dataEntries: [
                            RadarEntry(value: volumeStats['speaking'] ?? 0),
                            RadarEntry(value: volumeStats['listening'] ?? 0),
                            RadarEntry(value: volumeStats['quiz'] ?? 0),
                            RadarEntry(value: volumeStats['vocabulary'] ?? 0),
                          ],
                          borderWidth: 2,
                        ),
                        RadarDataSet(
                          fillColor:
                              context.ext.chartAccuracy.withValues(alpha: 0.25),
                          borderColor: context.ext.chartAccuracy,
                          entryRadius: 3,
                          dataEntries: [
                            RadarEntry(value: accuracyStats['speaking'] ?? 0),
                            RadarEntry(value: accuracyStats['listening'] ?? 0),
                            RadarEntry(value: accuracyStats['quiz'] ?? 0),
                            RadarEntry(value: accuracyStats['vocabulary'] ?? 0),
                          ],
                          borderWidth: 2,
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData:
                          const BorderSide(color: Colors.transparent),
                      titlePositionPercentageOffset: 0.2,
                      titleTextStyle: GoogleFonts.inter(
                        color: onSurface.withValues(alpha: 0.9),
                        fontSize: context.responsive.fontSizeCaption,
                        fontWeight: FontWeight.bold,
                      ),
                      getTitle: (index, angle) {
                        const titles = [
                          'radar_speaking',
                          'radar_listening',
                          'radar_test',
                          'radar_vocabulary'
                        ];
                        if (index < titles.length) {
                          return RadarChartTitle(
                              text: titles[index].tr(), angle: angle);
                        }
                        return const RadarChartTitle(text: '');
                      },
                      tickCount: 1,
                      ticksTextStyle:
                          const TextStyle(color: Colors.transparent),
                      tickBorderData:
                          BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
                      gridBorderData: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.2), width: 1.5),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 1000),
                    swapAnimationCurve: Curves.elasticOut,
                  ),
                ),
                SizedBox(width: context.responsive.spacingM),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("radar_accuracy".tr(),
                          context.ext.chartAccuracy, context, onSurface),
                      SizedBox(height: context.responsive.spacingXS),
                      _buildLegendItem("radar_volume".tr(),
                          context.ext.chartVolume, context, onSurface),
                      SizedBox(height: context.responsive.spacingM),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.spacingS,
                          vertical: context.responsive.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusS),
                          border:
                              Border.all(color: scheme.outline.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "radar_analysis".tr(),
                          style: GoogleFonts.inter(
                            color: onSurface,
                            fontSize: context.responsive.fontSizeCaption,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingS),
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          color: onSurface.withValues(alpha: 0.9),
                          fontSize: context.responsive.fontSizeCaption,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildLegendItem(String text, Color color, BuildContext context, Color onSurface) {
    return Row(
      children: [
        Container(
          width: context.responsive.value(mobile: 8, tablet: 10, desktop: 12),
          height: context.responsive.value(mobile: 8, tablet: 10, desktop: 12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        SizedBox(width: context.responsive.spacingXS),
        Text(
          text,
          style: GoogleFonts.inter(
            color: onSurface.withValues(alpha: 0.8),
            fontSize: context.responsive.fontSizeCaption,
          ),
        ),
      ],
    );
  }
}
