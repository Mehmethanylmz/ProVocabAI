import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkillRadarCard extends StatelessWidget {
  final Map<String, double> skills;
  final String messageKey;

  const SkillRadarCard({
    super.key,
    required this.skills,
    required this.messageKey,
  });

  @override
  Widget build(BuildContext context) {
    final gridColor = Colors.white.withOpacity(0.2);
    final titleColor = Colors.white.withOpacity(0.9);
    final radarColor = const Color(0xFF50E3C2);

    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A2D3E),
            Color(0xFF1F2029),
          ],
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
            child: Icon(Icons.insights,
                size: 150, color: Colors.white.withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: radarColor.withOpacity(0.3),
                          borderColor: radarColor,
                          entryRadius: 3,
                          dataEntries: [
                            RadarEntry(value: skills['reading'] ?? 0),
                            RadarEntry(value: skills['listening'] ?? 0),
                            RadarEntry(value: skills['speaking'] ?? 0),
                            RadarEntry(value: skills['grammar'] ?? 0),
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      getTitle: (index, angle) {
                        switch (index) {
                          case 0:
                            return RadarChartTitle(
                                text: 'READING', angle: angle);
                          case 1:
                            return RadarChartTitle(
                                text: 'LISTENING', angle: angle);
                          case 2:
                            return RadarChartTitle(
                                text: 'SPEAKING', angle: angle);
                          case 3:
                            return RadarChartTitle(
                                text: 'GRAMMAR', angle: angle);
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
                    swapAnimationDuration: const Duration(milliseconds: 400),
                    swapAnimationCurve: Curves.easeInOut,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.5)),
                        ),
                        child: Text(
                          "AI COACH",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        messageKey.tr(),
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (skills['speaking'] ?? 0) / 100,
                        backgroundColor: Colors.white10,
                        color: Colors.redAccent,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
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
}
