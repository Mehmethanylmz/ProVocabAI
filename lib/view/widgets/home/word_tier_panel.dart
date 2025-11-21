import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
        'color': Colors.green[600]!,
        'gradient': const [Color(0xFF11998e), Color(0xFF38ef7d)],
        'icon': Icons.workspace_premium,
        'label': 'Uzman'
      },
      'Apprentice': {
        'color': Colors.blue[700]!,
        'gradient': const [Color(0xFF667eea), Color(0xFF764ba2)],
        'icon': Icons.trending_up,
        'label': 'Çırak'
      },
      'Novice': {
        'color': Colors.orange[600]!,
        'gradient': const [Color(0xFFF09819), Color(0xFFEDDE5D)],
        'icon': Icons.school,
        'label': 'Acemi'
      },
      'Struggling': {
        'color': Colors.red[600]!,
        'gradient': const [Color(0xFFEB3349), Color(0xFFF45C43)],
        'icon': Icons.priority_high,
        'label': 'Zorlanılan'
      },
      'Unlearned': {
        'color': Colors.grey[700]!,
        'gradient': const [Color(0xFF525252), Color(0xFF3d3d3d)],
        'icon': Icons.circle_outlined,
        'label': 'Başlanmadı'
      },
    };

    final validEntries = tierDistribution.entries
        .where((entry) => tierInfo.containsKey(entry.key))
        .toList();

    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: context.paddingMedium,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: context.paddingLow,
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.analytics,
                            color: Colors.purple[700], size: context.iconSmall),
                      ),
                      SizedBox(width: context.normalValue),
                      Text(
                        'Seviye Dağılımı',
                        style: GoogleFonts.poppins(
                          fontSize: context.fontMedium,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.normalValue,
                        vertical: context.lowValue),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[100]!, width: 1),
                    ),
                    child: Text(
                      '$totalWords Kelime',
                      style: GoogleFonts.poppins(
                        fontSize: context.fontSmall,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.mediumValue),
              if (validEntries.isEmpty)
                Padding(
                  padding: context.paddingMedium,
                  child: Text("Henüz veri yok.",
                      style: GoogleFonts.poppins(color: Colors.grey)),
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
                    padding: EdgeInsets.only(bottom: context.mediumValue),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                                width: context.value(mobile: 40, tablet: 48),
                                height: context.value(mobile: 40, tablet: 48),
                                decoration: BoxDecoration(
                                  gradient:
                                      LinearGradient(colors: gradientColors),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            gradientColors[0].withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Icon(icon,
                                    color: Colors.white,
                                    size: context.iconSmall)),
                            SizedBox(width: context.mediumValue),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.poppins(
                                      fontSize: context.fontNormal,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: context.fontSmall,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: context.fontLarge,
                                fontWeight: FontWeight.bold,
                                color: baseColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.normalValue),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[100],
                            color: baseColor,
                            minHeight: context.value(mobile: 6, tablet: 8),
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
