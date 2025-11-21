import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Extension Import
import '../../../../core/extensions/responsive_extension.dart';

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
    final gridColor = Colors.white.withOpacity(0.1);
    final titleColor = Colors.white.withOpacity(0.9);
    final accuracyColor = const Color(0xFF50E3C2);
    final volumeColor = const Color(0xFFFFB74D);

    return Container(
      // Yükseklik: Mobilde 280, Tablette 350 (Daha rahat görünsün)
      height: context.value(mobile: 280, tablet: 350),
      margin: EdgeInsets.symmetric(vertical: context.normalValue),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2D3E), Color(0xFF1F2029)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
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
              // İkon boyutu dinamik
              size: context.value(mobile: 150, tablet: 200),
              color: Colors.white.withOpacity(0.03),
            ),
          ),
          Padding(
            padding: context.paddingMedium, // 16 veya 24
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: volumeColor.withOpacity(0.15),
                          borderColor: volumeColor,
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
                          fillColor: accuracyColor.withOpacity(0.25),
                          borderColor: accuracyColor,
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
                        fontSize: context.fontSmall, // 10-12 arası
                        fontWeight: FontWeight.bold,
                      ),
                      // ... (getTitle fonksiyonu aynı kalabilir) ...
                      getTitle: (index, angle) {
                        switch (index) {
                          case 0:
                            return RadarChartTitle(
                                text: 'KONUŞMA', angle: angle);
                          case 1:
                            return RadarChartTitle(
                                text: 'DİNLEME', angle: angle);
                          case 2:
                            return RadarChartTitle(text: 'TEST', angle: angle);
                          case 3:
                            return RadarChartTitle(
                                text: 'KELİME', angle: angle);
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
                SizedBox(width: context.mediumValue),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("Başarı", accuracyColor, context),
                      SizedBox(height: context.lowValue),
                      _buildLegendItem("Hacim", volumeColor, context),
                      SizedBox(height: context.mediumValue),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.normalValue,
                            vertical: context.lowValue),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          "ANALİZ",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: context.fontSmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: context.normalValue),
                      Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: context.fontSmall, // Dinamik font
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
          width: context.value(mobile: 8, tablet: 10),
          height: context.value(mobile: 8, tablet: 10),
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)
              ]),
        ),
        SizedBox(width: context.lowValue),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: context.fontSmall,
          ),
        ),
      ],
    );
  }
}
