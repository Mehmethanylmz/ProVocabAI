import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/extensions/responsive_extension.dart';
import '../../../core/constants/app_colors.dart';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        ),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            SizedBox(width: context.responsive.spacingS),
            Expanded(
              child: Text(
                'stats_mastered_title'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'stats_mastered_desc'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'btn_ok'.tr(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: context.responsive.fontSizeBody,
              ),
            ),
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
        title: 'stats_today'.tr(),
        value: '${widget.stats?.todayQuestions ?? 0}',
        subtitle: '%${widget.stats?.todaySuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'success_rate'.tr(),
        gradient: AppColors.gradientBlue,
        icon: Icons.today,
      ),
      _StatCardData(
        title: 'stats_week'.tr(),
        value: '${widget.stats?.weekQuestions ?? 0}',
        subtitle: '%${widget.stats?.weekSuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'success_rate'.tr(),
        gradient: AppColors.gradientGreen,
        icon: Icons.calendar_view_week,
      ),
      _StatCardData(
        title: 'stats_month'.tr(),
        value: '${widget.stats?.monthQuestions ?? 0}',
        subtitle: '%${widget.stats?.monthSuccessRate.toStringAsFixed(0) ?? 0}',
        subtitleLabel: 'success_rate'.tr(),
        gradient: AppColors.gradientPink,
        icon: Icons.calendar_month,
      ),
      _StatCardData(
        title: 'stats_mastered'.tr(),
        value: '${widget.stats?.masteredWords ?? 0}',
        subtitle: null,
        subtitleLabel: 'words'.tr(),
        gradient: AppColors.gradientPurple,
        icon: Icons.workspace_premium,
        hasInfo: true,
      ),
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive.value(mobile: 2, tablet: 4),
        childAspectRatio: context.responsive.value(mobile: 1.4, tablet: 1.6),
        mainAxisSpacing: context.responsive.spacingM,
        crossAxisSpacing: context.responsive.spacingM,
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
        crossAxisCount: context.responsive.value(mobile: 2, tablet: 4),
        childAspectRatio: context.responsive.value(mobile: 1.4, tablet: 1.6),
        mainAxisSpacing: context.responsive.spacingM,
        crossAxisSpacing: context.responsive.spacingM,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1500.ms, color: AppColors.surface.withOpacity(0.3));
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
          borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, data.gradient[0].withOpacity(0.05)],
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradient[0].withOpacity(0.15),
              blurRadius: context.responsive.spacingM + 3,
              offset: Offset(0, context.responsive.spacingS),
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
              padding: EdgeInsets.all(context.responsive.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İkon ve Başlık
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.responsive.spacingXS),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: data.gradient),
                          borderRadius: BorderRadius.circular(
                              context.responsive.borderRadiusM),
                          boxShadow: [
                            BoxShadow(
                              color: data.gradient[0].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(data.icon,
                            color: AppColors.surface,
                            size: context.responsive.iconSizeS),
                      ),
                      SizedBox(width: context.responsive.spacingS),
                      Expanded(
                        child: Text(
                          data.title,
                          style: GoogleFonts.poppins(
                            fontSize: context.responsive.fontSizeBody,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data.hasInfo)
                        Icon(
                          Icons.info_outline,
                          size: context.responsive.iconSizeS,
                          color: AppColors.textDisabled,
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Değer
                  Text(
                    data.value,
                    style: GoogleFonts.poppins(
                      fontSize: context.responsive.fontSizeH1,
                      fontWeight: FontWeight.bold,
                      color: data.gradient[0],
                    ),
                  ),

                  // Alt metin (Başarı oranı vb.)
                  if (data.subtitle != null)
                    Row(
                      children: [
                        Text(
                          data.subtitleLabel,
                          style: GoogleFonts.poppins(
                            fontSize: context.responsive.fontSizeCaption,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: context.responsive.spacingXS),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive.spacingXS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: data.gradient[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                context.responsive.borderRadiusS),
                          ),
                          child: Text(
                            data.subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive.fontSizeCaption,
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
