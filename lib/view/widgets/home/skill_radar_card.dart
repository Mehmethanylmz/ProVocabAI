import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/constants/app_colors.dart';

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
    final gridColor = AppColors.surface.withOpacity(0.1);
    final titleColor = AppColors.surface.withOpacity(0.9);

    return Container(
      height: context.responsive.value(mobile: 280, tablet: 350, desktop: 400),
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingS),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2D3E), Color(0xFF1F2029)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A2D3E).withOpacity(0.5),
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
              color: AppColors.surface.withOpacity(0.03),
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
                          fillColor: AppColors.chartVolume.withOpacity(0.15),
                          borderColor: AppColors.chartVolume,
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
                          fillColor: AppColors.chartAccuracy.withOpacity(0.25),
                          borderColor: AppColors.chartAccuracy,
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
                      titleTextStyle: GoogleFonts.poppins(
                        color: titleColor,
                        fontSize: context.responsive.fontSizeCaption,
                        fontWeight: FontWeight.bold,
                      ),
                      getTitle: (index, angle) {
                        switch (index) {
                          case 0:
                            return RadarChartTitle(
                              text: 'radar_speaking'.tr(),
                              angle: angle,
                            );
                          case 1:
                            return RadarChartTitle(
                              text: 'radar_listening'.tr(),
                              angle: angle,
                            );
                          case 2:
                            return RadarChartTitle(
                              text: 'radar_test'.tr(),
                              angle: angle,
                            );
                          case 3:
                            return RadarChartTitle(
                              text: 'radar_vocabulary'.tr(),
                              angle: angle,
                            );
                          default:
                            return const RadarChartTitle(text: '');
                        }
                      },
                      tickCount: 1,
                      ticksTextStyle:
                          const TextStyle(color: Colors.transparent),
                      tickBorderData: BorderSide(color: gridColor),
                      gridBorderData: BorderSide(color: gridColor, width: 1.5),
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
                          AppColors.chartAccuracy, context),
                      SizedBox(height: context.responsive.spacingXS),
                      _buildLegendItem(
                          "radar_volume".tr(), AppColors.chartVolume, context),
                      SizedBox(height: context.responsive.spacingM),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.spacingS,
                          vertical: context.responsive.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusS),
                          border: Border.all(
                              color: AppColors.surface.withOpacity(0.2)),
                        ),
                        child: Text(
                          "radar_analysis".tr(),
                          style: GoogleFonts.poppins(
                            color: AppColors.surface,
                            fontSize: context.responsive.fontSizeCaption,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingS),
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: AppColors.surface.withOpacity(0.9),
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

  Widget _buildLegendItem(String text, Color color, BuildContext context) {
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
                color: color.withOpacity(0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        SizedBox(width: context.responsive.spacingXS),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: AppColors.surface.withOpacity(0.8),
            fontSize: context.responsive.fontSizeCaption,
          ),
        ),
      ],
    );
  }
}
