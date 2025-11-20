import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/dashboard_stats.dart';

class DashboardStatsGrid extends StatelessWidget {
  final DashboardStats? stats;
  final bool isSmallScreen;

  const DashboardStatsGrid({
    super.key,
    required this.stats,
    required this.isSmallScreen,
  });

  void _showMasteryInfoDialog(BuildContext context, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            SizedBox(width: 10),
            Text('Ustalaşılan Kelime Nedir?'),
          ],
        ),
        content: Text(
          "Bu sayaç, Seviye 4 ('Çırak') ve üzerine ulaşan kelimelerin toplamını gösterir.\n\nBir kelime bu seviyeye ulaştığında, onu iyi bildiğiniz varsayılır ve 'ustalaşmış' olarak sayılır. Bu, ilerlemenizi daha hızlı görebilmeniz içindir!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Anladım'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: isSmallScreen ? 1 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isSmallScreen ? 2.8 : 1.8,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          context,
          'Bugün',
          '${stats?.todayQuestions ?? 0}',
          '${stats?.todaySuccessRate.toStringAsFixed(0) ?? 0}%',
          Colors.blue[700]!,
          isSmallScreen,
        ),
        _buildStatCard(
          context,
          'Bu Hafta',
          '${stats?.weekQuestions ?? 0}',
          '${stats?.weekSuccessRate.toStringAsFixed(0) ?? 0}%',
          Colors.green[600]!,
          isSmallScreen,
        ),
        _buildStatCard(
          context,
          'Bu Ay',
          '${stats?.monthQuestions ?? 0}',
          '${stats?.monthSuccessRate.toStringAsFixed(0) ?? 0}%',
          Colors.orange[600]!,
          isSmallScreen,
        ),
        _buildStatCard(
          context,
          'Ustalaşılan Kelimeler',
          '${stats?.masteredWords ?? 0}',
          '',
          Colors.purple[600]!,
          isSmallScreen,
          isSingleValue: true,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String questions,
    String rate,
    Color color,
    bool isSmallScreen, {
    bool isSingleValue = false,
  }) {
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double valueFontSize = isSmallScreen ? 28.0 : 32.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSingleValue)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: InkWell(
                            onTap: () => _showMasteryInfoDialog(context, color),
                            child: Icon(
                              Icons.info_outline,
                              color: color,
                              size: titleFontSize,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    questions,
                    style: GoogleFonts.poppins(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isSingleValue)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Başarı',
                      style: GoogleFonts.poppins(
                        fontSize: titleFontSize,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rate,
                      style: GoogleFonts.poppins(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.3));
  }
}
