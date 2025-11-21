import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/extensions/responsive_extension.dart';
import '../../../data/models/dashboard_stats.dart';

class DashboardStatsGrid extends StatefulWidget {
  final DashboardStats? stats;

  const DashboardStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  State<DashboardStatsGrid> createState() => _DashboardStatsGridState();
}

class _DashboardStatsGridState extends State<DashboardStatsGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showMasteryInfoDialog(BuildContext context, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            SizedBox(width: context.normalValue),
            Expanded(
              child: Text(
                'Ustalaşılan Kelime',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Bu sayaç, 'Çırak' seviyesi ve üzerine ulaşan kelimelerin toplamını gösterir.\n\nBir kelime bu seviyeye ulaştığında, onu öğrenmiş varsayılır ve bu haneye yazılır.",
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Tamam',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Veri yoksa loading göster
    if (widget.stats == null) {
      return _buildLoadingState();
    }

    // Kart verilerini hazırlıyoruz
    final statsCards = [
      _StatCardData(
        title: 'Bugün',
        value: '${widget.stats?.todayQuestions ?? 0}',
        subtitle: '%${widget.stats?.todaySuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'Başarı',
        gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)], // Mavi Tonlar
        icon: Icons.today,
      ),
      _StatCardData(
        title: 'Bu Hafta',
        value: '${widget.stats?.weekQuestions ?? 0}',
        subtitle: '%${widget.stats?.weekSuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'Başarı',
        gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)], // Yeşil Tonlar
        icon: Icons.calendar_view_week,
      ),
      _StatCardData(
        title: 'Bu Ay',
        value: '${widget.stats?.monthQuestions ?? 0}',
        subtitle: '%${widget.stats?.monthSuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'Başarı',
        gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)], // Pembe Tonlar
        icon: Icons.calendar_month,
      ),
      _StatCardData(
        title: 'Ustalaşılan',
        value: '${widget.stats?.masteredWords ?? 0}',
        subtitle: null, // Bunda yüzde yok
        subtitleLabel: 'Kelime',
        gradient: const [Color(0xFF667eea), Color(0xFF764ba2)], // Mor Tonlar
        icon: Icons.workspace_premium,
        hasInfo: true,
      ),
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.value(mobile: 2, tablet: 4),
        childAspectRatio: context.value(mobile: 1.4, tablet: 1.6),
        mainAxisSpacing: context.mediumValue,
        crossAxisSpacing: context.mediumValue,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statsCards.length,
      itemBuilder: (context, index) {
        return _buildAdvancedStatCard(context, statsCards[index], index);
      },
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.value(mobile: 2, tablet: 4),
        childAspectRatio: context.value(mobile: 1.4, tablet: 1.6),
        mainAxisSpacing: context.mediumValue,
        crossAxisSpacing: context.mediumValue,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: Colors.white54);
      },
    );
  }

  Widget _buildAdvancedStatCard(
      BuildContext context, _StatCardData data, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = isSelected ? null : index);
        if (data.hasInfo) _showMasteryInfoDialog(context, data.gradient[0]);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(isSelected ? 0.95 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, data.gradient[0].withOpacity(0.05)],
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradient[0].withOpacity(0.15),
              blurRadius: context.normalValue + 3,
              offset: Offset(0, context.normalValue / 2),
            ),
          ],
          border: Border.all(
            color: data.gradient[0].withOpacity(isSelected ? 0.6 : 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Arka plan dekoratif daire
            Positioned(
              right: -20,
              top: -20,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (_, __) => Transform.rotate(
                  angle: _animationController.value * 2 * math.pi,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          data.gradient[0].withOpacity(0.15),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: context.paddingMedium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İkon ve Başlık
                  Row(
                    children: [
                      Container(
                        padding: context.paddingLow,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: data.gradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: data.gradient[0].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(data.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.title,
                          style: GoogleFonts.poppins(
                            fontSize: context.fontNormal,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data.hasInfo)
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.grey[400]),
                    ],
                  ),

                  const Spacer(),

                  // Değer
                  Text(
                    data.value,
                    style: GoogleFonts.poppins(
                      fontSize: context.fontXLarge,
                      fontWeight: FontWeight.bold,
                      color: data.gradient[0], // Ana renk
                    ),
                  ),

                  // Alt metin (Başarı oranı vb.)
                  if (data.subtitle != null)
                    Row(
                      children: [
                        Text(
                          data.subtitleLabel,
                          style: GoogleFonts.poppins(
                              fontSize: context.fontSmall,
                              color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: data.gradient[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: context.fontSmall,
                              fontWeight: FontWeight.bold,
                              color: data.gradient[1],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 100).ms)
        .slideY(begin: 0.1, duration: 400.ms)
        .fadeIn();
  }
}

// Veri sınıfını widget içinde private olarak tutuyoruz
class _StatCardData {
  final String title;
  final String value;
  final String? subtitle;
  final String subtitleLabel;
  final List<Color> gradient;
  final IconData icon;
  final bool hasInfo;

  _StatCardData({
    required this.title,
    required this.value,
    this.subtitle,
    required this.subtitleLabel,
    required this.gradient,
    required this.icon,
    this.hasInfo = false,
  });
}
